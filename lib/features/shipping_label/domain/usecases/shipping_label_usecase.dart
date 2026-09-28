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
import '../repositories/shipping_label_repository.dart';

/// Shipping Label 발송처리/미리보기/내보내기 UseCase (Repository 에 위임하는 얇은 계층).
class ShippingLabelUseCase {
  final ShippingLabelRepository repository;

  ShippingLabelUseCase({required this.repository});

  Future<Either<Failure, ShipmentConfirmResult>> confirmShipment({
    required Uint8List bytes,
    required String filename,
  }) =>
      repository.confirmShipment(bytes: bytes, filename: filename);

  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRows({
    int? sellerId,
  }) =>
      repository.previewRows(sellerId: sellerId);

  Future<Either<Failure, List<ShippingLabelPreviewRow>>> previewRowsByOrder({
    required int orderItemId,
  }) =>
      repository.previewRowsByOrder(orderItemId: orderItemId);

  Future<Either<Failure, Uint8List>> exportSpreadsheet(
    List<ShippingLabelPreviewRow> rows,
  ) =>
      repository.exportSpreadsheet(rows);

  Future<Either<Failure, List<CarrierOption>>> getCarrierOptions({
    required String platform,
  }) =>
      repository.getCarrierOptions(platform: platform);

  Future<Either<Failure, ManualShipmentResult>> confirmManualShipment({
    required int orderItemId,
    required String deliveryCompanyCode,
    required String invoiceNumber,
  }) =>
      repository.confirmManualShipment(
        orderItemId: orderItemId,
        deliveryCompanyCode: deliveryCompanyCode,
        invoiceNumber: invoiceNumber,
      );

  /// 「내부 상품준비중」 접수시트(FEATURE_2609_75 / D26).
  Future<Either<Failure, InternalLabelPreview>> previewInternalRows({
    int? sellerId,
  }) =>
      repository.previewInternalRows(sellerId: sellerId);

  /// [예약 발송](D20·D27).
  Future<Either<Failure, ReservationCreateResult>> reserveShipment({
    required Uint8List bytes,
    required String filename,
    required String executeAt,
  }) =>
      repository.reserveShipment(
        bytes: bytes,
        filename: filename,
        executeAt: executeAt,
      );

  Future<Either<Failure, List<ReservedShipmentRow>>> getReservedShipments() =>
      repository.getReservedShipments();

  Future<Either<Failure, List<ReservedShipmentRow>>> getReservedShipmentsByOrder(
    String externalOrderId,
  ) =>
      repository.getReservedShipmentsByOrder(externalOrderId);

  Future<Either<Failure, ReservedShipmentRow>> changeReservationTime(
    int itemId,
    String executeAt,
  ) =>
      repository.changeReservationTime(itemId, executeAt);

  Future<Either<Failure, ReservedShipmentRow>> retryReservation(int itemId) =>
      repository.retryReservation(itemId);

  /// 송장은 배송 묶음 단위(D18) — 조회는 주문번호, 저장은 배송 묶음 id.
  Future<Either<Failure, List<StoredInvoice>>> getStoredInvoices(
    String externalOrderId,
  ) =>
      repository.getStoredInvoices(externalOrderId);

  Future<Either<Failure, StoredInvoice>> changeReservedInvoice(
    int orderShipmentId, {
    required String deliveryCompanyCode,
    required String invoiceNumber,
  }) =>
      repository.changeReservedInvoice(
        orderShipmentId,
        deliveryCompanyCode: deliveryCompanyCode,
        invoiceNumber: invoiceNumber,
      );

  /// 저장된 송장으로 [예약 발송]·[지금 발송](D18) — 발송처리 다이얼로그의 저장된 송장 모드가 부른다.
  Future<Either<Failure, ReservationCreateResult>> reserveStored(
    List<int> orderItemIds,
    String executeAt,
  ) =>
      repository.reserveStored(orderItemIds, executeAt);

  Future<Either<Failure, ShipmentConfirmResult>> shipStoredNow(
    List<int> orderItemIds,
  ) =>
      repository.shipStoredNow(orderItemIds);
}
