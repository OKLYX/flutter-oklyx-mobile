import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import 'manual_shipment_event.dart';
import 'manual_shipment_state.dart';

/// Order-detail single shipment BLoC (carrier pick + invoice number typed in).
///
/// The send unit is **the whole box this line belongs to**, not the line on
/// screen, and the server also decides upload vs invoice edit (PLAN 2609_11
/// D1·D3) — this BLoC only handles labels and screen state. An 11st partial /
/// split send passes its chosen lines in `SubmitManualShipment.elevenst`
/// (FEATURE_2610_17 / D64).
///
/// **Permission**: no client role gate (mobile has no role check). A 403 on the
/// carrier lookup hides the section through `optionsForbidden` instead — that
/// reflects the server's decision, not a second one.
class ManualShipmentBloc extends Bloc<ManualShipmentEvent, ManualShipmentState> {
  final ShippingLabelUseCase useCase;

  ManualShipmentBloc({required this.useCase})
      : super(const ManualShipmentState.initial()) {
    on<LoadCarrierOptions>(_onLoadOptions);
    on<CarrierSelected>(_onCarrierSelected);
    on<SubmitManualShipment>(_onSubmit);
    on<SubmitErrorCleared>(_onSubmitErrorCleared);
  }

  Future<void> _onLoadOptions(
    LoadCarrierOptions event,
    Emitter<ManualShipmentState> emit,
  ) async {
    emit(state.copyWith(
      loadingOptions: true,
      optionsLoadFailed: false,
      optionsForbidden: false,
    ));

    final result = await useCase.getCarrierOptions(platform: event.platform);
    result.fold(
      (failure) {
        final code = failure is ServerFailure ? failure.statusCode : null;
        // 403 = ADMIN 아님 → 섹션 숨김. 그 외 실패는 섹션을 유지하고 '다시 시도' 를 제공한다.
        // errorMessage 는 전송 실패 전용이라 여기서 건드리지 않는다.
        emit(state.copyWith(
          loadingOptions: false,
          options: const [],
          optionsForbidden: code == 403,
          optionsLoadFailed: code != 403,
        ));
      },
      // 택배사가 하나뿐이어도 자동 선택하지 않는다 — 웹과 동작을 맞춘다
      // (사용자가 어느 택배사로 보내는지 명시적으로 고르게 한다).
      (options) => emit(state.copyWith(loadingOptions: false, options: options)),
    );
  }

  void _onCarrierSelected(
    CarrierSelected event,
    Emitter<ManualShipmentState> emit,
  ) {
    emit(state.copyWith(carrierCode: event.carrierCode));
  }

  Future<void> _onSubmit(
    SubmitManualShipment event,
    Emitter<ManualShipmentState> emit,
  ) async {
    final carrierCode = state.carrierCode;
    if (carrierCode == null || state.submitting) return;

    emit(state.copyWith(submitting: true, clearError: true));

    final result = await useCase.confirmManualShipment(
      orderItemId: event.orderItemId,
      deliveryCompanyCode: carrierCode,
      invoiceNumber: event.invoiceNumber,
      elevenst: event.elevenst,
    );
    result.fold(
      // 요청 자체가 실패 → result 를 채우지 않는다(입력을 다시 열어 재시도할 수 있어야 한다, D14).
      (failure) => emit(state.copyWith(
        submitting: false,
        errorMessage: _errorMessage(failure, '발송처리에 실패했습니다.'),
      )),
      // 부분실패(failed)도 200 이라 여기로 온다 → 입력을 잠근다(재전송 = 중복 송장).
      (manualResult) => emit(state.copyWith(
        submitting: false,
        result: manualResult,
      )),
    );
  }

  void _onSubmitErrorCleared(
    SubmitErrorCleared event,
    Emitter<ManualShipmentState> emit,
  ) {
    if (state.errorMessage == null) return;
    emit(state.copyWith(clearError: true));
  }

  // Helper copied from the shipping-sheet BLoC (no shared util ❌ — the
  // verified sheet path stays untouched).
  // ⚠️ Only 400 differs: this path has several reasons (not a Coupang · 11st
  // order / no box ID / carrier code not registered / 11st send-mode rules,
  // FEATURE_2610_17 / D64), so the server body message is used as is. A fixed
  // text would hide what the user can act on.
  String _errorMessage(Failure failure, String fallback) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 404) return '주문을 찾을 수 없습니다.';
    if (code == 400) return failure.message;
    return fallback;
  }
}
