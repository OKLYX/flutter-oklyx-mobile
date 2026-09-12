import '../../domain/entities/inquiry.dart';

abstract class InquiryListEvent {}

/// 페이지 진입: 유형 목록 + 판매자 + 동기화 대상 + 기본 창(최근 14일) 문의 조회.
class LoadInquiries extends InquiryListEvent {}

/// 유형 탭 전환. **서버 파라미터**라 즉시 재조회한다(상태 칩과 반대다).
class SelectType extends InquiryListEvent {
  final InquiryType type;

  SelectType({required this.type});
}

/// 판매자 선택 (null = 전체). ⚠️ 값만 바꾼다 — 반영은 [SearchInquiries].
/// 채널 옵션은 판매자에 따라 다시 불러온다(웹과 같은 처리).
class SelectSeller extends InquiryListEvent {
  final int? sellerId;

  SelectSeller({this.sellerId});
}

/// 채널(계정) 선택 (null = 전체). ⚠️ 값만 바꾼다 — 반영은 [SearchInquiries].
class SelectChannel extends InquiryListEvent {
  final int? accountId;

  SelectChannel({this.accountId});
}

/// 조회 기간 선택. ⚠️ 값만 바꾼다 — 반영은 [SearchInquiries].
class SelectPeriod extends InquiryListEvent {
  final String period;

  SelectPeriod({required this.period});
}

/// 검색어 입력. ⚠️ 값만 바꾼다 — 검색은 **서버**가 하므로 [SearchInquiries] 때 전송된다.
class ChangeSearchTerm extends InquiryListEvent {
  final String term;

  ChangeSearchTerm({required this.term});
}

/// 조회 버튼: 유형·판매자·채널·기간·검색어를 서버로 보내 재조회.
class SearchInquiries extends InquiryListEvent {}

/// 상태 칩 선택 (null = 전체). **클라이언트 필터라 서버를 부르지 않는다.**
/// 같은 상태를 다시 누르면 해제(전체)된다.
class SelectStatus extends InquiryListEvent {
  final InquiryStatus? status;

  SelectStatus({this.status});
}

/// 문의만 가져오기 — 선택 채널(없으면 동기화 대상 전부)을 순회한다(PLAN M4).
class SyncInquiries extends InquiryListEvent {}

/// SnackBar 로 소비한 뒤 에러/요약 문구를 비운다.
class ActionErrorCleared extends InquiryListEvent {}
