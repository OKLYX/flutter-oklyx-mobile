import '../../domain/entities/inquiry_detail.dart';

abstract class InquiryDetailState {}

class InquiryDetailInitial extends InquiryDetailState {}

/// 조회 중. ⚠️ 화면은 `extra` 로 받은 목록 항목으로 **헤더를 먼저 그리고**, 이 상태에서는
/// 스레드·관련 주문 자리에만 스피너를 놓는다(스피너만 있는 화면을 만들지 않는다).
class InquiryDetailLoading extends InquiryDetailState {}

class InquiryDetailError extends InquiryDetailState {
  final String message;

  InquiryDetailError({required this.message});
}

/// 조회 성공 (+ 답변 전송 진행/결과).
///
/// [copyWith] 로 **전송 성공 응답이 이 상태를 직접 갱신**한다 — 응답이 곧 갱신된 문의 1건이라
/// 전송 후 재조회(`ReloadInquiry`)를 부르지 않는다.
class InquiryDetailLoaded extends InquiryDetailState {
  final InquiryDetail detail;

  /// 유형 표시 문구. **서버 `/types` 가 준 라벨**이며(PLAN M2) 못 받았으면 null 이다 —
  /// 그때는 화면이 유형 칩을 그리지 않는다. 앱에 코드→라벨 표를 만들지 말 것.
  final String? typeLabel;

  /// 전송 중 — 버튼·입력을 잠근다.
  final bool submitting;

  /// 403 을 받았다 → 컴포저 자리에 권한 안내만 남긴다(PLAN M5).
  ///
  /// ⚠️ **전송을 한 번 시도한 뒤에만** true 가 된다 — 서버 `replyCapability` 는 역할을
  /// 판정하지 않으므로(비-ADMIN 에게도 `canReply = true` 가 내려온다) 앱이 미리 알 길이 없다.
  final bool replyForbidden;

  /// 전송 실패 문구(**서버 문구 그대로**). SnackBar 로 소비한 뒤 [ReplyErrorCleared] 로 비운다.
  final String? replyError;

  /// 502 — 전송 **결과를 모른다**(실패가 아니다). 로컬 상태를 건드리지 않고 입력을 잠근 채
  /// [새로고침] 으로 확인하게 한다 — 재전송은 중복이라 400 이다.
  final bool replyUnknown;

  InquiryDetailLoaded({
    required this.detail,
    this.typeLabel,
    this.submitting = false,
    this.replyForbidden = false,
    this.replyError,
    this.replyUnknown = false,
  });

  /// [clearReplyError] 는 "null 로 덮기"가 `??` 로는 불가능해서 둔다(목록 상태와 같은 관례).
  InquiryDetailLoaded copyWith({
    InquiryDetail? detail,
    String? typeLabel,
    bool? submitting,
    bool? replyForbidden,
    String? replyError,
    bool clearReplyError = false,
    bool? replyUnknown,
  }) =>
      InquiryDetailLoaded(
        detail: detail ?? this.detail,
        typeLabel: typeLabel ?? this.typeLabel,
        submitting: submitting ?? this.submitting,
        replyForbidden: replyForbidden ?? this.replyForbidden,
        replyError: clearReplyError ? null : (replyError ?? this.replyError),
        replyUnknown: replyUnknown ?? this.replyUnknown,
      );
}
