import 'package:flutter/material.dart';

import '../../domain/entities/purchase_list_item.dart';
import 'product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Purchase list product card.
///
/// Thumbnail (tap to zoom) + product name + 「브랜드」 / 「필요 수량」 /
/// 「매입 완료 수량」 (one per line) + the emphasised 「매입 필요 수량」 at the
/// bottom-right.
/// 🔴 The numbers are the response's as they are: a chosen seller's share, or in
/// 「전체」 the sum of the shares' shortfalls (FEATURE_2610_09 D2 · D22 · D58).
///
/// **Used in two places** (2026-10-09, expand toggle → detail page):
/// - List: with [onTap] it shows `›` and opens the detail
///   (`PurchaseProductDetailPage`). In the seller view the list passes the
///   share buttons as [footer] (D83).
/// - Detail header: the same card without [onTap] as a summary (no `›`).
/// Intake · recent purchases · channel chips + lines live **on the detail only**.
/// ❌ Do not copy the card for the completed tab — both tabs use the same card
/// and the same detail (D21).
class PurchaseProductCard extends StatelessWidget {
  final PurchaseListItem item;

  /// Opens the product detail. Null on the detail page itself.
  final VoidCallback? onTap;

  /// Drawn under the card's row — the share tag and buttons in the seller view.
  final Widget? footer;

  const PurchaseProductCard({
    required this.item,
    this.onTap,
    this.footer,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AppCard.flush(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(context),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      );

  Widget _row(BuildContext context) =>
      // IntrinsicHeight + stretch lets the right column span the row so
      // the emphasised remaining quantity sits at the bottom-right.
      IntrinsicHeight(
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
