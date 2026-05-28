import 'package:dio/dio.dart';

import '../../../../../core/error/exceptions.dart';
import '../commission_rate_remote_datasource.dart';
import '../../models/commission_rate_model.dart';

class CommissionRateRemoteDataSourceImpl implements CommissionRateRemoteDataSource {
  final Dio _dio;

  CommissionRateRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CommissionRateModel>> getCommissionRates() async {
    try {
      final response = await _dio.get('/api/admin/commission-rate');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CommissionRateModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ServerException('Failed to fetch commission rates');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<CommissionRateModel> getCommissionRate(int id) async {
    try {
      final response = await _dio.get('/api/admin/commission-rate/$id');
      if (response.statusCode == 200) {
        return CommissionRateModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Failed to fetch commission rate');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<CommissionRateModel> createCommissionRate(Map<String, dynamic> params) async {
    try {
      final response = await _dio.post(
        '/api/admin/commission-rate',
        data: params,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CommissionRateModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Failed to create commission rate');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to create');
    }
  }

  @override
  Future<CommissionRateModel> updateCommissionRate(int id, Map<String, dynamic> params) async {
    try {
      final response = await _dio.patch(
        '/api/admin/commission-rate/$id',
        data: params,
      );
      if (response.statusCode == 200) {
        return CommissionRateModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Failed to update commission rate');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to update');
    }
  }

  @override
  Future<void> deleteCommissionRate(int id) async {
    try {
      final response = await _dio.delete('/api/admin/commission-rate/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to delete commission rate');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete');
    }
  }
}
