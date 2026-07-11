import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';

abstract class ShippingLabelRemoteDataSource {
  /// GET /api/admin/shipping-labels/spreadsheet?sellerId={sellerId}
  /// xlsx 바이너리를 그대로 반환 (JSON 언래핑 없음).
  Future<Uint8List> downloadSpreadsheet({int? sellerId});
}

class ShippingLabelRemoteDataSourceImpl implements ShippingLabelRemoteDataSource {
  final Dio dio;

  ShippingLabelRemoteDataSourceImpl({required this.dio});

  @override
  Future<Uint8List> downloadSpreadsheet({int? sellerId}) async {
    // xlsx 는 바이너리 → ResponseType.bytes 로 받아 Uint8List 반환.
    // 4xx/5xx 에러 본문도 bytes 로 오지만 파싱하지 않고 DioException 을 그대로 던진다.
    final response = await dio.get(
      '/api/admin/shipping-labels/spreadsheet',
      queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
      options: Options(
        responseType: ResponseType.bytes,
        // 서버가 쿠팡 API를 실시간 조회 → 기본 30초를 초과할 수 있어 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return response.data as Uint8List;
  }
}
