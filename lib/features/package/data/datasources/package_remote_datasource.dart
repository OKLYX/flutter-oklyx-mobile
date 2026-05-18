import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/models/create_package_params.dart';
import 'package:flutter_oklyn_mobile/features/package/data/models/package_model.dart';

abstract class PackageRemoteDataSource {
  Future<List<PackageModel>> getPackages();
  Future<PackageModel> createPackage(CreatePackageParams params);
  Future<PackageModel> updatePackage({
    required int id,
    required String type,
    required double cost,
    required String effectiveDate,
    required bool isDefault,
  });
}

class PackageRemoteDataSourceImpl implements PackageRemoteDataSource {
  final Dio dio;

  PackageRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<PackageModel>> getPackages() async {
    try {
      final response = await dio.get('/api/admin/package');
      final dynamic dataField = response.data['data'];
      if (dataField is! List) {
        throw ServerException('Invalid API response format');
      }
      final List<dynamic> data = dataField;
      return data.map((json) => PackageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to fetch packages';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to fetch packages: ${e.runtimeType}');
    }
  }

  @override
  Future<PackageModel> createPackage(CreatePackageParams params) async {
    try {
      final response = await dio.post(
        '/api/admin/package',
        data: params.toJson(),
      );
      final dynamic dataField = response.data['data'];
      if (dataField is! Map) {
        throw ServerException('Invalid API response format');
      }
      return PackageModel.fromJson(dataField as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to create package';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to create package: ${e.runtimeType}');
    }
  }

  @override
  Future<PackageModel> updatePackage({
    required int id,
    required String type,
    required double cost,
    required String effectiveDate,
    required bool isDefault,
  }) async {
    try {
      final response = await dio.patch(
        '/api/admin/package/$id',
        data: {
          'type': type,
          'cost': cost,
          'effectiveDate': effectiveDate,
          'isDefault': isDefault,
        },
      );
      final dynamic dataField = response.data['data'];
      if (dataField is! Map) {
        throw ServerException('Invalid API response format');
      }
      return PackageModel.fromJson(dataField as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.message ?? 'Failed to update package';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Failed to update package: ${e.runtimeType}');
    }
  }
}
