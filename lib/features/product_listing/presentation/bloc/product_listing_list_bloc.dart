import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/product_listing_usecase.dart';
import 'product_listing_list_event.dart';
import 'product_listing_list_state.dart';

/// 판매상품 조회(목록) BLoC
///
/// 프론트 "판매상품 조회" 기능과 동일하게 동작한다:
/// - 플랫폼 선택 후 검색 ([SearchProductListings])
/// - 무한 스크롤 페이지네이션 ([LoadMoreProductListings])
/// - 행 펼침/접힘 토글 ([ToggleListingOptions]) — 옵션은 목록 응답에 포함되어 옴
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

  void _onToggleOptions(
    ToggleListingOptions event,
    Emitter<ProductListingListState> emit,
  ) {
    final current = state;
    if (current is! ProductListingListLoaded) return;

    // 옵션(판매가/마진/마진율)은 목록 조회 응답에 이미 포함되어 온다(프론트와 동일).
    // 별도 요청 없이 펼침 상태만 토글한다.
    if (current.expandedId == event.listingId) {
      emit(current.copyWith(clearExpanded: true));
    } else {
      emit(current.copyWith(expandedId: event.listingId));
    }
  }
}
