import 'package:dio/dio.dart';
import '../models/carrier_rate_model.dart';
import '../models/create_carrier_rate_params.dart';
import '../models/update_carrier_rate_params.dart';

abstract class CarrierRateRemoteDataSource {
  Future<List<CarrierRateModel>> getCarrierRates();
  Future<CarrierRateModel> getCarrierRate(int id);
  Future<CarrierRateModel> createCarrierRate(CreateCarrierRateParams params);
  Future<CarrierRateModel> updateCarrierRate(int id, UpdateCarrierRateParams params);
}

class CarrierRateRemoteDataSourceImpl implements CarrierRateRemoteDataSource {
  final Dio dio;

  CarrierRateRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CarrierRateModel>> getCarrierRates() async {
    final response = await dio.get('/api/admin/carrier-rate');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => CarrierRateModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CarrierRateModel> getCarrierRate(int id) async {
    final response = await dio.get('/api/admin/carrier-rate/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return CarrierRateModel.fromJson(data);
  }

  @override
  Future<CarrierRateModel> createCarrierRate(CreateCarrierRateParams params) async {
    final response = await dio.post(
      '/api/admin/carrier-rate',
      data: params.toJson(),
    );
    final Map<String, dynamic> data = response.data['data'] as Map<String, dynamic>;
    return CarrierRateModel.fromJson(data);
  }

  @override
  Future<CarrierRateModel> updateCarrierRate(int id, UpdateCarrierRateParams params) async {
    final response = await dio.patch(
      '/api/admin/carrier-rate/$id',
      data: params.toJson(),
    );
    final Map<String, dynamic> data = response.data['data'] as Map<String, dynamic>;
    return CarrierRateModel.fromJson(data);
  }
}
