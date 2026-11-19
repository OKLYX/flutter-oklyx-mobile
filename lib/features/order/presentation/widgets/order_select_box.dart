import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// 22 selection box of a shipment management row and of the select-all
/// control (FEATURE_2611_32 / D11 · D13).
///
/// **Purpose**: the tap area is 34 × 44; the right 12 of it is the gap to the
/// photo. Picked = brand yellow with a dark check (D30), not picked = white
/// with a grey border, disabled ([onTap] null) = grey fill (R7).
/// **File**: lib/features/order/presentation/widgets/order_select_box.dart
///
/// **Usage**:
/// ```dart
/// OrderSelectBox(
///   selected: selected ?? false,
///   onTap: selectable ? () => onToggle(order) : null,
/// )
/// ```
///
/// ⚠️ Inside the card `InkWell` a tap on this box does not leak to the
/// detail page (the inner gesture wins).
/// ❌ Do not switch it back to `Checkbox`.
class OrderSelectBox extends StatelessWidget {
  final bool selected;

  /// null = disabled.
  final VoidCallback? onTap;

  const OrderSelectBox({
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final Color fill;
    final BoxBorder? border;
    if (!enabled) {
      fill = colorScheme.surfaceContainerHighest;
      border = Border.all(color: colorScheme.outlineVariant, width: 1.5);
    } else if (selected) {
      fill = AppColors.brandMain;
      border = null;
    } else {
      fill = colorScheme.surface;
      border = Border.all(color: colorScheme.onSurfaceVariant, width: 1.5);
    }
    return Semantics(
      checked: selected,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: fill,
                border: border,
              ),
              child: selected && enabled
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.foregroundLight,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
