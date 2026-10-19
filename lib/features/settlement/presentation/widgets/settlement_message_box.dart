import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Tone of a [SettlementMessageBox] — the web box colors of the settlement
/// screens (FEATURE_2610_20 / D22).
enum SettlementMessageTone {
  /// Blue — a normal notice (load result, minimum interval).
  info,

  /// Amber — rate limit, first-month question.
  warning,

  /// Red — a failure.
  error,

  /// Gray — 「금액만 기록」 · 11st 「맞춰 볼 총액 없음」 · references (never a warning).
  neutral,
}

/// One colored message box of the settlement and sales screens
/// (FEATURE_2610_20).
///
/// **File**:
/// lib/features/settlement/presentation/widgets/settlement_message_box.dart
///
/// ```dart
/// SettlementMessageBox(
///   tone: SettlementMessageTone.info,
///   message: state.syncNotice,
/// )
/// SettlementMessageBox(
///   tone: SettlementMessageTone.neutral,
///   message: kNoTotalNotice,
/// )
/// ```
///
/// ⚠️ [child] replaces [message] when the box needs more than one text
/// (buttons, rows).
class SettlementMessageBox extends StatelessWidget {
  final SettlementMessageTone tone;
  final String message;
  final Widget? child;

  const SettlementMessageBox(
      {required this.tone, super.key, this.message = '', this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color surface, Color border, Color foreground) = switch (tone) {
      SettlementMessageTone.info => (
          AppColors.infoSurface,
          AppColors.infoBorder,
          AppColors.infoForeground
        ),
      SettlementMessageTone.warning => (
          AppColors.warningSurface,
          AppColors.warningBorder,
          AppColors.warningForeground,
        ),
      SettlementMessageTone.error => (
          scheme.errorContainer,
          scheme.errorContainer,
          scheme.error
        ),
      SettlementMessageTone.neutral => (
          scheme.surfaceContainerLow,
          scheme.outlineVariant,
          scheme.onSurfaceVariant,
        ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground, fontSize: 13),
        child: child ?? Text(message),
      ),
    );
  }
}
