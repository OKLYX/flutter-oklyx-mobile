import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import '../../domain/entities/inquiry_detail.dart';
import '../bloc/inquiry_detail_bloc.dart';
import '../bloc/inquiry_detail_event.dart';

/// 고객문의 답변 컴포저 — 상세 화면 스레드 **바로 아래**에 붙는다 (FEATURE_2609_36 / 03).
///
/// **용도**: 서버가 준 [ReplyCapability] 만 보고 입력창을 열지·몇 자까지 받을지·확인
/// 대화상자를 띄울지를 정한다. 전송 이벤트는 [InquiryDetailBloc] 에 넘긴다.
/// **파일**: lib/features/inquiry/presentation/widgets/inquiry_reply_composer.dart
///
/// **사용 예제**:
/// ```dart
/// InquiryReplyComposer(
///   capability: state.detail.replyCapability,
///   submitting: state.submitting,
///   replyForbidden: state.replyForbidden,
///   replyUnknown: state.replyUnknown,
/// )
/// ```
///
/// 렌더 규칙(위에서부터 순서대로 판정):
/// 1. [replyForbidden] → 입력 없이 권한 안내 한 줄만(PLAN M5)
/// 2. [capability] == null → 아무것도 그리지 않는다(아직 로드 전)
/// 3. `canReply == false` → 입력 없이 서버 [ReplyCapability.reason] 한 줄
/// 4. 그 외 → 입력 영역
///
/// 🔴 **금지 패턴**
/// - 유형·플랫폼 분기(`if (type == PRODUCT_QNA)`) — 판정은 서버 한 곳이다(PLAN M3).
/// - 길이 상수·사유 문구 하드코딩 — `minLength`·`maxLength`·`reason` 은 서버가 준다.
/// - `once` 를 무시하고 확인을 **항상** 띄우는 하드코딩 — 판정은 서버가 소유한다.
/// - 위젯에 `confirming` 같은 확인 단계 상태 — 이 위젯의 상태는 [TextEditingController]
///   하나뿐이고, 확인 결과는 `await showDialog<bool>` 의 반환값으로만 받는다.
/// - 확인 안내를 입력창 아래 **인라인**으로 그리는 것 — 답변이 이미 달린 것처럼 보인다(M11).
///
/// ⚠️ 전송은 되돌릴 수 없다(2609_23 D17) — 쿠팡에 답변 수정·삭제 API 가 없다.
/// ⚠️ 글자수는 `trim().length` 로 세고 전송도 trim 한 값을 보낸다(서버가 `@NotBlank` + 길이검증).
/// ⚠️ `TextField.maxLength` 로 하드 컷 하지 않는다 — 사용자가 쓴 글이 말없이 잘리는 것보다
/// 버튼 비활성이 낫다.
class InquiryReplyComposer extends StatefulWidget {
  /// 서버 판정(PLAN M3). null 이면 아직 단건 조회 전이다.
  final ReplyCapability? capability;

  /// 전송 중 — 입력·버튼을 잠근다.
  final bool submitting;

  /// 403 을 받았다 → 권한 안내만 남긴다. ⚠️ 빨간 실패 SnackBar 를 띄우지 않는다.
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
              border: OutlineInputBorder(),
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
                ElevatedButton(
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
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      );

  /// 되돌릴 수 없는 전송이라 [ReplyCapability.once] 일 때 확인을 한 번 더 받는다(D17).
  ///
  /// ⚠️ 확인은 `AlertDialog` 안에서 시작해 다이얼로그와 함께 사라진다 — 화면에 잔류시키지
  /// 않는다(M11). 바텀시트로 새 관례를 만들지 말 것(입력 없는 확인이다).
  Future<void> _submit(
    BuildContext context,
    ReplyCapability capability,
  ) async {
    final bloc = context.read<InquiryDetailBloc>();
    // 확인 화면에 보인 글과 실제로 보내는 글은 같아야 한다 — 둘 다 trim 한 값이다.
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    if (capability.once) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('답변 전송'),
          // 무엇을 확정하는지 본문 그대로 보여준다 — 길 수 있어 스크롤을 둔다.
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('전송한 답변은 수정하거나 삭제할 수 없습니다.'),
                const SizedBox(height: 12),
                Text(trimmed),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('보내기'),
            ),
          ],
        ),
      );
      // 다이얼로그가 열려 있는 사이 페이지를 벗어날 수 있다.
      if (ok != true || bloc.isClosed) return;
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
