import '../../domain/entities/order_item.dart';
import '../../domain/entities/sync_target.dart';

abstract class OrderListEvent {}

/// 페이지 진입 시: 판매자 목록 + 전체 주문 로드 (프론트의 초기 useEffect와 동일)
class LoadOrders extends OrderListEvent {}

/// 판매자 드롭다운 선택 변경 (null = 전체)
class SelectSeller extends OrderListEvent {
  final int? sellerId;

  SelectSeller({this.sellerId});
}

/// 조회 버튼: 현재 선택된 판매자 기준으로 주문 재조회
class SearchOrders extends OrderListEvent {}

/// 동기화 버튼: 동기화 대상 채널을 조회한 뒤 계정 단위로 순차 동기화한다.
class SyncOrders extends OrderListEvent {}

/// 진행 중 취소. 현재 채널은 끝까지 진행되고 다음 채널부터 중단된다(PLAN D12).
class CancelSync extends OrderListEvent {}

/// 이번 실행에서 실패한 채널만 다시 동기화.
class RetryFailedChannels extends OrderListEvent {}

/// 배너의 [해당 채널만 다시 조회] — 지정한 채널만 다시 동기화한다.
/// [RetryFailedChannels]와 진입점만 다르고 동작은 같다.
class SyncSelectedChannels extends OrderListEvent {
  final List<SyncTarget> targets;

  SyncSelectedChannels({required this.targets});
}

/// 상태 필터 버튼 선택 (null = 전체). 같은 상태를 다시 누르면 해제(전체)된다.
class SelectStatus extends OrderListEvent {
  final String? status;

  SelectStatus({this.status});
}

/// 조회 기간 선택. ⚠️ 값만 바꾼다 — 반영은 [SearchOrders](조회 버튼)에서(PLAN D8).
class SelectPeriod extends OrderListEvent {
  final String period;

  SelectPeriod({required this.period});
}

/// 검색 대상 칩 변경 (고객명 ↔ 주문번호). 즉시 필터.
class ChangeSearchField extends OrderListEvent {
  final OrderSearchField field;

  ChangeSearchField({required this.field});
}

/// 검색어 입력. 즉시 필터 — 서버를 부르지 않는다(PLAN D9).
class ChangeSearchTerm extends OrderListEvent {
  final String term;

  ChangeSearchTerm({required this.term});
}
