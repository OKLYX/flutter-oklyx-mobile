import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/order_usecase.dart';
import 'lotteon_order_action_event.dart';
import 'lotteon_order_action_state.dart';

/// The LotteON order-detail writes (FEATURE_2611_23 / D24 · D25 · D26 · D57):
/// open cancel requests + [취소 승인] · [취소 거부], [주문 취소] (seller
/// cancel of the whole line) and [발송 약정일 안내].
///
/// **Why one BLoC**: the writes live on the same LotteON order detail and
/// share the 403 rule — one 403 hides every LotteON write button (and turns
/// the cancel tab off, D57).
///
/// ⚠️ No automatic retry — the screen confirms before approve and before the
/// seller cancel.
/// ⚠️ After approve / reject the list is read again — the request disappears
/// once LotteON accepted it.
class LotteonOrderActionBloc
    extends Bloc<LotteonOrderActionEvent, LotteonOrderActionState> {
  final OrderUseCase useCase;

  LotteonOrderActionBloc({required this.useCase})
      : super(const LotteonOrderActionState.initial()) {
    on<LotteonCancelRequestsRequested>(_onLoadRequests);
    on<LotteonChoicesRequested>(_onLoadChoices);
    on<LotteonCancelApproveRequested>(_onApprove);
    on<LotteonCancelRejectRequested>(_onReject);
    on<LotteonDeliveryAppointmentRequested>(_onAppointment);
    on<LotteonSellerCancelRequested>(_onSellerCancel);
    on<LotteonActionErrorCleared>(
        (event, emit) => emit(state.copyWith(clearError: true)));
  }

  Future<void> _onLoadRequests(
    LotteonCancelRequestsRequested event,
    Emitter<LotteonOrderActionState> emit,
  ) async {
    final result = await useCase.getLotteonCancelRequests(event.orderItemId);
    if (emit.isDone) {
      return;
    }
    result.fold(
      (_) => emit(state.copyWith(requestsFailed: true)),
      (requests) =>
          emit(state.copyWith(requests: requests, requestsFailed: false)),
    );
  }

  Future<void> _onLoadChoices(
    LotteonChoicesRequested event,
    Emitter<LotteonOrderActionState> emit,
  ) async {
    final result = await useCase.getLotteonChoices();
    if (emit.isDone) {
      return;
    }
    result.fold(
      (_) => emit(state.copyWith(choicesFailed: true)),
      (choices) => emit(state.copyWith(choices: choices, choicesFailed: false)),
    );
  }

  Future<void> _onApprove(
    LotteonCancelApproveRequested event,
    Emitter<LotteonOrderActionState> emit,
  ) async {
    if (state.sending) {
      return;
    }
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.approveLotteonCancel(event.requestId);
    if (emit.isDone) {
      return;
    }
    await _afterWrite(result, event.orderItemId, emit);
  }

  Future<void> _onReject(
    LotteonCancelRejectRequested event,
    Emitter<LotteonOrderActionState> emit,
  ) async {
    if (state.sending) {
      return;
    }
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.rejectLotteonCancel(
      event.requestId,
      reasonCode: event.reasonCode,
      reasonText: event.reasonText,
    );
    if (emit.isDone) {
      return;
    }
    await _afterWrite(result, event.orderItemId, emit);
  }

  /// Failure → message (403 → [LotteonOrderActionState.forbidden]);
  /// success → read the list again.
  Future<void> _afterWrite(
    Either<Failure, Unit> result,
    int orderItemId,
    Emitter<LotteonOrderActionState> emit,
  ) async {
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      _emitFailure(failure, emit);
      return;
    }
    final reloaded = await useCase.getLotteonCancelRequests(orderItemId);
    if (emit.isDone) {
      return;
    }
    reloaded.fold(
      (_) => emit(state.copyWith(sending: false, requestsFailed: true)),
      (requests) => emit(state.copyWith(
          sending: false, requests: requests, requestsFailed: false)),
    );
  }

  Future<void> _onAppointment(
    LotteonDeliveryAppointmentRequested event,
    Emitter<LotteonOrderActionState> emit,
  ) async {
    if (state.sending) {
      return;
    }
    emit(state.copyWith(
        sending: true, appointmentSent: false, clearError: true));
    final result = await useCase.sendLotteonDeliveryAppointment(
        event.orderItemId, event.body);
    if (emit.isDone) {
      return;
    }
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (_) => emit(state.copyWith(sending: false, appointmentSent: true)),
    );
  }

  Future<void> _onSellerCancel(
    LotteonSellerCancelRequested event,
    Emitter<LotteonOrderActionState> emit,
  ) async {
    if (state.sending) {
      return;
    }
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.cancelLotteonLine(
        event.orderItemId, event.quantity, event.reasonCode, event.reasonText);
    if (emit.isDone) {
      return;
    }
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (cancel) => emit(state.copyWith(sending: false, sellerCancel: cancel)),
    );
  }

  /// A failed write → message (403 → [LotteonOrderActionState.forbidden]).
  void _emitFailure(Failure failure, Emitter<LotteonOrderActionState> emit) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    emit(state.copyWith(
      sending: false,
      forbidden: code == 403,
      errorMessage: code == 403 ? null : failure.message,
    ));
  }
}
