import 'package:flutter/material.dart';

import '../../domain/entities/purchase_list_item.dart';
import 'product_thumbnail.dart';
import 'purchase_line_tile.dart';

/// 구매목록 상품 카드 (펼침 가능).
///
/// 접힘: 썸네일 + 상품명 + 필요/구매/잔여 수량. 탭하면 [onToggle] 호출.
/// 펼침([expanded]): 상품의 각 라인을 [PurchaseLineTile]로 인라인 표시한다(웹과 동일).
class PurchaseProductCard extends StatelessWidget {
  final PurchaseListItem item;
  final bool expanded;
  final bool busy;

  /// 읽기전용(완료 탭)이면 라인 인라인 폼을 숨긴다.
  final bool readOnly;
  final VoidCallback onToggle;
  final void Function(int itemId, String purchasedOn, int quantity)
      onRecordPurchase;
  final void Function(int itemId, int manualQty) onAdjustManual;

  const PurchaseProductCard({
    required this.item,
    required this.expanded,
    required this.busy,
    required this.onToggle,
    required this.onRecordPurchase,
    required this.onAdjustManual,
    this.readOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ProductThumbnail(productId: item.productId),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            _metric('필요', item.neededQty, Colors.grey[800]),
                            _metric('구매', item.purchasedQty, Colors.grey[800]),
                            _metric('잔여', item.remainingQty,
                                item.remainingQty > 0 ? Colors.orange[800] : Colors.green[800]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.lines
                    .map(
                      (line) => PurchaseLineTile(
                        line: line,
                        busy: busy,
                        readOnly: readOnly,
                        onRecordPurchase: onRecordPurchase,
                        onAdjustManual: onAdjustManual,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color? color) => Text(
        '$label $value',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      );
}
