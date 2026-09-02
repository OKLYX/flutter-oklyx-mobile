import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import '../../models/product_thumbnail_model.dart';
import '../../models/template_field_model.dart';
import '../thumbnail_remote_datasource.dart';

/// Dio datasource for per-product-per-seller thumbnails.
///
/// Response unwrapping follows `product_remote_datasource_impl.dart` (SSOT):
/// success payloads live under `response.data['data']`.
class ThumbnailRemoteDataSourceImpl implements ThumbnailRemoteDataSource {
  final DioClient dioClient;

  ThumbnailRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ProductThumbnailModel>> getByProduct(int productId) async {
    try {
      final response =
          await dioClient.get('/api/admin/products/$productId/thumbnails');

      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to fetch thumbnails',
          statusCode: response.statusCode,
        );
      }

      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .map((json) =>
              ProductThumbnailModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch thumbnails',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductThumbnailModel> generate(
    int productId,
    int sellerId,
    Map<String, String> fieldValues,
  ) async {
    try {
      final response = await dioClient.post(
        '/api/admin/products/$productId/thumbnails/generate',
        queryParameters: {'sellerId': sellerId},
        data: {'fieldValues': fieldValues},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Failed to generate thumbnail',
          statusCode: response.statusCode,
        );
      }

      final data =
          (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return ProductThumbnailModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to generate thumbnail',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductThumbnailModel> overrideThumbnail(
    int productId,
    int sellerId,
    File file,
  ) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await dioClient.post(
        '/api/admin/products/$productId/thumbnails/$sellerId/override',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Failed to override thumbnail',
          statusCode: response.statusCode,
        );
      }

      final data =
          (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return ProductThumbnailModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to override thumbnail',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> delete(int productId, int sellerId) async {
    try {
      final response = await dioClient
          .delete('/api/admin/products/$productId/thumbnails/$sellerId');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerException(
          'Failed to delete thumbnail',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete thumbnail',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<TemplateFieldModel>> getDefaultTemplateFields() async {
    try {
      // No dedicated getDefault endpoint (same as web): list templates and pick
      // the one with isDefault==true, then return its fields.
      final response = await dioClient.get('/api/admin/thumbnail-templates');

      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to fetch templates',
          statusCode: response.statusCode,
        );
      }

      final data = (response.data as Map<String, dynamic>)['data'] as List;
      final templates = data.cast<Map<String, dynamic>>();
      final defaultTemplate = templates.firstWhere(
        (t) => t['isDefault'] == true,
        orElse: () => const <String, dynamic>{},
      );

      final fields = defaultTemplate['fields'] as List?;
      if (fields == null) return [];
      return fields
          .map((json) =>
              TemplateFieldModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch templates',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
