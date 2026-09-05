import '../../domain/entities/claim.dart';

abstract class ClaimListEvent {}

/// 페이지 진입 시: 판매자 목록 + 기본 창(최근 2주) 클레임 조회.
class LoadClaims extends ClaimListEvent {}

/// 판매자 드롭다운 선택 변경 (null = 전체). ⚠️ 값만 바꾼다 — 반영은 [SearchClaims].
class SelectSeller extends ClaimListEvent {
  final int? sellerId;

  SelectSeller({this.sellerId});
}

/// 조회 기간 선택. ⚠️ 값만 바꾼다 — 반영은 [SearchClaims](조회 버튼).
class SelectPeriod extends ClaimListEvent {
  final String period;

  SelectPeriod({required this.period});
}

/// 검색어 입력. ⚠️ 값만 바꾼다 — 검색은 **서버**가 하므로 [SearchClaims] 때 전송된다.
class ChangeSearchTerm extends ClaimListEvent {
  final String term;

  ChangeSearchTerm({required this.term});
}

/// 조회 버튼: 판매자·기간·검색어를 서버로 보내 재조회.
class SearchClaims extends ClaimListEvent {}

/// 상태 칩 선택 (null = 전체). **클라이언트 필터라 서버를 부르지 않는다.**
/// 같은 상태를 다시 누르면 해제(전체)된다.
class SelectStatus extends ClaimListEvent {
  final ClaimStatus? status;

  SelectStatus({this.status});
}
