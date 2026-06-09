class CreateProductListingRequest {
  final String platform;
  final String platformProductId;
  final String name;
  final String? categoryId;
  final String? carrierId;
  final String? packageId;
  final String? sellerId;
  final List<CreateProductListingOptionRequest>? options;

  CreateProductListingRequest({
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

class CreateProductListingOptionRequest {
  final String optionName;
  final int sellingPrice;
  final String? platformOptionId;
  final List<CreateProductListingProductRequest>? products;

  CreateProductListingOptionRequest({
    required this.optionName,
    required this.sellingPrice,
    this.platformOptionId,
    this.products,
  });
}

class CreateProductListingProductRequest {
  final int productId;
  final int quantity;

  CreateProductListingProductRequest({
    required this.productId,
    required this.quantity,
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
