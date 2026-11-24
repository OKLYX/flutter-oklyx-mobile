import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../purchase_list/presentation/widgets/product_thumbnail.dart';
import '../../../seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/name_text.dart';
import '../../domain/entities/stock_enums.dart';
import '../bloc/outbound_work_cubit.dart';

/// One collected line of 「출고 작업」 (FEATURE_2611_34 D11 ~ D13 · R25).
class OutboundWorkLineTile extends StatefulWidget {
  final OutboundWorkLine line;
  final List<Seller> sellers;
  final Seller? soleSeller;

  /// Reason dropdown shows on the 「폐기」 tab only (D11).
  final bool showReason;
  final ValueChanged<int> onSellerChanged;
  final ValueChanged<StockReason> onReasonChanged;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<String> onQuantityChanged;
  final VoidCallback onRemove;

  const OutboundWorkLineTile({
    required this.line,
    required this.sellers,
    required this.soleSeller,
    required this.showReason,
    required this.onSellerChanged,
    required this.onReasonChanged,
    required this.onNoteChanged,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  @override
  State<OutboundWorkLineTile> createState() => _OutboundWorkLineTileState();
}

class _OutboundWorkLineTileState extends State<OutboundWorkLineTile> {
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity.text = widget.line.quantityText;
    _note.text = widget.line.reasonNote;
  }

  @override
  void didUpdateWidget(covariant OutboundWorkLineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A scan adds 1 to this line — show the new count.
    if (widget.line.quantityText != _quantity.text) {
      _quantity.text = widget.line.quantityText;
    }
    // A reason other than 「기타」 clears the note (R25).
    if (widget.line.reasonNote != _note.text) {
      _note.text = widget.line.reasonNote;
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final soleSeller = widget.soleSeller;
    final head = Row(
      children: [
        ProductThumbnail(productId: widget.line.productId, size: 40),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: NameText(
                  name: widget.line.productName,
                  kind: NameKind.product,
                  expandable: true,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (line.custom)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    '따로 정함',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warningForeground,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final seller = soleSeller != null
        ? Text(soleSeller.sellerName, overflow: TextOverflow.ellipsis)
        : DropdownButtonFormField<int>(
            // Re-built when the line follows the screen seller.
            key: ValueKey('seller-${line.sellerId}'),
            initialValue: line.sellerId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '판매자'),
            items: [
              for (final s in widget.sellers)
                DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(s.sellerName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.onSellerChanged(value);
              }
            },
          );
    final reason = DropdownButtonFormField<StockReason>(
      // Re-built when the line follows the screen reason.
      key: ValueKey(line.reason),
      initialValue: line.reason,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '사유'),
      items: [
        for (final r in StockReason.outboundWorkDisposalReasons)
          DropdownMenuItem(
            value: r,
            child: Text(r.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          widget.onReasonChanged(value);
        }
      },
    );
    return AppCard.row(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: seller),
              if (widget.showReason) ...[
                const SizedBox(width: 8),
                Expanded(child: reason),
              ],
            ],
          ),
          if (line.reason == StockReason.etc) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: '기타 설명'),
              onChanged: widget.onNoteChanged,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: '수량'),
                  onChanged: widget.onQuantityChanged,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: widget.onRemove,
                child: const Text('빼기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
