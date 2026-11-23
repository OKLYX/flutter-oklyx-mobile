import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/name_text.dart';
import '../../domain/entities/stock_enums.dart';
import '../bloc/stock_intake_cubit.dart';

/// One collected line of 「입고 작업」 (FEATURE_2611_33 D4 ⑥ · D8 · R6).
class IntakeLineTile extends StatefulWidget {
  final IntakeLine line;
  final List<Seller> sellers;
  final Seller? soleSeller;
  final ValueChanged<int?> onSellerChanged;
  final ValueChanged<StockReason> onReasonChanged;
  final ValueChanged<String> onQuantityChanged;
  final VoidCallback onRemove;

  const IntakeLineTile({
    required this.line,
    required this.sellers,
    required this.soleSeller,
    required this.onSellerChanged,
    required this.onReasonChanged,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  @override
  State<IntakeLineTile> createState() => _IntakeLineTileState();
}

class _IntakeLineTileState extends State<IntakeLineTile> {
  final TextEditingController _quantity = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity.text = widget.line.quantityText;
  }

  @override
  void didUpdateWidget(covariant IntakeLineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A scan adds 1 to this line — show the new count (R6).
    if (widget.line.quantityText != _quantity.text) {
      _quantity.text = widget.line.quantityText;
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final soleSeller = widget.soleSeller;
    final hasSeller = (soleSeller?.id ?? line.sellerId) != null;
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
        : DropdownButtonFormField<int?>(
            initialValue: widget.line.sellerId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '판매자'),
            items: [
              DropdownMenuItem<int?>(
                enabled: line.reason != StockReason.opening,
                child: const Text(
                  kUndecidedSellerLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final s in widget.sellers)
                DropdownMenuItem<int?>(
                  value: s.id,
                  child: Text(s.sellerName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: widget.onSellerChanged,
          );
    final reason = DropdownButtonFormField<StockReason>(
      initialValue: widget.line.reason,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '사유'),
      items: [
        DropdownMenuItem(
          value: StockReason.purchase,
          child: Text(
            StockReason.purchase.label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: StockReason.opening,
          enabled: hasSeller,
          child: Text(
            hasSeller ? StockReason.opening.label : kOpeningNeedsSellerLabel,
            overflow: TextOverflow.ellipsis,
          ),
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
              const SizedBox(width: 8),
              Expanded(child: reason),
            ],
          ),
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
