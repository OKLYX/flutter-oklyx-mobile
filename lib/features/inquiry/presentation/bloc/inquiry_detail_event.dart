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
