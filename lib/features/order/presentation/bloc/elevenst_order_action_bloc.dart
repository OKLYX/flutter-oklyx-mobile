import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/order_usecase.dart';
import 'elevenst_order_action_event.dart';
import 'elevenst_order_action_state.dart';

/// The 11st order-detail writes (FEATURE_2610_17 / D19 · D35 · D36 · D37 · D38):
/// open cancel requests + [취소 승인] · [취소 거부], and the seller return request.
///
/// **Why one BLoC**: the three writes live on the same 11st order detail and
/// share the 403 rule — one 403 hides every 11st write button.
///
/// ⚠️ Every write cannot be undone on 11st — no automatic retry, and the
/// screen confirms before approve and before 「신청하면서 바로 반품완료」.
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
