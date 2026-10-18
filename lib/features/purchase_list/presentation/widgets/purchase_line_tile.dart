import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/purchase_line.dart';

/// One purchase list line (inside the product detail).
///
/// An order line is **display only** — no input (PLAN 2609_29 D7). Purchases go
/// through the intake card (`PurchaseIntakeCard`); purchase records do not know
/// orders (D3).
///
/// Narrow screen, so lines are rows, not a table:
/// ```
/// 「A상사/쿠팡    #20260909-1   필요 3」
/// 「A상사/수동    —             필요 2」
///   [ 2 ] [저장]  [판매자 바꾸기] [제거]
/// ```
/// The channel label comes from `channelLabel(line)` only — ❌ no label table
/// copy.
///
/// A manual line (`isManual`, manualQty > 0) adds a second row
/// (FEATURE_2610_09 D23 · D24 · D77): quantity (1 or more, [저장] once it
/// differs), [판매자 바꾸기] (when [onChangeSeller] is given) and [제거] (deletes
/// the line). No confirmation dialog — a removed line can be added again
/// (mobile D23 — dialogs are for market sends and irreversible deletes only).
class PurchaseLineTile extends StatelessWidget {
  final PurchaseLine line;

  /// Saves a new manual quantity.
  final ValueChanged<int> onSaveQty;

  /// Opens the seller picker; null hides [판매자 바꾸기] (one seller, D53).
  final VoidCallback? onChangeSeller;

  /// Deletes this manual line.
  final VoidCallback onRemove;

  /// Disables the manual controls while another action is running.
  final bool busy;

  const PurchaseLineTile({
    required this.line,
    required this.onSaveQty,
    required this.onRemove,
    this.onChangeSeller,
    this.busy = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isManual = line.isManual && line.manualQty > 0;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  channelLabel(line),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 5,
                child: Text(
                  // 수동 라인은 주문번호가 없다.
                  line.externalOrderId ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '필요 ${line.neededQty}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (isManual) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _ManualQtyField(
                  value: line.manualQty,
                  busy: busy,
                  onSave: onSaveQty,
                ),
                const Spacer(),
                if (onChangeSeller != null)
                  TextButton(
                    onPressed: busy ? null : onChangeSeller,
                    style: _compact,
                    child:
                        const Text('판매자 바꾸기', style: TextStyle(fontSize: 12)),
                  ),
                TextButton(
                  onPressed: busy ? null : onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('제거', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static final ButtonStyle _compact = TextButton.styleFrom(
    minimumSize: const Size(0, 28),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}

/// Manual quantity — 1 or more; [저장] is enabled once the value is a
/// different whole number ≥ 1 (FEATURE_2610_09 D23).
class _ManualQtyField extends StatefulWidget {
  final int value;
  final bool busy;
  final ValueChanged<int> onSave;

  const _ManualQtyField({
    required this.value,
    required this.busy,
    required this.onSave,
  });

  @override
  State<_ManualQtyField> createState() => _ManualQtyFieldState();
}

class _ManualQtyFieldState extends State<_ManualQtyField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  int? get _parsed => int.tryParse(_controller.text.trim());

  bool get _canSave {
    final qty = _parsed;
    return !widget.busy && qty != null && qty >= 1 && qty != widget.value;
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            child: TextField(
              controller: _controller,
              enabled: !widget.busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                suffixText: '개',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _canSave ? () => widget.onSave(_parsed!) : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('저장', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
}
