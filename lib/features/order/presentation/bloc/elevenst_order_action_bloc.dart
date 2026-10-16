import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/order_usecase.dart';
import 'elevenst_order_action_event.dart';
import 'elevenst_order_action_state.dart';

/// The 11st order-detail writes (FEATURE_2610_17 / D19 · D35 · D36 · D37 · D38 ·
/// D61 ~ D67): open cancel requests + [취소 승인] · [취소 거부] ·
/// [책임사유 오류로 거부], the seller return request, sale refusal, the delay
/// notice, the partial / split line pickers, visit pickup and [입고완료 처리].
///
/// **Why one BLoC**: the writes live on the same 11st order detail and share
/// the 403 rule — one 403 hides every 11st write button.
///
/// ⚠️ Every write cannot be undone on 11st — no automatic retry, and the
/// screen confirms before approve, before 「신청하면서 바로 반품완료」 and
/// before every other irreversible write.
/// ⚠️ After approve / reject the list is read again — the request disappears
/// once 11st accepted it (status 02 / REJECTED on the server).
class ElevenstOrderActionBloc
    extends Bloc<ElevenstOrderActionEvent, ElevenstOrderActionState> {
  final OrderUseCase useCase;

  ElevenstOrderActionBloc({required this.useCase})
      : super(const ElevenstOrderActionState.initial()) {
    on<ElevenstCancelRequestsRequested>(_onLoadRequests);
    on<ElevenstCancelApproveRequested>(_onApprove);
    on<ElevenstCancelRejectRequested>(_onReject);
    on<ElevenstReturnReasonsRequested>(_onLoadReasons);
    on<ElevenstReturnRequested>(_onReturn);
    on<ElevenstActionErrorCleared>(
        (event, emit) => emit(state.copyWith(clearError: true)));
    on<ElevenstChoicesRequested>(_onLoadChoices);
    on<ElevenstSaleRefusalRequested>(_onSaleRefusal);
    on<ElevenstCancelFaultRejectRequested>(_onRejectFault);
    on<ElevenstDeliveryLinesRequested>(_onLoadDeliveryLines);
    on<ElevenstDeliveryDelayRequested>(_onDeliveryDelay);
    on<ElevenstVisitPickupRequested>(_onVisitPickup);
    on<ElevenstStockConfirmRequested>(_onStockConfirm);
  }

  Future<void> _onLoadRequests(
    ElevenstCancelRequestsRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    final result = await useCase.getElevenstCancelRequests(event.orderItemId);
    if (emit.isDone) return;
    result.fold(
      (_) => emit(state.copyWith(requestsFailed: true)),
      (requests) =>
          emit(state.copyWith(requests: requests, requestsFailed: false)),
    );
  }

  Future<void> _onApprove(
    ElevenstCancelApproveRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.approveElevenstCancel(event.requestId);
    if (emit.isDone) return;
    await _afterWrite(result, event.orderItemId, emit);
  }

  Future<void> _onReject(
    ElevenstCancelRejectRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.rejectElevenstCancel(
      event.requestId,
      deliveryCompanyCode: event.deliveryCompanyCode,
      invoiceNumber: event.invoiceNumber,
      sendDate: event.sendDate,
    );
    if (emit.isDone) return;
    await _afterWrite(result, event.orderItemId, emit);
  }

  /// Failure → message (403 → [forbidden]); success → read the list again.
  Future<void> _afterWrite(
    Either<Failure, Unit> result,
    int orderItemId,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      final code = failure is ServerFailure ? failure.statusCode : null;
      emit(state.copyWith(
        sending: false,
        forbidden: code == 403,
        errorMessage: code == 403 ? null : failure.message,
      ));
      return;
    }
    final reloaded = await useCase.getElevenstCancelRequests(orderItemId);
    if (emit.isDone) return;
    reloaded.fold(
      (_) => emit(state.copyWith(sending: false, requestsFailed: true)),
      (requests) => emit(state.copyWith(sending: false, requests: requests)),
    );
  }

  Future<void> _onLoadReasons(
    ElevenstReturnReasonsRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    final result = await useCase.getElevenstReturnReasons();
    if (emit.isDone) return;
    result.fold(
      (_) => emit(state.copyWith(reasonsFailed: true)),
      (reasons) => emit(state.copyWith(reasons: reasons, reasonsFailed: false)),
    );
  }

  Future<void> _onLoadChoices(
    ElevenstChoicesRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    final result = await useCase.getElevenstChoices();
    if (emit.isDone) return;
    result.fold(
      (_) => emit(state.copyWith(choicesFailed: true)),
      (choices) => emit(state.copyWith(choices: choices, choicesFailed: false)),
    );
  }

  Future<void> _onSaleRefusal(
    ElevenstSaleRefusalRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.cancelElevenstLine(
        event.orderItemId, event.quantity, event.reasonCode, event.reasonText);
    if (emit.isDone) return;
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (refusal) => emit(state.copyWith(sending: false, saleRefusal: refusal)),
    );
  }

  Future<void> _onRejectFault(
    ElevenstCancelFaultRejectRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result =
        await useCase.rejectElevenstCancelFault(event.requestId, event.body);
    if (emit.isDone) return;
    await _afterWrite(result, event.orderItemId, emit);
  }

  Future<void> _onLoadDeliveryLines(
    ElevenstDeliveryLinesRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    final result = await useCase.getElevenstDeliveryLines(event.orderItemId);
    if (emit.isDone) return;
    result.fold(
      (_) => emit(state.copyWith(deliveryLinesFailed: true)),
      (lines) => emit(
          state.copyWith(deliveryLines: lines, deliveryLinesFailed: false)),
    );
  }

  Future<void> _onDeliveryDelay(
    ElevenstDeliveryDelayRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, delaySent: false, clearError: true));
    final result =
        await useCase.sendElevenstDeliveryDelay(event.orderItemId, event.body);
    if (emit.isDone) return;
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (_) => emit(state.copyWith(sending: false, delaySent: true)),
    );
  }

  Future<void> _onVisitPickup(
    ElevenstVisitPickupRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending || state.visitPickupDone) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.completeElevenstVisitPickup(
        event.orderItemId, event.certCode);
    if (emit.isDone) return;
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (_) => emit(state.copyWith(sending: false, visitPickupDone: true)),
    );
  }

  Future<void> _onStockConfirm(
    ElevenstStockConfirmRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending || state.stockSent) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result = await useCase.confirmElevenstStock(event.orderItemId);
    if (emit.isDone) return;
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (_) => emit(state.copyWith(sending: false, stockSent: true)),
    );
  }

  /// A failed write → message (403 → [ElevenstOrderActionState.forbidden]).
  void _emitFailure(Failure failure, Emitter<ElevenstOrderActionState> emit) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    emit(state.copyWith(
      sending: false,
      forbidden: code == 403,
      errorMessage: code == 403 ? null : failure.message,
    ));
  }

  Future<void> _onReturn(
    ElevenstReturnRequested event,
    Emitter<ElevenstOrderActionState> emit,
  ) async {
    if (state.sending || state.returnSent) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result =
        await useCase.requestElevenstReturn(event.orderItemId, event.body);
    if (emit.isDone) return;
    result.fold(
      (failure) {
        final code = failure is ServerFailure ? failure.statusCode : null;
        emit(state.copyWith(
          sending: false,
          forbidden: code == 403,
          errorMessage: code == 403 ? null : failure.message,
        ));
      },
      (_) => emit(state.copyWith(sending: false, returnSent: true)),
    );
  }
}
