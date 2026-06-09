import '../../../product_listing/domain/entities/product_listing.dart';

class ProductListingModel extends ProductListing {
  ProductListingModel({
    required super.id,
    required super.platform,
    required super.platformProductId,
    required super.name,
    super.sellerId,
    super.sellerName,
    super.categoryName,
    super.carrierName,
    super.packageType,
    super.options,
  });

  factory ProductListingModel.fromJson(Map<String, dynamic> json) {
    return ProductListingModel(
      id: json['id'] as int,
      platform: json['platform'] as String,
      platformProductId: json['platformProductId'] as String,
      name: json['name'] as String,
      sellerId: json['sellerId'] as int?,
      sellerName: json['sellerName'] as String?,
      categoryName: json['categoryName'] as String?,
      carrierName: json['carrierName'] as String?,
      packageType: json['packageType'] as String?,
      options: json['options'] != null
          ? (json['options'] as List<dynamic>)
              .map((e) => ProductListingOptionModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'platformProductId': platformProductId,
      'name': name,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'categoryName': categoryName,
      'carrierName': carrierName,
      'packageType': packageType,
      'options': options?.map((e) => (e as ProductListingOptionModel).toJson()).toList(),
    };
  }
}

class ProductListingOptionModel extends ProductListingOption {
  ProductListingOptionModel({
    required super.id,
    required super.optionName,
    required super.sellingPrice,
    super.platformOptionId,
    super.margin,
    super.marginRate,
    super.products,
  });

  factory ProductListingOptionModel.fromJson(Map<String, dynamic> json) {
    return ProductListingOptionModel(
      id: json['id'] as int,
      optionName: json['optionName'] as String,
      // 백엔드가 sellingPrice/margin 을 double(예: 22880.0)로 내려줄 수 있어
      // num 으로 받아 toInt() 처리한다.
      sellingPrice: (json['sellingPrice'] as num).toInt(),
      platformOptionId: json['platformOptionId'] as String?,
      margin: (json['margin'] as num?)?.toInt(),
      marginRate: (json['marginRate'] as num?)?.toDouble(),
      products: json['products'] != null
          ? (json['products'] as List<dynamic>)
              .map((e) =>
                  ProductListingProductModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'optionName': optionName,
      'sellingPrice': sellingPrice,
      'platformOptionId': platformOptionId,
      'margin': margin,
      'marginRate': marginRate,
      'products': products
          ?.map((e) => (e as ProductListingProductModel).toJson())
          .toList(),
    };
  }
}

class ProductListingProductModel extends ProductListingProduct {
  ProductListingProductModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.quantity,
  });

  factory ProductListingProductModel.fromJson(Map<String, dynamic> json) {
    return ProductListingProductModel(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
    };
  }
}

class ProductListingPageModel {
  final List<ProductListingModel> content;
  final int totalPages;
  final int totalElements;

  ProductListingPageModel({
    required this.content,
    required this.totalPages,
    required this.totalElements,
  });

  factory ProductListingPageModel.fromJson(Map<String, dynamic> json) {
    return ProductListingPageModel(
      content: (json['content'] as List<dynamic>)
          .map((e) => ProductListingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.map((e) => e.toJson()).toList(),
      'totalPages': totalPages,
      'totalElements': totalElements,
    };
  }
}
