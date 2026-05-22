import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/category/data/models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();

  Future<CategoryModel> createCategory({
    required String name,
    required String platform,
    required String platformCategoryId,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final Dio dio;

  CategoryRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await dio.get('/api/admin/category');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required String platform,
    required String platformCategoryId,
  }) async {
    try {
      final response = await dio.post(
        '/api/admin/category',
        data: {
          'name': name,
          'platform': platform,
          'platformCategoryId': platformCategoryId,
        },
      );
      final dynamic dataField = response.data['data'];
      if (dataField is! Map) {
        throw ServerException('Invalid API response format');
      }
      return CategoryModel.fromJson(dataField as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to create category');
    } catch (e) {
      throw ServerException('Failed to create category: ${e.runtimeType}');
    }
  }
}
