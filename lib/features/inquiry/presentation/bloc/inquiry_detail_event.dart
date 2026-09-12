abstract class InquiryDetailEvent {}

/// 진입 시 1회 — `GET /api/inquiries/{id}` (PLAN M1).
class LoadInquiry extends InquiryDetailEvent {
  final int id;

  LoadInquiry({required this.id});
}

/// [새로고침] · [다시 시도] 재조회.
///
/// 🔴 **인자가 없다** — BLoC 이 마지막 id 를 들고 있어야 한다. 화면이 id 를 다시 넘기게
/// 만들면 답변 전송(03)의 회복 경로에서 컴포저가 id 를 또 알아야 한다.
class ReloadInquiry extends InquiryDetailEvent {}

/// 답변 전송 — `POST /api/admin/inquiries/{id}/replies` (FEATURE_2609_36 / 03).
///
/// 🔴 되돌릴 수 없다(2609_23 D17). [content] 는 **이미 trim 된 본문**이다 — 확인 다이얼로그에
/// 보인 글과 실제로 보내는 글이 달라지면 안 되므로 위젯이 trim 해서 넘긴다.
/// ⚠️ 문의 id 를 싣지 않는다 — BLoC 이 마지막 id 를 들고 있다([ReloadInquiry] 와 같은 이유).
class SubmitReply extends InquiryDetailEvent {
  final String content;

  SubmitReply(this.content);
}

/// 전송 실패 문구를 SnackBar 로 소비한 뒤 비운다(목록의 `ActionErrorCleared` 관례).
class ReplyErrorCleared extends InquiryDetailEvent {}
