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

/// 동기화 버튼: 외부 마켓플레이스 주문 동기화 후 목록 갱신
class SyncOrders extends OrderListEvent {}

/// 상태 필터 버튼 선택 (null = 전체). 같은 상태를 다시 누르면 해제(전체)된다.
class SelectStatus extends OrderListEvent {
  final String? status;

  SelectStatus({this.status});
}

/// 주문목록 다운로드 버튼: 현재 선택된 판매자 기준으로 Shipping Label xlsx 를
/// 서버에서 받아 기기 다운로드 폴더에 저장한다.
class DownloadShippingLabel extends OrderListEvent {}
