import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/internal_stage_result.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_internal_stage_event.dart';
import 'order_internal_stage_state.dart';

/// 내부 발주처리·해제 전송 전용 BLoC (FEATURE_2609_75 / D1·D13·D18).
///
/// 🔴 쿠팡에 보내지 않는다 — 우리 DB 의 내부 단계만 바꾼다. 발주처리 BLoC 을 재사용하지 않는다
/// (결과 모델이 다르고, 한 BLoC 에 담으면 `submitting` 이 어느 쪽인지 화면이 구분하지 못한다).
/// **권한**: 403 이면 [OrderInternalStageState.forbidden] — 화면이 진입점을 숨긴다.
class OrderInternalStageBloc
    extends Bloc<OrderInternalStageEvent, OrderInternalStageState> {
  final OrderUseCase useCase;

  OrderInternalStageBloc({required this.useCase})
      : super(const OrderInternalStageState.initial()) {
    on<InternalStageRequested>(_onSubmit);
    on<InternalStageResultCleared>(_onResultCleared);
  }

  Future<void> _onSubmit(
    InternalStageRequested event,
    Emitter<OrderInternalStageState> emit,
  ) async {
    if (state.submitting != null) return;
    emit(state.copyWith(
        submitting: event.action, clearError: true, clearResult: true));

    final result = await _send(event);
    if (emit.isDone) return;

    result.fold(
      (failure) {
        final code = failure is ServerFailure ? failure.statusCode : null;
        emit(state.copyWith(
          clearSubmitting: true,
          forbidden: code == 403,
          clearError: code == 403,
          errorMessage: code == 403 ? null : _errorMessage(failure),
        ));
      },
      (r) => emit(state.copyWith(
          clearSubmitting: true, lastAction: event.action, result: r)),
    );
  }

  Future<Either<Failure, InternalStageResult>> _send(
      InternalStageRequested event) {
    switch (event.action) {
      case InternalStageAction.mark:
        return useCase.markInternal(event.orderItemIds);
      case InternalStageAction.release:
        return useCase.releaseInternal(event.orderItemIds);
      case InternalStageAction.cancel:
        return useCase.cancelReservedItems(event.orderItemIds);
    }
  }

  void _onResultCleared(
    InternalStageResultCleared event,
    Emitter<OrderInternalStageState> emit,
  ) {
    if (state.result == null && state.errorMessage == null) return;
    emit(state.copyWith(clearResult: true, clearError: true));
  }

  /// 400 은 서버 문구를 그대로 쓴다(「처리 중」 등). 그 외는 고정 문구.
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 400) return failure.message;
    return '처리에 실패했습니다. 다시 시도해주세요.';
  }
}
