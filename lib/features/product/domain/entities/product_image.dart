import 'package:equatable/equatable.dart';

/// One photo in a product's gallery (`/api/admin/products/{id}/images`).
///
/// The first photo (lowest [sortOrder]) is the representative one — the
/// server copies it into `Product.imageUrl`, which `ProductThumbnail` shows.
/// [imageUrl] is the stored value as-is: an S3 public URL on dev/prod.
class ProductImage extends Equatable {
  final int id;
  final int productId;
  final int sortOrder;
  final String imageUrl;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.sortOrder,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, productId, sortOrder, imageUrl];
}
