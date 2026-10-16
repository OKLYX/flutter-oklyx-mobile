import 'package:equatable/equatable.dart';

import '../../data/models/cancel_reason_option.dart';
import '../../data/models/elevenst_cancel_request.dart';
import '../../data/models/elevenst_choices.dart';
import '../../data/models/elevenst_delivery_line.dart';
import '../../data/models/order_cancel_result.dart';

/// State of `ElevenstOrderActionBloc` (FEATURE_2610_17 / D19 · D35 ·
/// D61 ~ D67).
///
/// - [forbidden] = a write came back 403 (not ADMIN) → the screen hides the
///   11st write buttons from then on (mobile has no role check of its own).
/// - [returnSent] = the seller return request was accepted → the form locks.
/// - [errorMessage] = server / 11st wording of the last failure (one-shot).
/// - [choices] = the reason lists of D61 · D62 · D63 ([choicesFailed] = the
///   load failed). [saleRefusal] = the last sale-refusal result (11st's own
///   failure text sits in its `failed`). [delaySent] · [visitPickupDone] ·
///   [stockSent] = that write was accepted. [deliveryLines] = the lines of the
///   same delivery (D64).
class ElevenstOrderActionState extends Equatable {
  final List<ElevenstCancelRequest> requests;
  final bool requestsFailed;
  final List<CancelReasonOption> reasons;
  final bool reasonsFailed;
  final bool sending;
  final bool forbidden;
  final bool returnSent;
  final String? errorMessage;
  final ElevenstChoices choices;
  final bool choicesFailed;
  final OrderCancelResult? saleRefusal;
  final bool delaySent;
  final bool visitPickupDone;
  final bool stockSent;
  final List<ElevenstDeliveryLine> deliveryLines;
  final bool deliveryLinesFailed;

  const ElevenstOrderActionState({
    required this.requests,
    required this.requestsFailed,
    required this.reasons,
    required this.reasonsFailed,
    required this.sending,
    required this.forbidden,
    required this.returnSent,
    required this.errorMessage,
    required this.choices,
    required this.choicesFailed,
    required this.saleRefusal,
    required this.delaySent,
    required this.visitPickupDone,
    required this.stockSent,
    required this.deliveryLines,
    required this.deliveryLinesFailed,
  });

  const ElevenstOrderActionState.initial()
      : requests = const [],
        requestsFailed = false,
        reasons = const [],
        reasonsFailed = false,
        sending = false,
        forbidden = false,
        returnSent = false,
        errorMessage = null,
        choices = ElevenstChoices.empty,
        choicesFailed = false,
        saleRefusal = null,
        delaySent = false,
        visitPickupDone = false,
        stockSent = false,
        deliveryLines = const [],
        deliveryLinesFailed = false;

  /// ⚠️ [errorMessage] is cleared with [clearError] only (same rule as the
  /// sibling order BLoCs — passing null would keep the old value).
  ElevenstOrderActionState copyWith({
    List<ElevenstCancelRequest>? requests,
    bool? requestsFailed,
    List<CancelReasonOption>? reasons,
    bool? reasonsFailed,
    bool? sending,
    bool? forbidden,
    bool? returnSent,
    String? errorMessage,
    bool clearError = false,
    ElevenstChoices? choices,
    bool? choicesFailed,
    OrderCancelResult? saleRefusal,
    bool? delaySent,
    bool? visitPickupDone,
    bool? stockSent,
    List<ElevenstDeliveryLine>? deliveryLines,
    bool? deliveryLinesFailed,
  }) =>
      ElevenstOrderActionState(
        requests: requests ?? this.requests,
        requestsFailed: requestsFailed ?? this.requestsFailed,
        reasons: reasons ?? this.reasons,
        reasonsFailed: reasonsFailed ?? this.reasonsFailed,
        sending: sending ?? this.sending,
        forbidden: forbidden ?? this.forbidden,
        returnSent: returnSent ?? this.returnSent,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        choices: choices ?? this.choices,
        choicesFailed: choicesFailed ?? this.choicesFailed,
        saleRefusal: saleRefusal ?? this.saleRefusal,
        delaySent: delaySent ?? this.delaySent,
        visitPickupDone: visitPickupDone ?? this.visitPickupDone,
        stockSent: stockSent ?? this.stockSent,
        deliveryLines: deliveryLines ?? this.deliveryLines,
        deliveryLinesFailed: deliveryLinesFailed ?? this.deliveryLinesFailed,
      );

  @override
  List<Object?> get props => [
        requests,
        requestsFailed,
        reasons,
        reasonsFailed,
        sending,
        forbidden,
        returnSent,
        errorMessage,
        choices,
        choicesFailed,
        saleRefusal,
        delaySent,
        visitPickupDone,
        stockSent,
        deliveryLines,
        deliveryLinesFailed,
      ];
}
