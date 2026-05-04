import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;

  ProductBloc({required this.getProductsUseCase}) : super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<RefreshProducts>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    emit(const ProductLoading());

    final result = await getProductsUseCase(
      const GetProductsParams(page: 0, size: 20),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (productPage) => emit(ProductLoaded(
        products: productPage.content,
        hasMore: !productPage.last,
        currentPage: 0,
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
    ));

    final result = await getProductsUseCase(
      GetProductsParams(page: nextPage, size: 20),
    );

    result.fold(
      (failure) => emit(currentState),
      (productPage) => emit(ProductLoaded(
        products: [...currentState.products, ...productPage.content],
        hasMore: !productPage.last,
        currentPage: nextPage,
      )),
    );
  }

  Future<void> _onRefreshProducts(RefreshProducts event, Emitter<ProductState> emit) async {
    add(const LoadProducts());
  }
}
