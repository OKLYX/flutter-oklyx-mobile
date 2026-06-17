import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/repositories/marketplace_account_repository.dart';
import '../models/marketplace_account_model.dart';

abstract class MarketplaceAccountRemoteDataSource {
  Future<List<MarketplaceAccountModel>> getBySeller(int sellerId);

  Future<MarketplaceAccountModel> create(CreateMarketplaceAccountParams params);

  Future<MarketplaceAccountModel> update(int id, UpdateMarketplaceAccountParams params);

  Future<void> delete(int id);
}

class MarketplaceAccountRemoteDataSourceImpl implements MarketplaceAccountRemoteDataSource {
  final Dio dio;

  MarketplaceAccountRemoteDataSourceImpl({required this.dio});

  static const String _path = '/api/admin/marketplace-account';

  @override
  Future<List<MarketplaceAccountModel>> getBySeller(int sellerId) async {
    final response = await dio.get(_path, queryParameters: {'sellerId': sellerId});
    final data = response.data['data'] as List;
    return data
        .map((json) => MarketplaceAccountModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MarketplaceAccountModel> create(CreateMarketplaceAccountParams params) async {
    final response = await dio.post(_path, data: {
      'sellerId': params.sellerId,
      'platform': params.platform,
      'accountAlias': params.accountAlias,
      'vendorId': params.vendorId,
      'accessKey': params.accessKey,
      'secretKey': params.secretKey,
    });
    return MarketplaceAccountModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<MarketplaceAccountModel> update(int id, UpdateMarketplaceAccountParams params) async {
    // Blank/null secretKey is omitted → backend keeps the existing key.
    final response = await dio.patch('$_path/$id', data: {
      'sellerId': params.sellerId,
      'platform': params.platform,
      'accountAlias': params.accountAlias,
      'vendorId': params.vendorId,
      'accessKey': params.accessKey,
      if (params.secretKey != null && params.secretKey!.isNotEmpty)
        'secretKey': params.secretKey,
    });
    return MarketplaceAccountModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    await dio.delete('$_path/$id');
  }
}
