import '../../domain/entities/product_listing.dart';

abstract class ProductListingDetailState {}

class ProductListingDetailInitial extends ProductListingDetailState {}

class ProductListingDetailLoading extends ProductListingDetailState {}

class ProductListingDetailLoaded extends ProductListingDetailState {
  final ProductListing listing;
  final List<ProductListingOption> options;

  ProductListingDetailLoaded({
    required this.listing,
    required this.options,
  });
}

class ProductListingDetailError extends ProductListingDetailState {
  final String message;

  ProductListingDetailError({required this.message});
}

/// 삭제 진행 중. 다이얼로그 뒤 페이지가 깨지지 않도록 기존 데이터를 함께 보관한다.
class ProductListingDetailDeleting extends ProductListingDetailState {
  final ProductListing listing;
  final List<ProductListingOption> options;

  ProductListingDetailDeleting({required this.listing, required this.options});
}

/// 삭제 성공. 리스너가 목록 화면으로 이동시킨다.
class ProductListingDetailDeleteSuccess extends ProductListingDetailState {}

/// 삭제 실패. 다이얼로그에 에러를 표시하고 페이지 내용은 유지한다.
class ProductListingDetailDeleteFailure extends ProductListingDetailState {
  final ProductListing listing;
  final List<ProductListingOption> options;
  final String message;

  ProductListingDetailDeleteFailure({
    required this.listing,
    required this.options,
    required this.message,
  });
}
