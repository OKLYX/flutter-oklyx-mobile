class ProductListing {
  final int id;
  final String platform;
  final String platformProductId;
  final String name;
  final String? categoryName;
  final String? carrierName;
  final String? packageType;
  final String? sellerName;
  final List<ProductListingOption>? options;

  ProductListing({
    required this.id,
    required this.platform,
    required this.platformProductId,
    required this.name,
    this.categoryName,
    this.carrierName,
    this.packageType,
    this.sellerName,
    this.options,
  });
}

class ProductListingOption {
  final int id;
  final String optionName;
  final int sellingPrice;
  final int? margin;
  final double? marginRate;

  ProductListingOption({
    required this.id,
    required this.optionName,
    required this.sellingPrice,
    this.margin,
    this.marginRate,
  });
}
