import 'package:equatable/equatable.dart';

/// Events of `ElevenstOrderActionBloc` (FEATURE_2610_17 / D19 · D35 · D36 · D38 ·
/// D61 ~ D67).
abstract class ElevenstOrderActionEvent extends Equatable {
  const ElevenstOrderActionEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the open cancel requests of one order line.
class ElevenstCancelRequestsRequested extends ElevenstOrderActionEvent {
  final int orderItemId;

  const ElevenstCancelRequestsRequested(this.orderItemId);

  @override
  List<Object?> get props => [orderItemId];
}

/// [취소 승인] — sent only after the confirm dialog (D37).
class ElevenstCancelApproveRequested extends ElevenstOrderActionEvent {
  final int requestId;
  final int orderItemId;

  const ElevenstCancelApproveRequested(
      {required this.requestId, required this.orderItemId});

  @override
  List<Object?> get props => [requestId, orderItemId];
}

/// [취소 거부] — carrier · invoice · date sent 'yyyy-MM-dd' (D38).
class ElevenstCancelRejectRequested extends ElevenstOrderActionEvent {
  final int requestId;
  final int orderItemId;
  final String deliveryCompanyCode;
  final String invoiceNumber;
  final String sendDate;

  const ElevenstCancelRejectRequested({
    required this.requestId,
    required this.orderItemId,
    required this.deliveryCompanyCode,
    required this.invoiceNumber,
    required this.sendDate,
  });

  @override
  List<Object?> get props =>
      [requestId, orderItemId, deliveryCompanyCode, invoiceNumber, sendDate];
}

/// Loads the 13 seller-return reasons (D39 ⑤).
class ElevenstReturnReasonsRequested extends ElevenstOrderActionEvent {
  const ElevenstReturnReasonsRequested();
}

/// [판매자가 대신 반품 신청] (D35 · D36 · D39 ⑤). [body] is the request JSON.
class ElevenstReturnRequested extends ElevenstOrderActionEvent {
  final int orderItemId;
  final Map<String, dynamic> body;

  const ElevenstReturnRequested(
      {required this.orderItemId, required this.body});

  @override
  List<Object?> get props => [orderItemId, body];
}

/// Clears the one-shot error so the same message does not toast twice.
class ElevenstActionErrorCleared extends ElevenstOrderActionEvent {
  const ElevenstActionErrorCleared();
}

/// Loads the reason lists of [주문 취소] · [책임사유 오류로 거부] ·
/// [발송지연 안내] once on entry (D61 · D62 · D63).
class ElevenstChoicesRequested extends ElevenstOrderActionEvent {
  const ElevenstChoicesRequested();
}

/// [주문 취소] of an 11st line = sale refusal 1638 of the whole line (D61).
class ElevenstSaleRefusalRequested extends ElevenstOrderActionEvent {
  final int orderItemId;

  /// Request-check quantity only — 11st cancels the whole line.
  final int quantity;
  final String reasonCode;
  final String reasonText;

  const ElevenstSaleRefusalRequested({
    required this.orderItemId,
    required this.quantity,
    required this.reasonCode,
    required this.reasonText,
  });

  @override
  List<Object?> get props => [orderItemId, quantity, reasonCode, reasonText];
}

/// [책임사유 오류로 거부] (1745, D62) — [body] = refuseCode · reasonText +
/// the same delivery fields as [취소 거부].
class ElevenstCancelFaultRejectRequested extends ElevenstOrderActionEvent {
  final int requestId;
  final int orderItemId;
  final Map<String, dynamic> body;

  const ElevenstCancelFaultRejectRequested({
    required this.requestId,
    required this.orderItemId,
    required this.body,
  });

  @override
  List<Object?> get props => [requestId, orderItemId, body];
}

/// Loads the lines of the same 11st delivery for the partial / split pickers
/// (D64).
class ElevenstDeliveryLinesRequested extends ElevenstOrderActionEvent {
  final int orderItemId;

  const ElevenstDeliveryLinesRequested(this.orderItemId);

  @override
  List<Object?> get props => [orderItemId];
}

/// [발송지연 안내] (6728, D63) — [body] = expectedDate 'yyyy-MM-dd' ·
/// reasonCode · reasonText.
class ElevenstDeliveryDelayRequested extends ElevenstOrderActionEvent {
  final int orderItemId;
  final Map<String, dynamic> body;

  const ElevenstDeliveryDelayRequested(
      {required this.orderItemId, required this.body});

  @override
  List<Object?> get props => [orderItemId, body];
}

/// [방문수령 완료] (7052, D66) — sent only after the confirm dialog.
class ElevenstVisitPickupRequested extends ElevenstOrderActionEvent {
  final int orderItemId;
  final String certCode;

  const ElevenstVisitPickupRequested(
      {required this.orderItemId, required this.certCode});

  @override
  List<Object?> get props => [orderItemId, certCode];
}

/// [입고완료 처리] (1773, D67) — sent only after the confirm dialog.
class ElevenstStockConfirmRequested extends ElevenstOrderActionEvent {
  final int orderItemId;

  const ElevenstStockConfirmRequested(this.orderItemId);

  @override
  List<Object?> get props => [orderItemId];
}
