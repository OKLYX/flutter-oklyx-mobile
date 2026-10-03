import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// One choice of an [AppFilterChip] menu.
class AppFilterOption<T> {
  final T value;
  final String label;

  const AppFilterOption(this.value, this.label);
}

/// Pill chip that picks one search condition of a list page
/// (FEATURE_2610_03 · D132 · D136).
///
/// **Purpose**: one shape for the choice conditions (seller · channel ·
/// period · sort · platform) of the list-page search areas — pill, height 32,
/// border `outline`, ▾ after the text. A tap opens a menu right below the
/// chip ([showAppFilterMenu]); the current value has a check mark.
/// **File**: lib/shared/widgets/app_filter_chip.dart
///
/// **Usage**:
/// ```dart
/// AppFilterChip<int?>(
///   label: sellerId == null ? '판매자' : sellerName,
///   value: sellerId,
///   options: [
///     const AppFilterOption(null, '전체'),
///     for (final s in sellers) AppFilterOption(s.id, s.sellerName),
///   ],
///   highlighted: sellerId != null,
///   onSelected: busy ? null : (id) => bloc.add(SelectSeller(sellerId: id)),
/// )
/// ```
///
/// ⚠️ [label] = the label word while 「전체」 / 「선택하세요」 is picked,
///    otherwise the picked value (D132 ②). The page decides it.
/// ⚠️ [highlighted] = a value other than the default is picked → yellow
///    border, the same mark as the order status chips (D132 ③).
/// ⚠️ [onSelected] null = the chip does not open (while loading or syncing —
///    D132 ⑤). Picking the current value again also calls [onSelected], like
///    the dropdown it replaces.
/// ❌ Do not open the choices in a bottom sheet (D132 · D116).
class AppFilterChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<AppFilterOption<T>> options;
  final bool highlighted;
  final ValueChanged<T>? onSelected;

  const AppFilterChip({
    required this.label,
    required this.value,
    required this.options,
    super.key,
    this.highlighted = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onSelected != null;
    final foreground =
        enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.38);
    return Material(
      color: scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: highlighted ? AppColors.brandMain : scheme.outline,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: enabled ? () => _open(context) : null,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 14, color: foreground),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down, size: 18, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked =
        await showAppFilterMenu<T>(context, value: value, options: options);
    if (picked == null || !context.mounted) {
      return;
    }
    onSelected?.call(picked.value);
  }
}

/// Opens a choice menu right below the widget of [context] (D132 ①④) —
/// used by [AppFilterChip] and the search target box of the order pages.
/// Returns the picked option, or null when the menu closes without a pick.
Future<AppFilterOption<T>?> showAppFilterMenu<T>(
  BuildContext context, {
  required T value,
  required List<AppFilterOption<T>> options,
}) {
  final box = context.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final bottomLeft = box.localToGlobal(
    box.size.bottomLeft(Offset.zero),
    ancestor: overlay,
  );
  final bottomRight = box.localToGlobal(
    box.size.bottomRight(Offset.zero),
    ancestor: overlay,
  );
  return showMenu<AppFilterOption<T>>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(bottomLeft, bottomRight),
      Offset.zero & overlay.size,
    ),
    items: [
      for (final option in options)
        PopupMenuItem<AppFilterOption<T>>(
          value: option,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: option.value == value
                    ? const Icon(Icons.check, size: 18)
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(option.label)),
            ],
          ),
        ),
    ],
  );
}
