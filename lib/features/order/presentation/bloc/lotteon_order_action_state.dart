import 'package:equatable/equatable.dart';

import '../../data/models/lotteon_cancel_request.dart';
import '../../data/models/lotteon_choices.dart';
import '../../data/models/order_cancel_result.dart';

/// State of `LotteonOrderActionBloc` (FEATURE_2611_23 / D24 · D25 · D26 ·
/// D57).
///
/// - [forbidden] = a write came back 403 (not ADMIN) → the screen hides the
///   LotteON write buttons from then on (mobile has no role check of its own).
/// - [errorMessage] = server / LotteON wording of the last failure (one-shot).
/// - [choices] = the reason lists of D58 ([choicesFailed] = the load failed).
/// - [sellerCancel] = the last seller-cancel result (LotteON's own failure
///   text sits in its `failed`). [appointmentSent] = the last delivery
///   appointment was accepted.
class LotteonOrderActionState extends Equatable {
  final List<LotteonCancelRequest> requests;
  final bool requestsFailed;
  final LotteonChoices choices;
  final bool choicesFailed;
  final bool sending;
  final bool forbidden;
  final String? errorMessage;
  final OrderCancelResult? sellerCancel;
  final bool appointmentSent;

  const LotteonOrderActionState({
    required this.requests,
    required this.requestsFailed,
    required this.choices,
    required this.choicesFailed,
    required this.sending,
    required this.forbidden,
    required this.errorMessage,
    required this.sellerCancel,
    required this.appointmentSent,
  });

  const LotteonOrderActionState.initial()
      : requests = const [],
        requestsFailed = false,
        choices = LotteonChoices.empty,
        choicesFailed = false,
        sending = false,
        forbidden = false,
        errorMessage = null,
        sellerCancel = null,
        appointmentSent = false;

  /// ⚠️ [errorMessage] is cleared with [clearError] only (same rule as the
  /// sibling order BLoCs — passing null would keep the old value).
  LotteonOrderActionState copyWith({
    List<LotteonCancelRequest>? requests,
    bool? requestsFailed,
    LotteonChoices? choices,
    bool? choicesFailed,
    bool? sending,
    bool? forbidden,
    String? errorMessage,
    bool clearError = false,
    OrderCancelResult? sellerCancel,
    bool? appointmentSent,
  }) =>
      LotteonOrderActionState(
        requests: requests ?? this.requests,
        requestsFailed: requestsFailed ?? this.requestsFailed,
        choices: choices ?? this.choices,
        choicesFailed: choicesFailed ?? this.choicesFailed,
        sending: sending ?? this.sending,
        forbidden: forbidden ?? this.forbidden,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        sellerCancel: sellerCancel ?? this.sellerCancel,
        appointmentSent: appointmentSent ?? this.appointmentSent,
      );

  @override
  List<Object?> get props => [
        requests,
        requestsFailed,
        choices,
        choicesFailed,
        sending,
        forbidden,
        errorMessage,
        sellerCancel,
        appointmentSent,
      ];
}
