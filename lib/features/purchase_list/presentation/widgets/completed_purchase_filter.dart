import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'seller_filter_dropdown.dart';

/// 구매완료내역 탭의 필터 바: 판매자 + 구매일 기간(시작/종료).
///
/// 프론트 CompletedPurchaseFilter와 동일하게 '조회' 버튼으로 적용한다(즉시 재조회 X).
/// 입력값은 위젯 로컬 상태로 들고 있다가 [onApply]로 한 번에 전달하며, 부모의
/// 적용값([sellerId]/[from]/[to])이 바뀌면(조회/초기화 후) 로컬 상태를 재동기화한다.
/// 날짜를 비우면 해당 경계 없음(=전체 기간)으로 전달한다.
class CompletedPurchaseFilter extends StatefulWidget {
  final List<Seller> sellers;
  final int? sellerId;
  final String from;
  final String to;
  final bool isLoading;
  final void Function(int? sellerId, String from, String to) onApply;
  final VoidCallback onReset;

  const CompletedPurchaseFilter({
    required this.sellers,
    required this.sellerId,
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
  int? _sellerId;
  String _from = '';
  String _to = '';

  @override
  void initState() {
    super.initState();
    _sellerId = widget.sellerId;
    _from = widget.from;
    _to = widget.to;
  }

  @override
  void didUpdateWidget(CompletedPurchaseFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 적용값이 바뀌면(조회/초기화 후) 로컬 입력값을 재동기화한다.
    if (oldWidget.sellerId != widget.sellerId ||
        oldWidget.from != widget.from ||
        oldWidget.to != widget.to) {
      _sellerId = widget.sellerId;
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SellerFilterDropdown(
              sellers: widget.sellers,
              selectedSellerId: _sellerId,
              enabled: !widget.isLoading,
              onChanged: (value) => setState(() => _sellerId = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: '구매일 시작',
                    value: _from,
                    enabled: !widget.isLoading,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: '구매일 종료',
                    value: _to,
                    enabled: !widget.isLoading,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onReset,
                  child: const Text('초기화'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.onApply(_sellerId, _from, _to),
                  child: Text(widget.isLoading ? '조회 중...' : '조회'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 구매일 날짜 선택 필드(탭하면 DatePicker). 값이 비면 '전체'로 표시한다.
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
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value.isEmpty ? '전체' : value,
          style: TextStyle(
            color: value.isEmpty ? Colors.grey[600] : null,
          ),
        ),
      ),
    );
  }
}
