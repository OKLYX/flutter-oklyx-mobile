import 'dart:io';

import '../models/product_thumbnail_model.dart';
import '../models/template_field_model.dart';

abstract class ThumbnailRemoteDataSource {
  Future<List<ProductThumbnailModel>> getByProduct(int productId);

  Future<ProductThumbnailModel> generate(
    int productId,
    int sellerId,
    Map<String, String> fieldValues,
  );

  Future<ProductThumbnailModel> overrideThumbnail(
      int productId, int sellerId, File file);

  Future<void> delete(int productId, int sellerId);

  Future<List<TemplateFieldModel>> getDefaultTemplateFields();
}
