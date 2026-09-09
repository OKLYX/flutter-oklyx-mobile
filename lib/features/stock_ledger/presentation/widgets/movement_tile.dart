import 'package:flutter/material.dart';
import '../../domain/entities/stock_enums.dart';
import '../../domain/entities/stock_movement.dart';

/// 원장 이력 1줄.
///
/// 예: `09-07  삼다수 2L  입고  +3  매입  hong`
///
/// ⚠️ 수량 부호는 서버가 저장한 그대로 보여준다 — 화면에서 뒤집지 않는다(PLAN 2609_28 D6).
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
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
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
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
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
              color: increase ? Colors.blue[700] : Colors.red[700],
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
