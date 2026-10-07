import 'package:flutter/material.dart';

import '../../data/models/reserved_shipment_row.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Chip value on the reserved shipment page (FEATURE_2610_07 / D1·D2).
enum ReservedFilter { open, done, all }

/// Chip labels — same text as the web card.
String reservedFilterLabel(ReservedFilter filter) => switch (filter) {
      ReservedFilter.open => '처리 필요',
      ReservedFilter.done => '완료',
      ReservedFilter.all => '전체',
    };

/// [ReservedFilter.open] = [ReservedShipmentRow.isOpen] rows,
/// [ReservedFilter.done] = the rest, [ReservedFilter.all] = every row.
/// The result values are never listed again here (D2).
bool matchesReservedFilter(ReservedShipmentRow row, ReservedFilter filter) =>
    switch (filter) {
      ReservedFilter.open => row.isOpen,
      ReservedFilter.done => !row.isOpen,
      ReservedFilter.all => true,
    };

/// Reserved shipment chip bar — single choice with a count on each chip.
///
/// **Purpose**: narrows the cards of the reserved shipment page. Counts come
/// from every received row, whichever chip is on (D6).
/// **File**:
/// lib/features/shipping_label/presentation/widgets/reserved_filter_bar.dart
///
/// ⚠️ Same pill as `OrderStatusFilterBar` — the chip is copied, not shared
/// (that file is also used by the order history page).
/// ❌ Not for the order detail history section — it shows every row of one
/// order (D4).
class ReservedFilterBar extends StatelessWidget {
  final List<ReservedShipmentRow> rows;
  final ReservedFilter selected;
  final void Function(ReservedFilter filter) onSelect;

  const ReservedFilterBar({
    required this.rows,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReservedFilter.values
              .map(
                (filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _StatusChip(
                    label: reservedFilterLabel(filter),
                    count: rows
                        .where((r) => matchesReservedFilter(r, filter))
                        .length,
                    isActive: selected == filter,
                    onTap: () => onSelect(filter),
                  ),
                ),
              )
              .toList(),
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
