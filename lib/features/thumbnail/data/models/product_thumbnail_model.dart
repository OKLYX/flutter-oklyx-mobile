import '../../domain/entities/product_thumbnail.dart';

class ProductThumbnailModel extends ProductThumbnail {
  const ProductThumbnailModel({
    required super.id,
    required super.productId,
    required super.sellerId,
    required super.sellerName,
    super.templateId,
    required super.imageUrl,
    required super.source,
    required super.generatedAt,
  });

  factory ProductThumbnailModel.fromJson(Map<String, dynamic> json) {
    // `source` is a backend enum serialized as its name string.
    final source = json['source'];
    return ProductThumbnailModel(
      id: json['id'] as int,
      productId: json['productId'] as int,
      sellerId: json['sellerId'] as int,
      sellerName: json['sellerName'] as String? ?? '',
      templateId: json['templateId'] as int?,
      imageUrl: json['imageUrl'] as String? ?? '',
      source: source is String ? source : source?.toString() ?? 'GENERATED',
      generatedAt: json['generatedAt']?.toString() ?? '',
    );
  }
}
