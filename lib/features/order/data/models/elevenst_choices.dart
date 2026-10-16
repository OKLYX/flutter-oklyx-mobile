import 'package:equatable/equatable.dart';

import 'cancel_reason_option.dart';

/// Code lists of the 11st order-detail actions
/// (GET /api/orders/elevenst-choices, FEATURE_2610_17 / D61 · D62 · D63).
///
/// **Purpose**: the reason dropdowns of [주문 취소] (sale refusal 1638),
/// [책임사유 오류로 거부] (1745) and [발송지연 안내] (6728).
///
/// ⚠️ The labels are 11st's own names from the server — never keep a
/// code → label map in the app.
class ElevenstChoices extends Equatable {
  final List<CancelReasonOption> cancelReasons;
  final List<CancelReasonOption> faultRejectReasons;
  final List<CancelReasonOption> delayReasons;

  const ElevenstChoices({
    required this.cancelReasons,
    required this.faultRejectReasons,
    required this.delayReasons,
  });

  static const ElevenstChoices empty = ElevenstChoices(
    cancelReasons: [],
    faultRejectReasons: [],
    delayReasons: [],
  );

  factory ElevenstChoices.fromJson(Map<String, dynamic> json) {
    List<CancelReasonOption> list(String key) => (json[key] as List? ?? [])
        .map((e) => CancelReasonOption.fromJson(e as Map<String, dynamic>))
        .toList();
    return ElevenstChoices(
      cancelReasons: list('cancelReasons'),
      faultRejectReasons: list('faultRejectReasons'),
      delayReasons: list('delayReasons'),
    );
  }

  @override
  List<Object?> get props => [cancelReasons, faultRejectReasons, delayReasons];
}
