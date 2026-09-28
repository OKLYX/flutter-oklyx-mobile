import 'package:equatable/equatable.dart';

import '../../data/models/reserved_shipment_row.dart';
import '../../data/models/stored_invoice.dart';

abstract class ReservedShipmentEvent extends Equatable {
  const ReservedShipmentEvent();

  @override
  List<Object?> get props => [];
}

/// 행 조회(진입 · 당겨서 새로고침). [externalOrderId] 가 있으면 그 주문의 기록 + 「송장」(E14)만(주문 상세·송장 시트, D30·D18).
/// 한 번 정한 범위는 BLoC 이 기억한다 — 새로고침은 인자 없이 보낸다.
class ReservedShipmentsRequested extends ReservedShipmentEvent {
  final String? externalOrderId;

  const ReservedShipmentsRequested({this.externalOrderId});

  @override
  List<Object?> get props => [externalOrderId];
}

/// [다시 시도] (D16).
class ReservationRetryRequested extends ReservedShipmentEvent {
  final ReservedShipmentRow row;

  const ReservationRetryRequested(this.row);

  @override
  List<Object?> get props => [row];
}

/// [시각 변경] (D18) — [executeAt] = KST 'yyyy-MM-ddTHH:mm:ss'.
class ReservationTimeChanged extends ReservedShipmentEvent {
  final ReservedShipmentRow row;
  final String executeAt;

  const ReservationTimeChanged(this.row, this.executeAt);

  @override
  List<Object?> get props => [row, executeAt];
}

/// 현황 카드의 [송장 수정] (D18) — 택배사 코드 + 송장번호(하이픈 제거는 서버가 한다). E12 는 `row.orderShipmentId`.
class ReservationInvoiceChanged extends ReservedShipmentEvent {
  final ReservedShipmentRow row;
  final String deliveryCompanyCode;
  final String invoiceNumber;

  const ReservationInvoiceChanged(
      this.row, this.deliveryCompanyCode, this.invoiceNumber);

  @override
  List<Object?> get props => [row, deliveryCompanyCode, invoiceNumber];
}

/// [예약 취소] (D18 행2) — 그 행의 주문 라인으로 E7 을 보낸다.
class ReservationCancelRequested extends ReservedShipmentEvent {
  final ReservedShipmentRow row;

  const ReservationCancelRequested(this.row);

  @override
  List<Object?> get props => [row];
}

/// 「송장」의 [송장 수정] (D18 🔁) — 배송 묶음 1개. 송장이 없던 묶음이면 서버가 보관 행을 만든다.
class StoredInvoiceChanged extends ReservedShipmentEvent {
  final StoredInvoice invoice;
  final String deliveryCompanyCode;
  final String invoiceNumber;

  const StoredInvoiceChanged(
      this.invoice, this.deliveryCompanyCode, this.invoiceNumber);

  @override
  List<Object?> get props => [invoice, deliveryCompanyCode, invoiceNumber];
}
