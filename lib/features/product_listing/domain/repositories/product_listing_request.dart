/// 판매상품 옵션 수정 요청.
///
/// ⚠️ 구성품(`products`)은 더 이상 전송하지 않는다. 옵션의 구성품은 마스터 상품이
/// 소유하며(마스터 옵션 → 물품 → 수량), 판매상품 폼에서는 읽기 전용으로만 보여준다.
class CreateProductListingOptionRequest {
  final String optionName;
  final int sellingPrice;
  final String? platformOptionId;

  CreateProductListingOptionRequest({
    required this.optionName,
    required this.sellingPrice,
    this.platformOptionId,
  });
}

class UpdateProductListingRequest {
  final String platform;
  final String platformProductId;
  final String name;
  final String? categoryId;
  final String? carrierId;
  final String? packageId;
  final String? sellerId;
  final List<CreateProductListingOptionRequest>? options;

  UpdateProductListingRequest({
    required this.platform,
    required this.platformProductId,
    required this.name,
    this.categoryId,
    this.carrierId,
    this.packageId,
    this.sellerId,
    this.options,
  });
}
