import 'package:flutter/material.dart';

/// The one confirmation dialog of the app (FEATURE_2610_02 · N9; moved here
/// from the master screens).
///
/// **Purpose**: title · one block of text · two text buttons ([취소] / confirm)
/// — or, with `showCancel: false` (FEATURE_2610_13 / D125), the confirm
/// button alone: a notice that only needs acknowledging (web `ConfirmDialog`
/// without `onCancel`). A dangerous action shows the confirm label in red.
/// Tapping outside cancels.
/// **File**: lib/shared/widgets/app_confirm_dialog.dart
/// Returns `true` on confirm; cancel, barrier tap and back return `false`.
///
/// **Usage**:
/// ```dart
/// final ok = await showAppConfirmDialog(
///   context,
///   title: '마스터 삭제',
///   message: '… 되돌릴 수 없습니다.',
///   confirmText: '삭제',
///   isDangerous: true,
/// );
/// if (!ok) return;
///
/// // A notice with one [확인] button (D125)
/// await showAppConfirmDialog(context,
///     title: '배송 설정 저장', message: note, showCancel: false);
/// ```
///
/// ⚠️ A body made of several blocks is joined with one blank line (`\n\n`)
///    into [message]; the wording stays as it was.
/// ⚠️ [isDangerous] is `true` only where the confirm button was already red.
/// ❌ Do not add or remove a confirmation or notice that no decision asked for.
/// ❌ Do not build an `AlertDialog` for a yes/no question in a page.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String message,
  String? title,
  String confirmText = '확인',
  String cancelText = '취소',
  bool isDangerous = false,
  bool showCancel = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          if (showCancel)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: scheme.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
