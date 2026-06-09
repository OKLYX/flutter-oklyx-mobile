import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;

  /// 현재 적용 중인 검색어. 페이지네이션(LoadMore)과 새로고침이
  /// 동일한 검색 조건을 유지하도록 보관한다. 빈 문자열이면 전체 조회.
  String _searchQuery = '';

  ProductBloc({required this.getProductsUseCase}) : super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<RefreshProducts>(_onRefreshProducts);
    on<SearchProducts>(_onSearchProducts);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    emit(const ProductLoading());

    final result = await getProductsUseCase(
      GetProductsParams(page: 0, size: 20, search: _searchQuery.isEmpty ? null : _searchQuery),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (productPage) => emit(ProductLoaded(
        products: productPage.content,
        hasMore: !productPage.last,
        currentPage: 0,
        searchQuery: _searchQuery,
      )),
    );
  }

  Future<void> _onLoadMoreProducts(LoadMoreProducts event, Emitter<ProductState> emit) async {
    final currentState = state;
    if (currentState is! ProductLoaded) return;
    if (!currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;
    emit(ProductLoadingMore(
      products: currentState.products,
      currentPage: currentState.currentPage,
      searchQuery: _searchQuery,
    ));

    final result = await getProductsUseCase(
      GetProductsParams(page: nextPage, size: 20, search: _searchQuery.isEmpty ? null : _searchQuery),
    );

    result.fold(
      (failure) => emit(currentState),
      (productPage) => emit(ProductLoaded(
        products: [...currentState.products, ...productPage.content],
        hasMore: !productPage.last,
        currentPage: nextPage,
        searchQuery: _searchQuery,
      )),
    );
  }

  Future<void> _onRefreshProducts(RefreshProducts event, Emitter<ProductState> emit) async {
    add(const LoadProducts());
  }

  Future<void> _onSearchProducts(SearchProducts event, Emitter<ProductState> emit) async {
    _searchQuery = event.query.trim();
    add(const LoadProducts());
  }
}
