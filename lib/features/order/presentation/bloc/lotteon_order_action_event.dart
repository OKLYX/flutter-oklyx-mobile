import 'package:equatable/equatable.dart';

/// Events of `LotteonOrderActionBloc` (FEATURE_2611_23 / D24 · D25 · D26).
abstract class LotteonOrderActionEvent extends Equatable {
  const LotteonOrderActionEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the open cancel requests of one order line.
class LotteonCancelRequestsRequested extends LotteonOrderActionEvent {
  final int orderItemId;

  const LotteonCancelRequestsRequested(this.orderItemId);

  @override
  List<Object?> get props => [orderItemId];
}

/// Loads the LotteON reason lists once on entry (D58).
class LotteonChoicesRequested extends LotteonOrderActionEvent {
  const LotteonChoicesRequested();
}

/// [취소 승인] — sent only after the confirm dialog (D24).
class LotteonCancelApproveRequested extends LotteonOrderActionEvent {
  final int requestId;
  final int orderItemId;

  const LotteonCancelApproveRequested(
      {required this.requestId, required this.orderItemId});

  @override
  List<Object?> get props => [requestId, orderItemId];
}

/// [취소 거부] — one of the three reasons + the optional text (D24).
class LotteonCancelRejectRequested extends LotteonOrderActionEvent {
  final int requestId;
  final int orderItemId;
  final String reasonCode;
  final String reasonText;

  const LotteonCancelRejectRequested({
    required this.requestId,
    required this.orderItemId,
    required this.reasonCode,
    required this.reasonText,
  });

  @override
  List<Object?> get props => [requestId, orderItemId, reasonCode, reasonText];
}

/// [발송 약정일 안내] (D26) — [body] = appointmentDate 'yyyy-MM-dd' ·
/// reasonCode · detailCode.
class LotteonDeliveryAppointmentRequested extends LotteonOrderActionEvent {
  final int orderItemId;
  final Map<String, dynamic> body;

  const LotteonDeliveryAppointmentRequested(
      {required this.orderItemId, required this.body});

  @override
  List<Object?> get props => [orderItemId, body];
}

/// [주문 취소] of a LotteON line = seller cancel of the whole line (D25).
class LotteonSellerCancelRequested extends LotteonOrderActionEvent {
  final int orderItemId;

  /// The remaining quantity of the line — LotteON cancels the whole line.
  final int quantity;
  final String reasonCode;
  final String reasonText;

  const LotteonSellerCancelRequested({
    required this.orderItemId,
    required this.quantity,
    required this.reasonCode,
    required this.reasonText,
  });

  @override
  List<Object?> get props => [orderItemId, quantity, reasonCode, reasonText];
}

/// Clears the one-shot error so the same message does not toast twice.
class LotteonActionErrorCleared extends LotteonOrderActionEvent {
  const LotteonActionErrorCleared();
}
