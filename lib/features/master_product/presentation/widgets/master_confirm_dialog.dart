import 'package:flutter/material.dart';

/// Confirmation dialog for the master screens — mobile counterpart of the web
/// `ConfirmDialog` / `window.confirm` (FEATURE_2609_80 R-d).
///
/// **File**: lib/features/master_product/presentation/widgets/master_confirm_dialog.dart
/// Returns `true` on confirm; cancel, barrier tap and back return `false`.
///
/// **Usage**:
/// ```dart
/// final ok = await showMasterConfirmDialog(
///   context,
///   title: '마스터 삭제',
///   message: '… 되돌릴 수 없습니다.',
///   confirmText: '삭제',
///   isDangerous: true,
/// );
/// if (!ok) return;
/// ```
///
/// ⚠️ Copy title, body and button labels verbatim from the web call site. The
///    web `window.confirm` has no title, so leave [title] `null` there.
/// ❌ Do not add new confirmations — they exist only for marketplace pushes
///    and irreversible removals (D23/D29/D32).
Future<bool> showMasterConfirmDialog(
  BuildContext context, {
  required String message,
  String? title,
  String confirmText = '확인',
  String cancelText = '취소',
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
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
