class CreateProductListingRequest {
  final String platform;
  final String platformProductId;
  final String name;
  final String? categoryId;
  final String? carrierId;
  final String? packageId;
  final String? sellerId;

  CreateProductListingRequest({
    required this.platform,
    required this.platformProductId,
    required this.name,
    this.categoryId,
    this.carrierId,
    this.packageId,
    this.sellerId,
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

  UpdateProductListingRequest({
    required this.platform,
    required this.platformProductId,
    required this.name,
    this.categoryId,
    this.carrierId,
    this.packageId,
    this.sellerId,
  });
}
