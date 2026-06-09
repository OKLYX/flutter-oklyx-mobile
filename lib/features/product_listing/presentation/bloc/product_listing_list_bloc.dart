import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/product_listing_usecase.dart';
import 'product_listing_list_event.dart';
import 'product_listing_list_state.dart';

/// 판매상품 조회(목록) BLoC
///
/// 프론트 "판매상품 조회" 기능과 동일하게 동작한다:
/// - 플랫폼 선택 후 검색 ([SearchProductListings])
/// - 무한 스크롤 페이지네이션 ([LoadMoreProductListings])
/// - 행을 펼치면 옵션을 별도로 로드 ([ToggleListingOptions])
class ProductListingListBloc
    extends Bloc<ProductListingListEvent, ProductListingListState> {
  final ProductListingUseCase productListingUseCase;

  static const int _pageSize = 20;

  ProductListingListBloc({required this.productListingUseCase})
      : super(ProductListingListInitial()) {
    on<SearchProductListings>(_onSearch);
    on<LoadMoreProductListings>(_onLoadMore);
    on<ToggleListingOptions>(_onToggleOptions);
  }

  Future<void> _onSearch(
    SearchProductListings event,
    Emitter<ProductListingListState> emit,
  ) async {
    emit(ProductListingListLoading());

    final result = await productListingUseCase.getByPlatform(
      event.platform,
      page: 0,
      size: _pageSize,
    );

    result.fold(
      (failure) => emit(ProductListingListError(message: failure.message)),
      (listings) => emit(ProductListingListLoaded(
        platform: event.platform,
        listings: listings,
        currentPage: 0,
        hasMore: listings.length == _pageSize,
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreProductListings event,
    Emitter<ProductListingListState> emit,
  ) async {
    final current = state;
    if (current is! ProductListingListLoaded) return;
    if (current.isLoadingMore || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await productListingUseCase.getByPlatform(
      current.platform,
      page: nextPage,
      size: _pageSize,
    );

    result.fold(
      (failure) => emit(ProductListingListError(message: failure.message)),
      (listings) => emit(current.copyWith(
        listings: [...current.listings, ...listings],
        currentPage: nextPage,
        hasMore: listings.length == _pageSize,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onToggleOptions(
    ToggleListingOptions event,
    Emitter<ProductListingListState> emit,
  ) async {
    final current = state;
    if (current is! ProductListingListLoaded) return;

    // 이미 펼쳐진 행을 다시 누르면 접는다.
    if (current.expandedId == event.listingId) {
      emit(current.copyWith(clearExpanded: true, clearLoadingOptions: true));
      return;
    }

    // 캐시에 있으면 추가 요청 없이 바로 펼친다.
    if (current.optionsCache.containsKey(event.listingId)) {
      emit(current.copyWith(expandedId: event.listingId));
      return;
    }

    emit(current.copyWith(
      expandedId: event.listingId,
      loadingOptionsId: event.listingId,
    ));

    final result = await productListingUseCase.getOptions(event.listingId);

    // 토글이 진행되는 동안 상태가 바뀌었을 수 있으므로 최신 상태로 갱신.
    final latest = state;
    if (latest is! ProductListingListLoaded) return;

    result.fold(
      (failure) => emit(latest.copyWith(clearLoadingOptions: true)),
      (options) => emit(latest.copyWith(
        optionsCache: {
          ...latest.optionsCache,
          event.listingId: options,
        },
        clearLoadingOptions: true,
      )),
    );
  }
}
