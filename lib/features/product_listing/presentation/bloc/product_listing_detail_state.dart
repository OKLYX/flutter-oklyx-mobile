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
