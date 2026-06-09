import 'package:equatable/equatable.dart';
import '../../domain/entities/product_listing.dart';
import '../../../product/domain/entities/product.dart';

abstract class ProductListingCreateState extends Equatable {
  const ProductListingCreateState();
}

class ProductListingCreateLoaded extends ProductListingCreateState {
  final Map<String, String> formData;
  final Map<String, String?> validationErrors;
  final List<dynamic> sellers;
  final List<dynamic> categories;
  final List<dynamic> carrierRates;
  final List<dynamic> packages;
  final List<dynamic> commissionRates;
  final List<Product> selectedProducts;
  final List<OptionWithProducts> optionsData;
  final List<Product> searchedProducts;
  final double commissionRate;

  const ProductListingCreateLoaded({
    required this.formData,
    this.validationErrors = const {},
    this.sellers = const [],
    this.categories = const [],
    this.carrierRates = const [],
    this.packages = const [],
    this.commissionRates = const [],
    this.selectedProducts = const [],
    this.optionsData = const [],
    this.searchedProducts = const [],
    this.commissionRate = 0.05,
  });

  @override
  List<Object?> get props => [
    formData,
    validationErrors,
    sellers,
    categories,
    carrierRates,
    packages,
    commissionRates,
    selectedProducts,
    optionsData,
    searchedProducts,
    commissionRate,
  ];
}

class OptionWithProducts {
  final ProductListingOption option;
  final List<ProductQuantity> products;
  final String? platformOptionId;

  OptionWithProducts({
    required this.option,
    required this.products,
    this.platformOptionId,
  });
}

class ProductQuantity {
  final int productId;
  final int quantity;

  ProductQuantity({
    required this.productId,
    required this.quantity,
  });
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
