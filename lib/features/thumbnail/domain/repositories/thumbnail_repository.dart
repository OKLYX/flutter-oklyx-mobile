import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product_thumbnail.dart';
import '../entities/template_field.dart';

abstract class ThumbnailRepository {
  /// GET /api/admin/products/{productId}/thumbnails
  Future<Either<Failure, List<ProductThumbnail>>> getByProduct(int productId);

  /// POST /api/admin/products/{productId}/thumbnails/generate?sellerId=
  /// Body `{ "fieldValues": {key: value} }` (non-blank values only).
  Future<Either<Failure, ProductThumbnail>> generate(
    int productId,
    int sellerId,
    Map<String, String> fieldValues,
  );

  /// POST /api/admin/products/{productId}/thumbnails/{sellerId}/override (multipart `file`)
  Future<Either<Failure, ProductThumbnail>> overrideThumbnail(
    int productId,
    int sellerId,
    File file,
  );

  /// DELETE /api/admin/products/{productId}/thumbnails/{sellerId}
  Future<Either<Failure, void>> delete(int productId, int sellerId);

  /// GET /api/admin/thumbnail-templates → fields of the `isDefault==true` template.
  Future<Either<Failure, List<TemplateField>>> getDefaultTemplateFields();
}
