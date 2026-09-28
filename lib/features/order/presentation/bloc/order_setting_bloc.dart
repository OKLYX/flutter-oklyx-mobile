import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_setting_event.dart';
import 'order_setting_state.dart';

/// 주문관리 설정(기본 예약 발송 시각) BLoC (FEATURE_2609_75 / D4·D12).
class OrderSettingBloc extends Bloc<OrderSettingEvent, OrderSettingState> {
  final OrderUseCase useCase;

  OrderSettingBloc({required this.useCase})
      : super(const OrderSettingState.initial()) {
    on<OrderSettingRequested>(_onRequested);
    on<OrderSettingSaved>(_onSaved);
  }

  Future<void> _onRequested(
    OrderSettingRequested event,
    Emitter<OrderSettingState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, saved: false));
    final result = await useCase.getOrderSetting();
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        forbidden: _isForbidden(failure),
        errorMessage: '설정을 불러오지 못했습니다.',
      )),
      (s) => emit(state.copyWith(loading: false, setting: s)),
    );
  }

  Future<void> _onSaved(
    OrderSettingSaved event,
    Emitter<OrderSettingState> emit,
  ) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, clearError: true, saved: false));
    final result = await useCase.updateOrderSetting(event.reservedShipmentTime);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(state.copyWith(
        saving: false,
        forbidden: _isForbidden(failure),
        errorMessage: failure is ServerFailure && failure.statusCode == 400
            ? failure.message
            : '저장에 실패했습니다. 다시 시도해주세요.',
      )),
      (s) => emit(state.copyWith(saving: false, setting: s, saved: true)),
    );
  }

  bool _isForbidden(Failure failure) =>
      failure is ServerFailure && failure.statusCode == 403;
}
