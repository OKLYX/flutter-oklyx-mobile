import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/carrier_option.dart';
import '../../data/models/internal_label_preview.dart';
import '../../data/models/manual_shipment_result.dart';
import '../../data/models/reservation_create_result.dart';
import '../../data/models/reserved_shipment_row.dart';
import '../../data/models/stored_invoice.dart';
import '../../data/models/shipment_confirm_result.dart';
import '../../data/models/shipping_label_preview_row.dart';

abstract class ShippingLabelRepository {
  /// 택배사 결과 xlsx 업로드 → 쿠팡 송장업로드 배치 결과.
  Future<Either<Failure, ShipmentConfirmResult>> confirmShipment({
    required Uint8List bytes,
    required String filename,
  });

  /// V2 편집용 미리보기 행 조회 (full rows).
  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRows({
    int? sellerId,
  });

  /// V2 단건 주문(상태 무관) 편집용 미리보기 행 조회.
  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRowsByOrder({
    required int orderItemId,
  });

  /// V2 편집된 rows → 접수용 xlsx 바이너리.
  Future<Either<Failure, Uint8List>> exportSpreadsheet(
    List<ShippingLabelPreviewRow> rows,
  );

  /// 단건 발송처리용 택배사 드롭다운 항목 (그 플랫폼에 코드가 등록된 활성 택배사).
  Future<Either<Failure, List<CarrierOption>>> getCarrierOptions({
    required String platform,
  });

  /// 한 박스 단건 발송처리(또는 송장수정) — 모드 판정은 서버가 한다(PLAN 2609_11 D3).
  Future<Either<Failure, ManualShipmentResult>> confirmManualShipment({
    required int orderItemId,
    required String deliveryCompanyCode,
    required String invoiceNumber,
  });

  /// 「내부 상품준비중」 접수시트 미리보기(FEATURE_2609_75 / D26).
  Future<Either<Failure, InternalLabelPreview>> previewInternalRows({
    int? sellerId,
  });

  /// [예약 발송] — 송장만 저장(D20·D27). [executeAt] = KST 'yyyy-MM-ddTHH:mm:ss'.
  Future<Either<Failure, ReservationCreateResult>> reserveShipment({
    required Uint8List bytes,
    required String filename,
    required String executeAt,
  });

  /// 예약 발송 현황 — 주문 행(D30).
  Future<Either<Failure, List<ReservedShipmentRow>>> getReservedShipments();

  /// 주문 1건의 예약 발송 기록(D30).
  Future<Either<Failure, List<ReservedShipmentRow>>> getReservedShipmentsByOrder(
    String externalOrderId,
  );

  /// 그 주문의 예약 시각 변경(D18).
  Future<Either<Failure, ReservedShipmentRow>> changeReservationTime(
    int itemId,
    String executeAt,
  );

  /// [다시 시도](D16).
  Future<Either<Failure, ReservedShipmentRow>> retryReservation(int itemId);

  /// 그 주문의 내부 단계 배송 묶음별 현재 송장(D18).
  Future<Either<Failure, List<StoredInvoice>>> getStoredInvoices(
    String externalOrderId,
  );

  /// 배송 묶음 1개의 택배사·송장번호 저장(D18 🔁).
  Future<Either<Failure, StoredInvoice>> changeReservedInvoice(
    int orderShipmentId, {
    required String deliveryCompanyCode,
    required String invoiceNumber,
  });

  /// 저장된 송장으로 [예약 발송](D18).
  Future<Either<Failure, ReservationCreateResult>> reserveStored(
    List<int> orderItemIds,
    String executeAt,
  );

  /// 저장된 송장으로 [지금 발송](D18).
  Future<Either<Failure, ShipmentConfirmResult>> shipStoredNow(
    List<int> orderItemIds,
  );
}
