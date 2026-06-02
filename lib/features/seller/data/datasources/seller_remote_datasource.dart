import 'package:dio/dio.dart';
import '../models/seller_model.dart';

abstract class SellerRemoteDataSource {
  Future<List<SellerModel>> getSellers();

  Future<SellerModel> getSellerById(int id);
}

class SellerRemoteDataSourceImpl implements SellerRemoteDataSource {
  final Dio dio;

  SellerRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<SellerModel>> getSellers() async {
    try {
      final response = await dio.get('/api/admin/seller');
      final data = response.data['data'] as List;
      return data.map((json) => SellerModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SellerModel> getSellerById(int id) async {
    try {
      final response = await dio.get('/api/admin/seller/$id');
      return SellerModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
