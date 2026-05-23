import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/category/data/models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();

  Future<CategoryModel> createCategory({
    required String name,
    required String platform,
    required String platformCategoryId,
    int? parentId,
  });

  Future<CategoryModel> getCategory(int id);

  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required String platform,
    required String platformCategoryId,
    required int? parentId,
  });

  Future<void> deleteCategory(int id);
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
    int? parentId,
  }) async {
    try {
      final response = await dio.post(
        '/api/admin/category',
        data: {
          'name': name,
          'platform': platform,
          'platformCategoryId': platformCategoryId,
          if (parentId != null) 'parentId': parentId,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return CategoryModel.fromJson(data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to create category',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<CategoryModel> getCategory(int id) async {
    try {
      final response = await dio.get('/api/admin/category/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return CategoryModel.fromJson(data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch category',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required String platform,
    required String platformCategoryId,
    required int? parentId,
  }) async {
    try {
      final response = await dio.patch(
        '/api/admin/category/$id',
        data: {
          'name': name,
          'platform': platform,
          'platformCategoryId': platformCategoryId,
          if (parentId != null) 'parentId': parentId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return CategoryModel.fromJson(data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to update category',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    try {
      final response = await dio.delete('/api/admin/category/$id');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerException(
          response.data['message'] ?? 'Failed to delete category',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }
}
