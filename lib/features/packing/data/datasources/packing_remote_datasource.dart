import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import '../../domain/entities/packing.dart';
import '../models/packing_models.dart';

/// `/api/admin/packing/...` (FEATURE_2611_03 / PLAN D13 · D27 · D34) — the
/// same calls as the web `PackingRepositoryImpl`. All are ADMIN only.
///
/// `DioClient` lets every status below 500 through — [_ensureOk] turns a
/// non-2xx status into a [ServerException] with the envelope `message`
/// (a 400 reason such as 「이미 출고된 박스입니다」 reaches the screen as it is).
class PackingRemoteDataSource {
  final Dio dio;

  PackingRemoteDataSource({required this.dio});

  Future<PackingScanModel> scan(String invoiceNumber) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/packing/scan',
      queryParameters: <String, dynamic>{'invoiceNumber': invoiceNumber},
    ));
    return PackingScanModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<PendingParcelModel>> pending() async {
    final response =
        _ensureOk(await dio.get<dynamic>('/api/admin/packing/pending'));
    return ((response.data['data'] as List<dynamic>?) ?? const [])
        .map((e) => PendingParcelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BarcodeLookupModel> lookupBarcode(String value, int parcelId) async {
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/packing/barcode',
      queryParameters: <String, dynamic>{'value': value, 'parcelId': parcelId},
    ));
    return BarcodeLookupModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<BoxCandidateModel>> boxCandidates(
    List<BoxCandidateItem> items,
  ) async {
    final response = _ensureOk(await dio.post<dynamic>(
      '/api/admin/packing/box-candidates',
      data: <String, dynamic>{
        'items': [
          for (final item in items)
            {'productId': item.productId, 'quantity': item.quantity},
        ],
      },
    ));
    return ((response.data['data'] as List<dynamic>?) ?? const [])
        .map((e) => BoxCandidateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PackingCompleteResultModel> complete(
    int parcelId,
    int boxPackageId,
    List<PackedItem> items,
  ) async {
    final response = _ensureOk(await dio.post<dynamic>(
      '/api/admin/packing/parcels/$parcelId/complete',
      data: <String, dynamic>{
        'boxPackageId': boxPackageId,
        'items': [
          for (final item in items)
            {
              'orderLineId': item.orderLineId,
              'productId': item.productId,
              'quantity': item.quantity,
            },
        ],
      },
    ));
    return PackingCompleteResultModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<PackingCloseResultModel> markUnused(int parcelId) async {
    final response = _ensureOk(
      await dio.post<dynamic>('/api/admin/packing/parcels/$parcelId/unused'),
    );
    return PackingCloseResultModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<PackingCloseResultModel> restore(int parcelId) async {
    final response = _ensureOk(
      await dio.post<dynamic>('/api/admin/packing/parcels/$parcelId/restore'),
    );
    return PackingCloseResultModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// [from] · [to] = `yyyy-MM-dd`, both inclusive. A blank [keyword] is not
  /// sent (D34).
  Future<List<PackingHistoryEntryModel>> history(
    String from,
    String to,
    String keyword,
  ) async {
    final trimmed = keyword.trim();
    final response = _ensureOk(await dio.get<dynamic>(
      '/api/admin/packing/history',
      queryParameters: <String, dynamic>{
        'from': from,
        'to': to,
        if (trimmed.isNotEmpty) 'keyword': trimmed,
      },
    ));
    return ((response.data['data'] as List<dynamic>?) ?? const [])
        .map(
            (e) => PackingHistoryEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Response<dynamic> _ensureOk(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return response;
    }
    final body = response.data;
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : '';
    throw ServerException(message, statusCode: code);
  }
}
