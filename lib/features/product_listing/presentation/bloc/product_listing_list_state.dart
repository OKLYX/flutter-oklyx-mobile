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
/// 프론트 "판매상품 조회"와 동일하게 행을 펼치면 옵션을 별도로 로드해
/// [optionsCache] 에 저장한다. [expandedId] 는 현재 펼쳐진 행의 id.
class ProductListingListLoaded extends ProductListingListState {
  final String platform;
  final List<ProductListing> listings;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final int? expandedId;
  final int? loadingOptionsId;
  final Map<int, List<ProductListingOption>> optionsCache;

  ProductListingListLoaded({
    required this.platform,
    required this.listings,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.expandedId,
    this.loadingOptionsId,
    this.optionsCache = const {},
  });

  ProductListingListLoaded copyWith({
    String? platform,
    List<ProductListing>? listings,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    int? expandedId,
    bool clearExpanded = false,
    int? loadingOptionsId,
    bool clearLoadingOptions = false,
    Map<int, List<ProductListingOption>>? optionsCache,
  }) {
    return ProductListingListLoaded(
      platform: platform ?? this.platform,
      listings: listings ?? this.listings,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      expandedId: clearExpanded ? null : (expandedId ?? this.expandedId),
      loadingOptionsId:
          clearLoadingOptions ? null : (loadingOptionsId ?? this.loadingOptionsId),
      optionsCache: optionsCache ?? this.optionsCache,
    );
  }
}
