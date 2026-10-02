import 'package:flutter/material.dart';

/// Spinner + label shown inside a button while its action runs
/// (FEATURE_2610_02 · N8).
///
/// **Purpose**: small spinner 16 + gap 4 + text. A button that used to show
/// only a spinner shows the spinner plus its own label.
/// **File**: lib/shared/widgets/app_busy_label.dart
///
/// **Usage**:
/// ```dart
/// FilledButton(
///   onPressed: _isSaving ? null : _save,
///   child: _isSaving ? const AppBusyLabel('저장') : const Text('저장'),
/// )
/// ```
///
/// ⚠️ [size] / [gap] exist only for the "spinner + 불러오는 중..." loading rows
///    that keep their current shape. Inside a button never pass them.
/// ⚠️ [color] keeps the spinner color a button already had; omit it where the
///    button gave none.
/// ❌ Do not invent a new "…중" wording — reuse the button's own label.
class AppBusyLabel extends StatelessWidget {
  final String label;
  final double size;
  final double gap;
  final Color? color;

  const AppBusyLabel(
    this.label, {
    super.key,
    this.size = 16,
    this.gap = 4,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          SizedBox(width: gap),
          Text(label),
        ],
      );
}
