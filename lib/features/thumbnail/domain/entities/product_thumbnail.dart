import 'package:equatable/equatable.dart';

/// A per-product-per-seller thumbnail (consume-only on mobile — template editing
/// is web-only). Mirrors backend `ProductThumbnailResponse`.
class ProductThumbnail extends Equatable {
  final int id;
  final int productId;
  final int sellerId;
  final String sellerName;

  /// Template used to render; null for a MANUAL_OVERRIDE.
  final int? templateId;

  /// Public S3 URL on dev/prod (anonymous GET). Shown directly with
  /// `Image.network` — see field_value_panel / thumbnail_seller_card notes.
  final String imageUrl;

  /// `GENERATED` | `MANUAL_OVERRIDE` (String, not enum — badge branches on it).
  final String source;

  /// Render/override execution time (raw ISO string from backend). Also used as
  /// the image cache-buster after regeneration.
  final String generatedAt;

  const ProductThumbnail({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.sellerName,
    this.templateId,
    required this.imageUrl,
    required this.source,
    required this.generatedAt,
  });

  bool get isManualOverride => source == 'MANUAL_OVERRIDE';

  @override
  List<Object?> get props =>
      [id, productId, sellerId, sellerName, templateId, imageUrl, source, generatedAt];
}
