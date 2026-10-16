import 'package:equatable/equatable.dart';

import '../../data/models/cancel_reason_option.dart';
import '../../data/models/elevenst_cancel_request.dart';

/// State of `ElevenstOrderActionBloc` (FEATURE_2610_17 / D19 · D35).
///
/// - [forbidden] = a write came back 403 (not ADMIN) → the screen hides the
///   11st write buttons from then on (mobile has no role check of its own).
/// - [returnSent] = the seller return request was accepted → the form locks.
/// - [errorMessage] = server / 11st wording of the last failure (one-shot).
class ElevenstOrderActionState extends Equatable {
  final List<ElevenstCancelRequest> requests;
  final bool requestsFailed;
  final List<CancelReasonOption> reasons;
  final bool reasonsFailed;
  final bool sending;
  final bool forbidden;
  final bool returnSent;
  final String? errorMessage;

  const ElevenstOrderActionState({
    required this.requests,
    required this.requestsFailed,
    required this.reasons,
    required this.reasonsFailed,
    required this.sending,
    required this.forbidden,
    required this.returnSent,
    required this.errorMessage,
  });

  const ElevenstOrderActionState.initial()
      : requests = const [],
        requestsFailed = false,
        reasons = const [],
        reasonsFailed = false,
        sending = false,
        forbidden = false,
        returnSent = false,
        errorMessage = null;

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
        errorMessage
      ];
}
