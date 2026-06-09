import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_listing.dart';
import '../../domain/usecases/product_listing_usecase.dart';
import 'product_listing_detail_event.dart';
import 'product_listing_detail_state.dart';

/// 판매상품 상세 BLoC
///
/// 상세 정보(getById)와 옵션 목록(getOptions)을 함께 로드한다.
/// 옵션 조회가 실패해도 상세 정보는 보여주기 위해 옵션은 빈 목록으로 처리한다.
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

    await listingResult.fold(
      (failure) async =>
          emit(ProductListingDetailError(message: failure.message)),
      (listing) async {
        final optionsResult =
            await productListingUseCase.getOptions(event.id);
        final options = optionsResult.fold(
          (failure) => <ProductListingOption>[],
          (options) => options,
        );
        emit(ProductListingDetailLoaded(listing: listing, options: options));
      },
    );
  }
}
