abstract class ProductListingListEvent {}

/// 플랫폼 선택 후 검색 (page 0 부터 새로 조회)
class SearchProductListings extends ProductListingListEvent {
  final String platform;

  SearchProductListings({required this.platform});
}

/// 다음 페이지 로드 (무한 스크롤)
class LoadMoreProductListings extends ProductListingListEvent {}

/// 행 펼치기/접기 토글 (펼칠 때 옵션 로드)
class ToggleListingOptions extends ProductListingListEvent {
  final int listingId;

  ToggleListingOptions({required this.listingId});
}
