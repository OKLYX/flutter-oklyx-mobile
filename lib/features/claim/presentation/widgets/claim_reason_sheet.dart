import 'package:flutter/material.dart';

import '../../domain/entities/claim.dart';
import 'claim_action_sheet.dart';

/// The reason code + reason text a [ClaimReasonSheet] hands back.
class ClaimReasonInput {
  final String code;
  final String text;

  const ClaimReasonInput({required this.code, required this.text});
}

/// Bottom sheet for an action with `requires == 'REASON'` — a reason code and
/// a reason text, both required (FEATURE_2610_17 / D34 · D39 ①).
///
/// **Purpose**: the 11st [반품 거부] · [반품 보류] · [반품완료 보류] and the 11st
/// [교환 거부]. [ClaimActionSheet] opens it by `requires` only, so this sheet
/// does not look at the claim type or platform (same as [ClaimRejectSheet]).
/// **File**: lib/features/claim/presentation/widgets/claim_reason_sheet.dart
///
/// **Usage**:
/// ```dart
/// showAppSheet<void>(
///   context,
///   builder: (ctx) => ClaimReasonSheet(
///     claim: claim,
///     action: action,
///     onSubmit: (input) => reason = input,
///   ),
/// );
/// ```
///
/// 🔴 No code→label map in the app — choices come from the server's
/// [ClaimAction.choices] (values and labels as they are).
/// ⚠️ The text limit is 1~200 characters (D39 ①); the server checks the same.
/// ⚠️ [ClaimAction.hint] is a server sentence shown under the text box
/// (D34 · D39 ④) — shown as is.
/// ⚠️ **This sheet does not send.** An irreversible action asks the confirm
/// dialog here; then the sheet closes and calls [onSubmit] once. Sending,
/// loading, toasts and reloading stay in [ClaimActionSheet].
class ClaimReasonSheet extends StatefulWidget {
  final Claim claim;

  /// The server entry as is. Title and confirm label = [ClaimAction.label].
  final ClaimAction action;

  /// Called once with the chosen code and the trimmed text.
  final ValueChanged<ClaimReasonInput> onSubmit;

  const ClaimReasonSheet({
    super.key,
    required this.claim,
    required this.action,
    required this.onSubmit,
  });

  @override
  State<ClaimReasonSheet> createState() => _ClaimReasonSheetState();
}

class _ClaimReasonSheetState extends State<ClaimReasonSheet> {
  static const int _maxLength = 200;

  final TextEditingController _textController = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final label = action.label.isEmpty ? action.action : action.label;
    final text = _textController.text.trim();
    final ready =
        _selected != null && text.isNotEmpty && text.length <= _maxLength;
    final hint = action.hint;

    return Padding(
      // Keeps clear of the keyboard and the nav bar overlay (ScaffoldWithNavBar).
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
            ...action.choices.map(
              (c) => RadioListTile<String>(
                value: c.code,
                groupValue: _selected,
                contentPadding: EdgeInsets.zero,
                title: Text(c.label.isEmpty ? c.code : c.label),
                onChanged: (v) => setState(() => _selected = v),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLength: _maxLength,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
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
            FilledButton(
              style: action.irreversible
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      minimumSize: const Size(0, 48),
                    )
                  : FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: ready ? _onConfirm : null,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  /// Irreversible → two-step confirm (D10 · D34) → close → hand back.
  Future<void> _onConfirm() async {
    final code = _selected;
    if (code == null) return;
    final text = _textController.text.trim();
    final action = widget.action;
    final label = action.label.isEmpty ? action.action : action.label;
    if (action.irreversible) {
      final reason = action.choices
          .firstWhere(
            (choice) => choice.code == code,
            orElse: () => ActionChoice(code: code, label: code),
          )
          .label;
      final c = widget.claim;
      final confirmed = await showClaimConfirmDialog(
        context,
        title: c.itemName ?? '-',
        lines: [
          '수량 ${c.quantity}개',
          '사유: $reason',
          '$label은(는) 되돌릴 수 없습니다.',
        ],
        confirmLabel: label,
      );
      if (!confirmed || !mounted) return;
    }
    Navigator.pop(context);
    widget.onSubmit(ClaimReasonInput(code: code, text: text));
  }
}
