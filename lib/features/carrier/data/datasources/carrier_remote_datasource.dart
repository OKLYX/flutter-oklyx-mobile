import 'package:dio/dio.dart';
import '../models/carrier_model.dart';
import '../models/platform_carrier_code_model.dart';

abstract class CarrierRemoteDataSource {
  Future<List<CarrierModel>> getCarriers();
  Future<CarrierModel> createCarrier(String name, bool isActive);
  Future<CarrierModel> updateCarrier(int id, String name, bool isActive);
  Future<void> deleteCarrier(int id);

  Future<List<PlatformCarrierCodeModel>> getPlatformCodes(int carrierId);
  Future<PlatformCarrierCodeModel> createPlatformCode(
    int carrierId,
    String platform,
    String code,
  );
  Future<PlatformCarrierCodeModel> updatePlatformCode(
    int carrierId,
    int codeId,
    String platform,
    String code,
  );
  Future<void> deletePlatformCode(int carrierId, int codeId);
}

class CarrierRemoteDataSourceImpl implements CarrierRemoteDataSource {
  final Dio dio;

  CarrierRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CarrierModel>> getCarriers() async {
    final response = await dio.get('/api/admin/carriers');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => CarrierModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CarrierModel> createCarrier(String name, bool isActive) async {
    final response = await dio.post(
      '/api/admin/carriers',
      data: {'name': name, 'isActive': isActive},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return CarrierModel.fromJson(data);
  }

  @override
  Future<CarrierModel> updateCarrier(int id, String name, bool isActive) async {
    final response = await dio.patch(
      '/api/admin/carriers/$id',
      data: {'name': name, 'isActive': isActive},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return CarrierModel.fromJson(data);
  }

  @override
  Future<void> deleteCarrier(int id) async {
    final response = await dio.delete('/api/admin/carriers/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete carrier');
    }
  }

  @override
  Future<List<PlatformCarrierCodeModel>> getPlatformCodes(int carrierId) async {
    final response = await dio.get('/api/admin/carriers/$carrierId/platform-codes');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((json) =>
            PlatformCarrierCodeModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PlatformCarrierCodeModel> createPlatformCode(
    int carrierId,
    String platform,
    String code,
  ) async {
    final response = await dio.post(
      '/api/admin/carriers/$carrierId/platform-codes',
      data: {'platform': platform, 'deliveryCompanyCode': code},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PlatformCarrierCodeModel.fromJson(data);
  }

  @override
  Future<PlatformCarrierCodeModel> updatePlatformCode(
    int carrierId,
    int codeId,
    String platform,
    String code,
  ) async {
    final response = await dio.patch(
      '/api/admin/carriers/$carrierId/platform-codes/$codeId',
      data: {'platform': platform, 'deliveryCompanyCode': code},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PlatformCarrierCodeModel.fromJson(data);
  }

  @override
  Future<void> deletePlatformCode(int carrierId, int codeId) async {
    final response =
        await dio.delete('/api/admin/carriers/$carrierId/platform-codes/$codeId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete platform code');
    }
  }
}
