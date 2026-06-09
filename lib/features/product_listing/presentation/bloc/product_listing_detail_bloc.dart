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
    on<DeleteProductListing>(_onDelete);
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

  Future<void> _onDelete(
    DeleteProductListing event,
    Emitter<ProductListingDetailState> emit,
  ) async {
    // 현재 로드된 데이터를 보존해 삭제 중/실패 시 페이지가 비지 않게 한다.
    // 삭제 실패 후 재시도도 가능하도록 Loaded/DeleteFailure 두 상태 모두 허용한다.
    final current = state;
    final ProductListing listing;
    final List<ProductListingOption> options;
    if (current is ProductListingDetailLoaded) {
      listing = current.listing;
      options = current.options;
    } else if (current is ProductListingDetailDeleteFailure) {
      listing = current.listing;
      options = current.options;
    } else {
      return;
    }

    emit(ProductListingDetailDeleting(listing: listing, options: options));

    final result = await productListingUseCase.delete(event.id);

    result.fold(
      (failure) => emit(ProductListingDetailDeleteFailure(
        listing: listing,
        options: options,
        message: failure.message,
      )),
      (_) => emit(ProductListingDetailDeleteSuccess()),
    );
  }
}
