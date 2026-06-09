class ProductListing {
  final int id;
  final String platform;
  final String platformProductId;
  final String name;
  final int? sellerId;
  final String? sellerName;
  final String? categoryName;
  final String? carrierName;
  final String? packageType;
  // 수정 화면 프리필용 ID들 (프론트 ProductListingEntity의 categoryId/deliveryId/packageId와 동일).
  // 상세/목록 표시에는 *Name 필드를 쓰지만, 수정 폼은 드롭다운 선택값 복원을 위해 ID가 필요하다.
  // ⚠️ 백엔드는 택배비 ID를 `deliveryId`로 내려준다 (carrierId 아님).
  final int? categoryId;
  final int? deliveryId;
  final int? packageId;
  final List<ProductListingOption>? options;

  ProductListing({
    required this.id,
    required this.platform,
    required this.platformProductId,
    required this.name,
    this.sellerId,
    this.sellerName,
    this.categoryName,
    this.carrierName,
    this.packageType,
    this.categoryId,
    this.deliveryId,
    this.packageId,
    this.options,
  });
}

class ProductListingOption {
  final int id;
  final String optionName;
  final int sellingPrice;
  final String? platformOptionId;
  final int? margin;
  final double? marginRate;
  final List<ProductListingProduct>? products;

  ProductListingOption({
    required this.id,
    required this.optionName,
    required this.sellingPrice,
    this.platformOptionId,
    this.margin,
    this.marginRate,
    this.products,
  });
}

/// 옵션을 구성하는 상품(구성상품)
///
/// 프론트 ProductListingProduct 엔티티와 동일.
class ProductListingProduct {
  final int id;
  final int productId;
  final String productName;
  final int quantity;

  ProductListingProduct({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}
