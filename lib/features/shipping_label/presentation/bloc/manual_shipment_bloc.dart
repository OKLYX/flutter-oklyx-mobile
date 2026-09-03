import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import 'manual_shipment_event.dart';
import 'manual_shipment_state.dart';

/// 주문 상세 단건 발송처리 BLoC (택배사 선택 + 송장번호 직접 입력).
///
/// 전송 단위는 화면의 그 라인이 아니라 **그 라인이 속한 박스 전체**이고, 신규 업로드/송장수정
/// 모드 판정도 서버가 한다(PLAN 2609_11 D1·D3) — 여기서는 라벨과 화면 상태만 다룬다.
///
/// **권한**: 클라이언트 role 게이트 없음(모바일에 role 판정이 없다). 대신 택배사 조회가 403 이면
/// `optionsForbidden` 으로 섹션을 숨긴다 — 서버가 내린 판정을 반영하는 것이라 이중 판정이 아니다.
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

  // 송장시트 BLoC 의 헬퍼를 복사해 왔다(공용 유틸 추출 ❌ — 검증이 끝난 송장시트 경로를 건드리지 않는다).
  // ⚠️ 400 만 다르다: 이 경로는 사유가 여럿(비-쿠팡 주문 / 박스 ID 없음 / 택배사 코드 미등록)이라
  // 서버 본문 message 를 그대로 쓴다. 고정 문구로 덮으면 사용자가 조치할 정보를 잃는다.
  String _errorMessage(Failure failure, String fallback) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 404) return '주문을 찾을 수 없습니다.';
    if (code == 400) return failure.message;
    return fallback;
  }
}
