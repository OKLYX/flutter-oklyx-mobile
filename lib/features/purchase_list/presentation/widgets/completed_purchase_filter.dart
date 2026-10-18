import 'package:flutter/material.dart';

/// Filter bar of the completed tab: processing-day range (start/end,
/// FEATURE_2610_09 D63 · D81 · D85).
///
/// 🔴 No seller dropdown here — the page's seller filter under the tabs covers
/// both tabs (FEATURE_2610_09 D5).
///
/// Applied by [조회] (no reload on each change). Inputs live in local widget
/// state, go to [onApply] at once, and re-sync when the parent's applied values
/// ([from]/[to]) change (after [조회] / [초기화]). An empty date means no bound on
/// that side (= all time).
class CompletedPurchaseFilter extends StatefulWidget {
  final String from;
  final String to;
  final bool isLoading;
  final void Function(String from, String to) onApply;
  final VoidCallback onReset;

  const CompletedPurchaseFilter({
    required this.from,
    required this.to,
    required this.isLoading,
    required this.onApply,
    required this.onReset,
    super.key,
  });

  @override
  State<CompletedPurchaseFilter> createState() =>
      _CompletedPurchaseFilterState();
}

class _CompletedPurchaseFilterState extends State<CompletedPurchaseFilter> {
  String _from = '';
  String _to = '';

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  @override
  void didUpdateWidget(CompletedPurchaseFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 적용값이 바뀌면(조회/초기화 후) 로컬 입력값을 재동기화한다.
    if (oldWidget.from != widget.from || oldWidget.to != widget.to) {
      _from = widget.from;
      _to = widget.to;
    }
  }

  DateTime? _parse(String s) {
    final parts = s.split('-');
    if (parts.length != 3) {
      return null;
    }
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      return null;
    }
    return DateTime(y, m, d);
  }

  String _fmt(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _parse(_from) : _parse(_to);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = _fmt(picked);
        } else {
          _to = _fmt(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: '처리일 시작',
                value: _from,
                enabled: !widget.isLoading,
                onTap: () => _pickDate(isFrom: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateField(
                label: '처리일 종료',
                value: _to,
                enabled: !widget.isLoading,
                onTap: () => _pickDate(isFrom: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isLoading ? null : widget.onReset,
                child: const Text('초기화'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: widget.isLoading
                    ? null
                    : () => widget.onApply(_from, _to),
                child: Text(widget.isLoading ? '조회 중...' : '조회'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Processing-day field (tap → DatePicker). Empty shows 「전체」.
class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value.isEmpty ? '전체' : value,
          style: TextStyle(
            color: value.isEmpty
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
        ),
      ),
    );
  }
}
