import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/product/data/models/product_model.dart';
import 'package:flutter_oklyn_mobile/features/product/data/models/product_page_model.dart';
import 'package:flutter_oklyn_mobile/features/product/data/datasources/product_remote_datasource.dart';

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient dioClient;

  ProductRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ProductPageModel> getProducts({
    required int page,
    required int size,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'size': size,
        if (search != null) 'search': search,
      };

      final response = await dioClient.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to fetch products',
          statusCode: response.statusCode,
        );
      }

      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return ProductPageModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch products',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    try {
      final response = await dioClient.get('/products/$id');

      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to fetch product',
          statusCode: response.statusCode,
        );
      }

      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch product',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
