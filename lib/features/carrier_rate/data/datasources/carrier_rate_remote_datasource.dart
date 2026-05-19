import 'package:dio/dio.dart';
import '../models/carrier_rate_model.dart';

abstract class CarrierRateRemoteDataSource {
  Future<List<CarrierRateModel>> getCarrierRates();
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
}
