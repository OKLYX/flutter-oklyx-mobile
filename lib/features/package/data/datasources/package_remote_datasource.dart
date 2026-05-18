import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/package/data/models/package_model.dart';

abstract class PackageRemoteDataSource {
  Future<List<PackageModel>> getPackages();
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
}
