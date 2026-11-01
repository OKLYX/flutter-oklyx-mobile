import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_image.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

/// Product photo gallery — thin delegate, same calls as the web
/// `ProductImageUseCase` (`/api/admin/products/{productId}/images`).
///
/// Every write returns (or is followed by) the full gallery in order; the
/// first photo is the representative one.
class ProductImageUseCase {
  final ProductRepository repository;

  ProductImageUseCase(this.repository);

  Future<Either<Failure, List<ProductImage>>> list(int productId) =>
      repository.listProductImages(productId);

  /// Appends [files] in one request (the server takes them all at once).
  Future<Either<Failure, List<ProductImage>>> add(
    int productId,
    List<File> files,
  ) =>
      repository.addProductImages(productId, files);

  /// Replaces one photo in place (same image id, same position).
  Future<Either<Failure, void>> replace(
    int productId,
    int imageId,
    File file,
  ) =>
      repository.replaceProductImage(productId, imageId, file);

  /// [imageIds] must be the whole gallery in the new order.
  Future<Either<Failure, List<ProductImage>>> reorder(
    int productId,
    List<int> imageIds,
  ) =>
      repository.reorderProductImages(productId, imageIds);

  /// 409 = the photo is placed in a master image pool (server message).
  Future<Either<Failure, void>> remove(int productId, int imageId) =>
      repository.removeProductImage(productId, imageId);
}
