import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import '../models/carrier_option.dart';
import '../models/internal_label_preview.dart';
import '../models/manual_shipment_result.dart';
import '../models/reservation_create_result.dart';
import '../models/reserved_shipment_row.dart';
import '../models/stored_invoice.dart';
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

  /// GET /api/admin/shipping-labels/carrier-options?platform={platform}
  /// 그 플랫폼에 코드가 등록된 활성 택배사(JSON 봉투) → data 언래핑. DB lookup 이라 타임아웃 연장 없음.
  Future<List<CarrierOption>> getCarrierOptions({required String platform});

  /// POST /api/admin/shipping-labels/confirm/manual (body {orderItemId, deliveryCompanyCode, invoiceNumber})
  /// 한 박스 단건 발송처리(또는 송장수정) 결과(JSON 봉투) → data 언래핑.
  Future<ManualShipmentResult> confirmManualShipment({
    required int orderItemId,
    required String deliveryCompanyCode,
    required String invoiceNumber,
  });

  /// GET /api/admin/shipping-labels/v2/preview/internal?sellerId={sellerId}
  /// 「내부 상품준비중」 접수시트 행 + 쿠팡 결제완료 목록에 없던 주문번호(FEATURE_2609_75 / D26).
  Future<InternalLabelPreview> previewInternalRows({int? sellerId});

  /// POST /api/admin/reserved-shipments (multipart 'file' + 'executeAt')
  /// [예약 발송] — 송장만 저장한다(D20·D27). [executeAt] = KST 'yyyy-MM-ddTHH:mm:ss'.
  Future<ReservationCreateResult> reserveShipment({
    required Uint8List bytes,
    required String filename,
    required String executeAt,
  });

  /// GET /api/admin/reserved-shipments → 주문 행(끝나지 않은 것 + 최근 7일, D30).
  Future<List<ReservedShipmentRow>> getReservedShipments();

  /// GET /api/admin/reserved-shipments/orders/{externalOrderId} → 그 주문의 행 전부(주문 상세, D30).
  Future<List<ReservedShipmentRow>> getReservedShipmentsByOrder(
    String externalOrderId,
  );

  /// PATCH /api/admin/reserved-shipments/items/{itemId}/execute-at  body: {"executeAt": "..."} (D18 시각 변경)
  Future<ReservedShipmentRow> changeReservationTime(int itemId, String executeAt);

  /// POST /api/admin/reserved-shipments/items/{itemId}/retry — 자동 재시도가 멈춘 주문을 다시 실행(D16).
  Future<ReservedShipmentRow> retryReservation(int itemId);

  /// GET /api/admin/reserved-shipments/orders/{externalOrderId}/invoices → 내부 단계 배송 묶음별 현재 송장(D18).
  Future<List<StoredInvoice>> getStoredInvoices(String externalOrderId);

  /// PUT /api/admin/reserved-shipments/shipments/{orderShipmentId}/invoice
  /// body: {"deliveryCompanyCode": "...", "invoiceNumber": "..."} (D18 🔁 송장 수정 — 배송 묶음 단위)
  Future<StoredInvoice> changeReservedInvoice(
    int orderShipmentId, {
    required String deliveryCompanyCode,
    required String invoiceNumber,
  });

  /// POST /api/admin/reserved-shipments/stored  body: {"orderItemIds":[...], "executeAt":"..."}
  /// 저장된 송장으로 [예약 발송](D18) — 파일 없음.
  Future<ReservationCreateResult> reserveStored(
    List<int> orderItemIds,
    String executeAt,
  );

  /// POST /api/admin/reserved-shipments/stored/ship-now  body: {"orderItemIds":[...]}
  /// 저장된 송장으로 [지금 발송](D18) — 서버가 쿠팡 발주처리 → 송장 등록. 응답은 파일 [지금 발송]과 같은 모양.
  Future<ShipmentConfirmResult> shipStoredNow(List<int> orderItemIds);
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

  @override
  Future<List<CarrierOption>> getCarrierOptions({
    required String platform,
  }) async {
    // 쿠팡 호출이 아니라 DB lookup(수 건) → receiveTimeout 연장 불필요.
    final response = await dio.get(
      '/api/admin/shipping-labels/carrier-options',
      queryParameters: {'platform': platform},
    );
    return (response.data['data'] as List)
        .map((e) => CarrierOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ManualShipmentResult> confirmManualShipment({
    required int orderItemId,
    required String deliveryCompanyCode,
    required String invoiceNumber,
  }) async {
    final response = await dio.post(
      '/api/admin/shipping-labels/confirm/manual',
      data: {
        'orderItemId': orderItemId,
        'deliveryCompanyCode': deliveryCompanyCode,
        'invoiceNumber': invoiceNumber,
      },
      options: Options(
        // 서버가 쿠팡 송장업로드 API를 실호출 → confirmShipment 와 동일하게 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return ManualShipmentResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // ⚠️ 아래 10개는 try/catch 없이 DioException 을 올린다 — 레포지토리가 400 서버 문구·403 을 살린다.
  @override
  Future<InternalLabelPreview> previewInternalRows({int? sellerId}) async {
    final response = await dio.get(
      '/api/admin/shipping-labels/v2/preview/internal',
      queryParameters: sellerId != null ? {'sellerId': sellerId} : null,
      options: Options(
        // 서버가 쿠팡 결제완료 목록을 창마다 조회(D26) → 기본 30초 초과 가능해 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return InternalLabelPreview.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ReservationCreateResult> reserveShipment({
    required Uint8List bytes,
    required String filename,
    required String executeAt,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'executeAt': executeAt,
    });
    // DB 에만 쓴다(쿠팡 호출 없음, D27) → receiveTimeout 연장 없음.
    final response = await dio.post(
      '/api/admin/reserved-shipments',
      data: formData,
    );
    return ReservationCreateResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ReservedShipmentRow>> getReservedShipments() async {
    final response = await dio.get('/api/admin/reserved-shipments');
    return (response.data['data'] as List)
        .map((e) => ReservedShipmentRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReservedShipmentRow>> getReservedShipmentsByOrder(
    String externalOrderId,
  ) async {
    final response = await dio.get(
      '/api/admin/reserved-shipments/orders/${Uri.encodeComponent(externalOrderId)}',
    );
    return (response.data['data'] as List)
        .map((e) => ReservedShipmentRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReservedShipmentRow> changeReservationTime(
    int itemId,
    String executeAt,
  ) async {
    final response = await dio.patch(
      '/api/admin/reserved-shipments/items/$itemId/execute-at',
      data: {'executeAt': executeAt},
    );
    return ReservedShipmentRow.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ReservedShipmentRow> retryReservation(int itemId) async {
    final response = await dio.post(
      '/api/admin/reserved-shipments/items/$itemId/retry',
      options: Options(
        // 서버가 그 자리에서 쿠팡 발주처리·송장 등록을 한다 → 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return ReservedShipmentRow.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<StoredInvoice>> getStoredInvoices(String externalOrderId) async {
    final response = await dio.get(
      '/api/admin/reserved-shipments/orders/${Uri.encodeComponent(externalOrderId)}/invoices',
    );
    return (response.data['data'] as List)
        .map((e) => StoredInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StoredInvoice> changeReservedInvoice(
    int orderShipmentId, {
    required String deliveryCompanyCode,
    required String invoiceNumber,
  }) async {
    final response = await dio.put(
      '/api/admin/reserved-shipments/shipments/$orderShipmentId/invoice',
      data: {
        'deliveryCompanyCode': deliveryCompanyCode,
        'invoiceNumber': invoiceNumber,
      },
    );
    return StoredInvoice.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ReservationCreateResult> reserveStored(
    List<int> orderItemIds,
    String executeAt,
  ) async {
    // DB 에만 쓴다(쿠팡 호출 없음) → receiveTimeout 연장 없음.
    final response = await dio.post(
      '/api/admin/reserved-shipments/stored',
      data: {'orderItemIds': orderItemIds, 'executeAt': executeAt},
    );
    return ReservationCreateResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ShipmentConfirmResult> shipStoredNow(List<int> orderItemIds) async {
    final response = await dio.post(
      '/api/admin/reserved-shipments/stored/ship-now',
      data: {'orderItemIds': orderItemIds},
      options: Options(
        // 서버가 그 자리에서 쿠팡 발주처리·송장 등록을 한다 → 개별 연장.
        receiveTimeout:
            const Duration(seconds: AppConstants.coupangReceiveTimeout),
      ),
    );
    return ShipmentConfirmResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
