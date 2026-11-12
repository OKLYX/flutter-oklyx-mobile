import 'package:flutter/material.dart';

import '../../domain/entities/claim.dart';

/// Bottom sheet for an action with `requires == 'REASON_TEXT'` — one reason
/// text, 1~200 characters, nothing to pick (FEATURE_2611_23 / D78 · R56).
///
/// **Purpose**: the LotteON [반품 보류 해제] · [교환 보류 해제].
/// `ClaimActionSheet` opens it by `requires` only, so this sheet does not
/// look at the claim type or platform (same as `ClaimReasonSheet`).
/// **File**:
/// lib/features/claim/presentation/widgets/claim_reason_text_sheet.dart
///
/// **Usage**:
/// ```dart
/// showAppSheet<void>(
///   context,
///   builder: (ctx) => ClaimReasonTextSheet(
///     claim: claim,
///     action: action,
///     onSubmit: (value) => text = value,
///   ),
/// );
/// ```
///
/// ⚠️ [ClaimAction.hint] is a server sentence shown gray under the text box.
/// ⚠️ **This sheet does not send** and asks no confirm — it closes and calls
/// [onSubmit] once with the trimmed text. Sending, toasts and reloading stay
/// in `ClaimActionSheet`.
/// ❌ No `setState` — the button follows the text controller (R57).
class ClaimReasonTextSheet extends StatefulWidget {
  final Claim claim;

  /// The server entry as is. Title = [ClaimAction.label].
  final ClaimAction action;

  /// Called once with the trimmed text.
  final ValueChanged<String> onSubmit;

  const ClaimReasonTextSheet({
    required this.claim,
    required this.action,
    required this.onSubmit,
    super.key,
  });

  @override
  State<ClaimReasonTextSheet> createState() => _ClaimReasonTextSheetState();
}

class _ClaimReasonTextSheetState extends State<ClaimReasonTextSheet> {
  static const int _maxLength = 200;

  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _textController.text.trim();
    Navigator.pop(context);
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final label = action.label.isEmpty ? action.action : action.label;
    final hint = action.hint;

    return Padding(
      // Keeps clear of the keyboard and the nav bar overlay.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLength: _maxLength,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '사유 글 (1~200자)'),
            ),
            if (hint != null && hint.isNotEmpty)
              Text(
                hint,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, _) {
                final text = value.text.trim();
                final ready = text.isNotEmpty && text.length <= _maxLength;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: ready ? _onSend : null,
                        child: const Text('보내기'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
