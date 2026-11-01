import 'package:flutter/material.dart';
import '../../domain/entities/stock_enums.dart';
import '../../domain/entities/stock_movement.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// One ledger history line.
///
/// e.g. 「09-07  (photo)  삼다수 2L  입고 · 매입 · hong  +3」
///
/// The product photo sits left of the name (`ProductThumbnail` 40, no
/// zoom — FEATURE_2611_02 D13 · D14 · D21) in both places that use this
/// tile: the 「재고 조회」 history sheet and the 「입고·조정」 recent history.
///
/// ⚠️ The quantity sign is shown as the server stored it — the screen never
/// flips it (PLAN 2609_28 D6).
class MovementTile extends StatelessWidget {
  final StockMovement movement;

  const MovementTile({required this.movement, super.key});

  @override
  Widget build(BuildContext context) {
    final increase = movement.quantity >= 0;
    final signed =
        '${increase ? '+' : '−'}${movement.quantity.abs()}';
    final reasonText = movement.reason == StockReason.etc &&
            (movement.reasonNote?.trim().isNotEmpty ?? false)
        ? '기타 · ${movement.reasonNote!.trim()}'
        : (movement.reason?.label ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              _shortDate(movement.movedOn),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ProductThumbnail(productId: movement.productId, size: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.productName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    movement.movementType?.label ?? '',
                    if (reasonText.isNotEmpty) reasonText,
                    if (movement.sellerName.isNotEmpty) movement.sellerName,
                    if (movement.createdBy != null &&
                        movement.createdBy!.isNotEmpty)
                      movement.createdBy!,
                  ].where((e) => e.isNotEmpty).join(' · '),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            signed,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: increase
                  ? AppColors.infoForeground
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  /// YYYY-MM-DD → MM-DD. 형식이 다르면 원문 그대로 둔다.
  String _shortDate(String movedOn) =>
      movedOn.length >= 10 ? movedOn.substring(5, 10) : movedOn;
}
