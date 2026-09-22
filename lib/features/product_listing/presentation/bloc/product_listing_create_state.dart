import 'package:equatable/equatable.dart';
import '../../domain/entities/product_listing.dart';

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
  final List<OptionWithProducts> optionsData;
  final double commissionRate;

  const ProductListingCreateLoaded({
    required this.formData,
    this.validationErrors = const {},
    this.sellers = const [],
    this.categories = const [],
    this.carrierRates = const [],
    this.packages = const [],
    this.commissionRates = const [],
    this.optionsData = const [],
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
    optionsData,
    commissionRate,
  ];
}

/// 옵션 + 그 옵션의 구성품.
///
/// ⚠️ [products]는 **읽기 전용**이다. 구성품은 마스터 상품(마스터 옵션 → 물품 → 수량)이
/// 소유하며 서버 응답으로만 채워진다. 이 폼에서는 편집하지 않고 전송하지도 않는다.
/// 마스터에 연결되지 않은 옵션은 구성품을 알 수 없으므로 빈 목록이 된다.
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

/// 읽기 전용 구성품 한 줄 (물품명 × 수량).
class ProductQuantity {
  final int productId;
  final String productName;
  final int quantity;

  ProductQuantity({
    required this.productId,
    required this.productName,
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
