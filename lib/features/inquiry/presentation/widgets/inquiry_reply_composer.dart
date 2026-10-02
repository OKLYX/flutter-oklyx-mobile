import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import '../../domain/entities/inquiry_detail.dart';
import '../bloc/inquiry_detail_bloc.dart';
import '../bloc/inquiry_detail_event.dart';

/// Customer inquiry reply composer — attached **right below** the thread on
/// the detail screen (FEATURE_2609_36 / 03).
///
/// **Purpose**: looks only at the [ReplyCapability] given by the server to
/// decide whether to open the input, how many characters to accept and whether
/// to show the confirm dialog. The send event is handed to [InquiryDetailBloc].
/// **File**: lib/features/inquiry/presentation/widgets/inquiry_reply_composer.dart
///
/// **Usage**:
/// ```dart
/// InquiryReplyComposer(
///   capability: state.detail.replyCapability,
///   submitting: state.submitting,
///   replyForbidden: state.replyForbidden,
///   replyUnknown: state.replyUnknown,
/// )
/// ```
///
/// Render rules (checked in order from the top):
/// 1. [replyForbidden] → no input, only one line of permission notice (PLAN M5)
/// 2. [capability] == null → draws nothing (not loaded yet)
/// 3. `canReply == false` → no input, one line of the server's
///    [ReplyCapability.reason]
/// 4. otherwise → the input area
///
/// 🔴 **Forbidden patterns**
/// - Branching on type / platform (`if (type == PRODUCT_QNA)`) — the decision
///   is made in one place, the server (PLAN M3).
/// - Hard-coding length constants or reason texts — `minLength`, `maxLength`
///   and `reason` come from the server.
/// - Hard-coding that ignores `once` and **always** shows the confirmation —
///   the server owns the decision.
/// - A confirmation-step state such as `confirming` in the widget — the only
///   state of this widget is the [TextEditingController], and the confirmation
///   result is taken only from the return value of
///   `await showAppConfirmDialog`.
/// - Drawing the confirmation notice **inline** below the input — it looks as
///   if the reply were already posted (M11).
///
/// ⚠️ Sending cannot be undone (2609_23 D17) — Coupang has no API to edit or
/// delete a reply.
/// ⚠️ Characters are counted with `trim().length` and the trimmed value is
/// what gets sent (the server has `@NotBlank` + length validation).
/// ⚠️ No hard cut with `TextField.maxLength` — a disabled button is better
/// than silently truncating what the user wrote.
class InquiryReplyComposer extends StatefulWidget {
  /// 서버 판정(PLAN M3). null 이면 아직 단건 조회 전이다.
  final ReplyCapability? capability;

  /// 전송 중 — 입력·버튼을 잠근다.
  final bool submitting;

  /// A 403 was received → only the permission notice stays. ⚠️ No red failure
  /// toast is shown.
  final bool replyForbidden;

  /// 502 — 전송 결과 미상. 입력을 잠근 채 경고만 띄운다(재전송 유도 금지).
  final bool replyUnknown;

  const InquiryReplyComposer({
    super.key,
    required this.capability,
    required this.submitting,
    required this.replyForbidden,
    required this.replyUnknown,
  });

  @override
  State<InquiryReplyComposer> createState() => _InquiryReplyComposerState();
}

class _InquiryReplyComposerState extends State<InquiryReplyComposer> {
  /// 본문은 위젯의 로컬 상태다 — 글자마다 BLoC 이 emit 하면 리빌드가 낭비다.
  final TextEditingController _controller = TextEditingController();

  /// 403 안내 문구. **서버가 주지 않으므로**(403 본문은 일반 권한 오류다) 앱 상수로 둔다.
  /// 서버가 주는 [ReplyCapability.reason] 과 섞지 말 것.
  static const String _forbiddenNotice = '답변 전송 권한이 없는 계정입니다.';

  static const String _unknownNotice =
      '전송 결과를 확인하지 못했습니다. 위 [새로고침] 으로 답변이 등록됐는지 확인하세요.';

  @override
  void dispose() {
    _controller.dispose(); // 누락 시 leak — 상세는 문의마다 새로 만들어진다.
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InquiryReplyComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 전송이 끝났고 실패 신호가 없다 = 성공 → 입력창을 비운다. 잠금은 별도 플래그 없이
    // 갱신된 `canReply == false` 가 렌더 규칙 3으로 처리한다.
    final finished = oldWidget.submitting && !widget.submitting;
    final succeeded = !widget.replyForbidden && !widget.replyUnknown;
    if (finished && succeeded) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 서버가 403 으로 거절했다 — 입력 영역을 감춘다(M5).
    if (widget.replyForbidden) {
      return _wrap(const _Notice(text: _forbiddenNotice));
    }

    // 2. 아직 단건 조회 전 — 아무것도 그리지 않는다.
    final capability = widget.capability;
    if (capability == null) return const SizedBox.shrink();

    // 3. 답변 불가는 서버 판정이다 — 입력창을 만들지 않고 서버 사유만 보여준다.
    if (!capability.canReply) {
      return _wrap(_Notice(text: capability.reason ?? '지금은 답변할 수 없습니다.'));
    }

    // 4. 입력 영역
    final scheme = Theme.of(context).colorScheme;
    final trimmed = _controller.text.trim();
    final invalidLength = trimmed.length < capability.minLength ||
        trimmed.length > capability.maxLength;
    // 502 뒤에는 이미 전송됐을 수 있어 잠근 채로 둔다(중복 전송은 400 이다).
    final locked = widget.submitting || widget.replyUnknown;
    final canSubmit = !invalidLength && !locked;

    return _wrap(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '답변 작성',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (widget.replyUnknown) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                border: Border.all(color: AppColors.warningBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                _unknownNotice,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.warningForeground,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            enabled: !locked,
            minLines: 3,
            maxLines: 5,
            // 글자마다 emit 하지 않는다 — 버튼 활성만 갱신한다.
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '고객에게 보낼 답변을 입력하세요.',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${trimmed.length} / ${capability.maxLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: invalidLength ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              if (widget.submitting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                FilledButton(
                  onPressed:
                      canSubmit ? () => _submit(context, capability) : null,
                  child: const Text('답변 전송'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 카드 + 위쪽 여백. 아무것도 그리지 않을 때는 여백도 남기지 않는다.
  Widget _wrap(Widget child) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AppCard(child: child),
      );

  /// Sending cannot be undone, so when [ReplyCapability.once] is set one more
  /// confirmation is asked for (D17).
  ///
  /// ⚠️ The confirmation starts inside `showAppConfirmDialog` and disappears
  /// with the dialog — it is not left on the screen (M11). Do not start a new
  /// convention with a bottom sheet (it is a confirmation without input).
  Future<void> _submit(
    BuildContext context,
    ReplyCapability capability,
  ) async {
    final bloc = context.read<InquiryDetailBloc>();
    // 확인 화면에 보인 글과 실제로 보내는 글은 같아야 한다 — 둘 다 trim 한 값이다.
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    if (capability.once) {
      final ok = await showAppConfirmDialog(
        context,
        title: '답변 전송',
        // Shows what is being confirmed, the reply text as written.
        message: '전송한 답변은 수정하거나 삭제할 수 없습니다.\n\n$trimmed',
        confirmText: '보내기',
      );
      // 다이얼로그가 열려 있는 사이 페이지를 벗어날 수 있다.
      if (!ok || bloc.isClosed) return;
    }

    if (bloc.isClosed) return;
    bloc.add(SubmitReply(trimmed));
  }
}

/// 입력 없이 안내 한 줄만 그리는 자리(권한 없음 · 답변 불가).
class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
    );
  }
}
