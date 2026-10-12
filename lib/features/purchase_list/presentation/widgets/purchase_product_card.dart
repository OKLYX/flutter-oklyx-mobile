import 'package:flutter/material.dart';

import '../../domain/entities/purchase_list_item.dart';
import 'product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// 구매목록 상품(물품) 카드.
///
/// 썸네일(누르면 확대) + 상품명 + 브랜드 / 필요 수량 / 매입 완료 수량(한 줄에 하나)
/// + 오른쪽 아래 강조된 매입 필요 수량.
/// 🔴 세 숫자는 **전체 기준**이다 — 판매자로 쪼개지 않는다(PLAN 2609_29 D6).
///
/// **두 자리에서 쓴다**(2026-10-09, 펼침 토글 → 상세 페이지):
/// - 목록: [onTap] 을 주면 오른쪽 위 `›` 와 함께 누르면 상세(`PurchaseProductDetailPage`)로 간다.
/// - 상세 머리: [onTap] 없이 같은 카드를 요약으로 쓴다(`›` 없음).
/// 입고 기록 · 최근 구매이력 · 채널 칩 + 주문 줄은 **상세 페이지에만** 있다.
/// ❌ 완료탭용 카드를 복제하지 말 것 — 두 탭은 같은 카드·같은 상세를 쓴다(D21).
class PurchaseProductCard extends StatelessWidget {
  final PurchaseListItem item;

  /// Opens the product detail. Null on the detail page itself.
  final VoidCallback? onTap;

  const PurchaseProductCard({
    required this.item,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AppCard.flush(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            // IntrinsicHeight + stretch lets the right column span the row so
            // the emphasised remaining quantity sits at the bottom-right.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Align keeps the fixed-size thumbnail from being
                  // stretched to the row height.
                  Align(
                    alignment: Alignment.topCenter,
                    child: ProductThumbnail(
                      productId: item.productId,
                      size: 104,
                      zoomable: true,
                    ),
                  ),
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
                        const SizedBox(height: 6),
                        // One metric per line: full-word labels read
                        // unambiguously on a narrow screen.
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelLine(
                              '브랜드',
                              (item.brand?.trim().isNotEmpty ?? false)
                                  ? item.brand!.trim()
                                  : '-',
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            _metric(
                              '필요 수량',
                              item.neededQty,
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            _metric(
                              '매입 완료 수량',
                              item.purchasedQty,
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (onTap != null)
                        const Icon(Icons.chevron_right)
                      else
                        const SizedBox.shrink(),
                      _remaining(context, item.remainingQty),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// The number the user acts on — emphasised at the card's bottom-right.
  /// Amber while something is left to buy, green once covered.
  Widget _remaining(BuildContext context, int value) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '매입 필요 수량',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: value > 0
                  ? AppColors.warningForeground
                  : AppColors.successForeground,
            ),
          ),
        ],
      );

  Widget _metric(String label, int value, Color? color) =>
      _labelLine(label, '$value', color);

  Widget _labelLine(String label, String value, Color? color) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '$label : $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
