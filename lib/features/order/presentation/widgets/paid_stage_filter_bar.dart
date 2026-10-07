import 'package:flutter/material.dart';

import '../../domain/entities/order_item.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// 2nd-row chip value under PAID on the shipment page
/// (FEATURE_2610_07 / D10·D11).
enum PaidStage { all, beforeAck, internalPreparing, awaitingShipment }

/// Chip labels. The two stage labels come from [kInternalStageLabels] — only
/// the first two are new here (D12).
String paidStageLabel(PaidStage stage) => switch (stage) {
      PaidStage.all => '전체',
      PaidStage.beforeAck => '발주 전',
      PaidStage.internalPreparing =>
        kInternalStageLabels[InternalStage.internalPreparing]!,
      PaidStage.awaitingShipment =>
        kInternalStageLabels[InternalStage.awaitingShipment]!,
    };

/// Whether a PAID order falls under the chip. Callers pass PAID orders only.
/// The stage is the server's `internalStage` as is — never re-derived (D11).
bool matchesPaidStage(OrderItem order, PaidStage stage) => switch (stage) {
      PaidStage.all => true,
      PaidStage.beforeAck => order.internalStage == null,
      PaidStage.internalPreparing =>
        order.internalStage == InternalStage.internalPreparing,
      PaidStage.awaitingShipment =>
        order.internalStage == InternalStage.awaitingShipment,
    };

/// Shipment page 2nd-row chip bar, shown only while the PAID chip is on
/// (FEATURE_2610_07 / D10).
///
/// **Purpose**: splits PAID orders by the server's internal stage. Single
/// choice; [PaidStage.all] is the default.
/// **File**:
/// lib/features/order/presentation/widgets/paid_stage_filter_bar.dart
///
/// ⚠️ [orders] = PAID orders after the channel and search filters, before
/// any chip — every chip count comes from it (D13).
/// ⚠️ Same pill as `OrderStatusFilterBar` — the chip is copied, not shared
/// (that file is also used by the order history page).
/// ❌ Tapping the active chip does nothing — no clear-by-retap here (D10).
class PaidStageFilterBar extends StatelessWidget {
  final List<OrderItem> orders;
  final PaidStage selected;
  final void Function(PaidStage stage) onSelect;

  const PaidStageFilterBar({
    required this.orders,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: PaidStage.values.map((stage) {
            final isActive = selected == stage;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatusChip(
                label: paidStageLabel(stage),
                count: orders.where((o) => matchesPaidStage(o, stage)).length,
                isActive: isActive,
                onTap: () {
                  if (!isActive) {
                    onSelect(stage);
                  }
                },
              ),
            );
          }).toList(),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Brand yellow is light: the active chip needs a dark label.
    final textColor =
        isActive ? AppColors.foregroundLight : scheme.onSurfaceVariant;
    return Material(
      color: isActive ? AppColors.brandMain : scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: isActive ? AppColors.brandMain : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.foregroundLight.withValues(alpha: 0.12)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
