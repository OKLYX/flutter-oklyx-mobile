import 'package:equatable/equatable.dart';

import 'cancel_reason_option.dart';

/// Code lists of the LotteON order-detail actions
/// (GET /api/orders/lotteon-choices, FEATURE_2611_23 / D24 · D25 · D26 ·
/// D58).
///
/// **Purpose**: the reason dropdowns of [주문 취소] (225), [취소 거부] (59),
/// [발송 약정일 안내] (138 + the detail reasons of 「제작지연」) and the
/// return / exchange hold (141).
///
/// ⚠️ The labels are LotteON's own names from the server — never keep a
/// code → label map in the app (D58).
class LotteonChoices extends Equatable {
  final List<CancelReasonOption> cancelReasons;
  final List<CancelReasonOption> cancelRejectReasons;
  final List<CancelReasonOption> appointmentReasons;
  final List<CancelReasonOption> appointmentDetailReasons;
  final List<CancelReasonOption> holdReasons;

  const LotteonChoices({
    required this.cancelReasons,
    required this.cancelRejectReasons,
    required this.appointmentReasons,
    required this.appointmentDetailReasons,
    required this.holdReasons,
  });

  static const LotteonChoices empty = LotteonChoices(
    cancelReasons: [],
    cancelRejectReasons: [],
    appointmentReasons: [],
    appointmentDetailReasons: [],
    holdReasons: [],
  );

  factory LotteonChoices.fromJson(Map<String, dynamic> json) {
    List<CancelReasonOption> list(String key) => (json[key] as List? ?? [])
        .map((e) => CancelReasonOption.fromJson(e as Map<String, dynamic>))
        .toList();
    return LotteonChoices(
      cancelReasons: list('cancelReasons'),
      cancelRejectReasons: list('cancelRejectReasons'),
      appointmentReasons: list('appointmentReasons'),
      appointmentDetailReasons: list('appointmentDetailReasons'),
      holdReasons: list('holdReasons'),
    );
  }

  @override
  List<Object?> get props => [
        cancelReasons,
        cancelRejectReasons,
        appointmentReasons,
        appointmentDetailReasons,
        holdReasons,
      ];
}
