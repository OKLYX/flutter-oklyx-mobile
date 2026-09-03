import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import '../models/shipment_confirm_result.dart';
import '../models/shipping_label_preview_row.dart';

abstract class ShippingLabelRemoteDataSource {
  /// POST /api/admin/shipping-labels/confirm (multipart, param 'file')
  /// JSON 봉투 응답 → data 언래핑해 ShipmentConfirmResult 반환.
  Future<ShipmentConfirmResult> confirmShipment({
    required Uint8List bytes,
    required String filename,
  });

  /// GET /api/admin/shipping-labels/v2/preview?sellerId={sellerId}
  /// 편집용 full rows(JSON 봉투) → data 언래핑해 리스트 반환 (bytes 아님).
  Future<List<ShippingLabelPreviewRow>> previewRows({int? sellerId});

  /// GET /api/admin/shipping-labels/v2/preview/by-order?orderItemId={id}
  /// 주문 한 건(상태 무관)의 편집용 rows(JSON 봉투) → data 언래핑해 리스트 반환.
  Future<List<ShippingLabelPreviewRow>> previewRowsByOrder({
    required int orderItemId,
  });

  /// POST /api/admin/shipping-labels/v2/spreadsheet (body {rows:[...]})
  /// 편집된 rows → xlsx 바이너리 반환 (JSON 언래핑 없음).
  Future<Uint8List> exportSpreadsheet(List<ShippingLabelPreviewRow> rows);
}

class ShippingLabelRemoteDataSourceImpl implements ShippingLabelRemoteDataSource {
  final Dio dio;

  ShippingLabelRemoteDataSourceImpl({required this.dio});

  @override
  Future<ShipmentConfirmResult> confirmShipment({
    required Uint8List bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await dio.post(
      '/api/admin/shipping-labels/confirm',
      // Dio 가 multipart boundary 를 자동 설정한다 (Content-Type 수동 지정 금지).
      data: formData,
      options: Options(
        // 서버가 쿠팡 송장업로드 API를 실호출 → 기본 30초 초과 가능해 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    // preview(JSON 봉투)와 동일하게 data 언래핑.
    return ShipmentConfirmResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ShippingLabelPreviewRow>> previewRows({int? sellerId}) async {
    // preview 는 편집용 JSON 봉투 → data(List) 언래핑 (export 와 달리 bytes 아님).
    final response = await dio.get(
      '/api/admin/shipping-labels/v2/preview',
      queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
      options: Options(
        // 서버가 쿠팡 API를 실시간 조회 → 기본 30초 초과 가능해 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return (response.data['data'] as List)
        .map((e) =>
            ShippingLabelPreviewRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ShippingLabelPreviewRow>> previewRowsByOrder({
    required int orderItemId,
  }) async {
    // 목록 preview 와 동일한 JSON 봉투 → data(List) 언래핑.
    final response = await dio.get(
      '/api/admin/shipping-labels/v2/preview/by-order',
      queryParameters: {'orderItemId': orderItemId},
      options: Options(
        // 서버가 쿠팡 단건 주문을 실시간 조회 → 기본 30초 초과 가능해 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return (response.data['data'] as List)
        .map((e) =>
            ShippingLabelPreviewRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Uint8List> exportSpreadsheet(
      List<ShippingLabelPreviewRow> rows) async {
    // 편집된 rows POST → xlsx 는 바이너리 → ResponseType.bytes 로 받아 반환.
    // 클라에서 택배수량 최소 1 을 강제하므로 400(@Min(1))은 발생하지 않는 전제.
    final response = await dio.post(
      '/api/admin/shipping-labels/v2/spreadsheet',
      data: {'rows': rows.map((r) => r.toJson()).toList()},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as Uint8List;
  }
}
