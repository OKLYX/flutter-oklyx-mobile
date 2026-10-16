import 'package:equatable/equatable.dart';

/// Events of `ElevenstOrderActionBloc` (FEATURE_2610_17 / D19 · D35 · D36 · D38).
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
