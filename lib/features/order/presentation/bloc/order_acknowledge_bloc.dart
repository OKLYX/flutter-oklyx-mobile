import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_acknowledge_event.dart';
import 'order_acknowledge_state.dart';

/// 발주처리(결제완료 → 상품준비중) 전송 전용 BLoC.
///
/// **선택 상태는 여기 두지 않는다** — 화면 로컬 state 다(출고관리 채널 필터와 같은 판단,
/// 2609_15 D3). 이 BLoC 은 "보내는 중 / 결과 / 실패"만 안다.
///
/// **권한**: 클라이언트 role 게이트 없음(모바일에 role 판정이 없다). 403 응답을 받으면
/// [OrderAcknowledgeState.forbidden] 으로 표시하고 화면이 진입점을 숨긴다 —
/// 서버 판정을 반영하는 것이라 이중 판정이 아니다.
///
/// ⚠️ 발주처리는 되돌릴 수 없다 — 자동 재시도를 넣지 말 것(PLAN 2609_17 D15).
class OrderAcknowledgeBloc
    extends Bloc<OrderAcknowledgeEvent, OrderAcknowledgeState> {
  final OrderUseCase useCase;

  OrderAcknowledgeBloc({required this.useCase})
      : super(const OrderAcknowledgeState.initial()) {
    on<AcknowledgeRequested>(_onSubmit);
    on<AcknowledgeResultCleared>(_onResultCleared);
  }

  Future<void> _onSubmit(
    AcknowledgeRequested event,
    Emitter<OrderAcknowledgeState> emit,
  ) async {
    // 중복 전송 차단 — 되돌릴 수 없는 작업이라 재진입을 막는다.
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearError: true, clearResult: true));

    final result = await useCase.acknowledgeOrders(event.orderItemIds);
    if (emit.isDone) return; // 전송 중 화면을 벗어난 경우

    result.fold(
      (failure) {
        final code = failure is ServerFailure ? failure.statusCode : null;
        // 403 = ADMIN 아님 → 화면이 진입점을 숨긴다. 그 외는 메시지만(선택은 화면이 유지한다).
        emit(state.copyWith(
          submitting: false,
          forbidden: code == 403,
          clearError: code == 403,
          errorMessage: code == 403 ? null : _errorMessage(failure),
        ));
      },
      // 부분 실패도 성공 경로다(응답이 왔다) — 실패 사유는 result.failed 로 화면이 편다.
      (r) => emit(state.copyWith(submitting: false, result: r)),
    );
  }

  void _onResultCleared(
    AcknowledgeResultCleared event,
    Emitter<OrderAcknowledgeState> emit,
  ) {
    if (state.result == null && state.errorMessage == null) return;
    emit(state.copyWith(clearResult: true, clearError: true));
  }

  /// `ManualShipmentBloc._errorMessage` 와 같은 매핑 — Dio 원문("Http status error [500]")을
  /// 사용자에게 그대로 보여주지 않는다. 400 만 서버 본문 message 를 쓴다(사유가 여럿이다).
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 404) return '주문을 찾을 수 없습니다.';
    if (code == 400) return failure.message;
    return '발주처리에 실패했습니다.';
  }
}
