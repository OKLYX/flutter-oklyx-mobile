import '../../domain/entities/product_listing.dart';

abstract class ProductListingListState {}

/// 검색 전 초기 상태
class ProductListingListInitial extends ProductListingListState {}

/// 첫 검색 로딩 (전체 화면 스피너)
class ProductListingListLoading extends ProductListingListState {}

/// 조회 실패
class ProductListingListError extends ProductListingListState {
  final String message;

  ProductListingListError({required this.message});
}

/// 조회 성공 (목록 + 페이지네이션 + 옵션 펼침 상태)
///
/// 옵션(판매가/마진/마진율)은 목록 조회 응답의 각 listing.options 에 포함되어
/// 온다(프론트와 동일). 따라서 별도 fetch/cache 없이 [expandedId] 로 현재
/// 펼쳐진 행만 추적한다.
class ProductListingListLoaded extends ProductListingListState {
  final String platform;
  final List<ProductListing> listings;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final int? expandedId;

  ProductListingListLoaded({
    required this.platform,
    required this.listings,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.expandedId,
  });

  ProductListingListLoaded copyWith({
    String? platform,
    List<ProductListing>? listings,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    int? expandedId,
    bool clearExpanded = false,
  }) {
    return ProductListingListLoaded(
      platform: platform ?? this.platform,
      listings: listings ?? this.listings,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      expandedId: clearExpanded ? null : (expandedId ?? this.expandedId),
    );
  }
}
