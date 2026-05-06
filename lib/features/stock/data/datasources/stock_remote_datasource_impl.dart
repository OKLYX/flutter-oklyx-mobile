import 'package:dio/dio.dart';

import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/datasources/stock_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/exceptions/stock_exceptions.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';

class StockRemoteDatasourceImpl implements StockRemoteDatasource {
  final DioClient dioClient;

  StockRemoteDatasourceImpl(this.dioClient);

  @override
  Future<GetStockResponse> getCurrentStock(String barcodeId) async {
    try {
      final response = await dioClient.get('/api/stock/$barcodeId');

      // Handle 404 as no stock history
      if (response.statusCode == 404) {
        return GetStockResponse(barcodeId: barcodeId, inStock: 0);
      }

      // Check if response has data
      if (response.data == null) {
        throw ServerException('Empty response from server');
      }

      final data = response.data as Map<String, dynamic>;
      if (!data.containsKey('data')) {
        throw ServerException('Invalid response format');
      }

      return GetStockResponse.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return GetStockResponse(barcodeId: barcodeId, inStock: 0);
      }
      throw ServerException('API error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to fetch stock: ${e.toString()}');
    }
  }

  @override
  Future<CreateStockResponse> createStock(CreateStockRequest data) async {
    try {
      final response = await dioClient.post(
        '/api/stock',
        data: data.toJson(),
      );

      // Handle 409 as insufficient stock
      if (response.statusCode == 409) {
        throw StockInsufficientException();
      }

      // Check if response has data
      if (response.data == null) {
        throw ServerException('Empty response from server');
      }

      final responseData = response.data as Map<String, dynamic>;
      if (!responseData.containsKey('data')) {
        throw ServerException('Invalid response format');
      }

      return CreateStockResponse.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw StockInsufficientException();
      }
      throw ServerException('API error: ${e.message}');
    } on StockInsufficientException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create stock: ${e.toString()}');
    }
  }
}
