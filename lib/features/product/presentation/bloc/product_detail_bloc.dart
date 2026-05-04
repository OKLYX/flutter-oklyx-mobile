import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductDetailUseCase getProductDetailUseCase;

  ProductDetailBloc({required this.getProductDetailUseCase})
      : super(const ProductDetailInitial()) {
    on<LoadProductDetail>(_onLoadProductDetail);
    on<RetryLoadProductDetail>(_onLoadProductDetail);
  }

  Future<void> _onLoadProductDetail(
    ProductDetailEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    final productId = event is LoadProductDetail
        ? event.productId
        : (event as RetryLoadProductDetail).productId;

    emit(const ProductDetailLoading());

    final result = await getProductDetailUseCase(
      GetProductDetailParams(productId),
    );

    result.fold(
      (failure) => emit(ProductDetailError(message: failure.message)),
      (product) => emit(ProductDetailLoaded(product: product)),
    );
  }
}
