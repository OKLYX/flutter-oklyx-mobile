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
      final dynamic dataField = response.data['data'];
      if (dataField is! List) {
        throw ServerException('Invalid API response format');
      }
      final List<dynamic> data = dataField;
      return data
          .map((json) => CommissionRateModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to fetch commission rates';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to fetch commission rates: ${e.runtimeType}');
    }
  }

  @override
  Future<CommissionRateModel> getCommissionRate(int id) async {
    try {
      final response = await _dio.get('/api/admin/commission-rate/$id');
      final dynamic dataField = response.data['data'];
      if (dataField is! Map) {
        throw ServerException('Invalid API response format');
      }
      return CommissionRateModel.fromJson(dataField as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to fetch commission rate';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to fetch commission rate: ${e.runtimeType}');
    }
  }

  @override
  Future<CommissionRateModel> createCommissionRate(Map<String, dynamic> params) async {
    try {
      final response = await _dio.post(
        '/api/admin/commission-rate',
        data: params,
      );
      final dynamic dataField = response.data['data'];
      if (dataField is! Map) {
        throw ServerException('Invalid API response format');
      }
      return CommissionRateModel.fromJson(dataField as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to create commission rate';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to create commission rate: ${e.runtimeType}');
    }
  }

  @override
  Future<CommissionRateModel> updateCommissionRate(int id, Map<String, dynamic> params) async {
    try {
      final response = await _dio.patch(
        '/api/admin/commission-rate/$id',
        data: params,
      );
      final dynamic dataField = response.data['data'];
      if (dataField is! Map) {
        throw ServerException('Invalid API response format');
      }
      return CommissionRateModel.fromJson(dataField as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to update commission rate';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to update commission rate: ${e.runtimeType}');
    }
  }

  @override
  Future<void> deleteCommissionRate(int id) async {
    try {
      final response = await _dio.delete('/api/admin/commission-rate/$id');
      if (response.statusCode == 200) {
        return;
      } else {
        throw ServerException('Failed to delete commission rate');
      }
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to delete commission rate';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to delete commission rate: ${e.runtimeType}');
    }
  }
}
