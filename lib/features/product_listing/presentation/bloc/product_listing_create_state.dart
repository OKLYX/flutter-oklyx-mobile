import 'package:equatable/equatable.dart';
import '../../domain/entities/product_listing.dart';

abstract class ProductListingCreateState extends Equatable {
  const ProductListingCreateState();
}

class ProductListingCreateLoaded extends ProductListingCreateState {
  final Map<String, String> formData;
  final Map<String, String?> validationErrors;

  const ProductListingCreateLoaded({
    required this.formData,
    this.validationErrors = const {},
  });

  @override
  List<Object?> get props => [formData, validationErrors];
}

class ProductListingCreateLoading extends ProductListingCreateState {
  const ProductListingCreateLoading();

  @override
  List<Object?> get props => [];
}

class ProductListingCreateSuccess extends ProductListingCreateState {
  final ProductListing productListing;

  const ProductListingCreateSuccess(this.productListing);

  @override
  List<Object?> get props => [productListing];
}

class ProductListingCreateError extends ProductListingCreateState {
  final String message;

  const ProductListingCreateError(this.message);

  @override
  List<Object?> get props => [message];
}
