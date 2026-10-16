import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import '../../domain/entities/order_item.dart';

/// 「11번가 예약판매」 badge of an 11st reserved-sale paid order
/// (FEATURE_2610_17 / D67).
///
/// **Purpose**: the order card (order history · shipment, shared [OrderCard])
/// draws it beside the order number, in the same slot and shape as
/// `InternalStageBadge`.
/// **File**: lib/features/order/presentation/widgets/elevenst_reserved_badge.dart
///
/// **Usage**:
/// ```dart
/// if (order.reservedSale) const ElevenstReservedBadge(),
/// ```
///
/// ⚠️ The text comes from [kElevenstReservedLabel] only.
/// ❌ Do not decide it from the raw status code — read
/// `OrderItem.reservedSale` (the server's flag).
class ElevenstReservedBadge extends StatelessWidget {
  const ElevenstReservedBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          kElevenstReservedLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
          ),
        ),
      );
}
