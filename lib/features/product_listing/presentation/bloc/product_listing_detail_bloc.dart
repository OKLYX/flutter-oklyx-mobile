import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_listing.dart';
import '../../domain/usecases/product_listing_usecase.dart';
import 'product_listing_detail_event.dart';
import 'product_listing_detail_state.dart';

/// 판매상품 상세 BLoC
///
/// 상세 정보(getById)를 로드한다. 옵션(판매가/마진/마진율)은 상세 응답의
/// listing.options 에 포함되어 오므로(프론트와 동일) 별도 요청하지 않는다.
class ProductListingDetailBloc
    extends Bloc<ProductListingDetailEvent, ProductListingDetailState> {
  final ProductListingUseCase productListingUseCase;

  ProductListingDetailBloc({required this.productListingUseCase})
      : super(ProductListingDetailInitial()) {
    on<LoadProductListingDetail>(_onLoad);
  }

  Future<void> _onLoad(
    LoadProductListingDetail event,
    Emitter<ProductListingDetailState> emit,
  ) async {
    emit(ProductListingDetailLoading());

    final listingResult = await productListingUseCase.getById(event.id);

    listingResult.fold(
      (failure) => emit(ProductListingDetailError(message: failure.message)),
      (listing) => emit(ProductListingDetailLoaded(
        listing: listing,
        options: listing.options ?? <ProductListingOption>[],
      )),
    );
  }
}
