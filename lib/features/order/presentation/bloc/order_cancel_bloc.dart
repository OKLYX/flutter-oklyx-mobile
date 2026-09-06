import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_cancel_event.dart';
import 'order_cancel_state.dart';

/// 발송 전 주문 취소 전용 BLoC (사유 목록 조회 + 전송).
///
/// **왜 별도 BLoC 인가**: 취소는 발주처리와 달리 **입력(사유·수량)이 있는 다른 작업**이다.
/// `OrderAcknowledgeBloc` 에 이벤트를 얹으면 결과 state 가 섞여 발주처리 표시가
/// 취소 결과에 오염된다(PLAN 2609_25).
///
/// **권한**: 클라이언트 role 게이트 없음(모바일에 role 판정이 없다). 403 을 받으면
/// `forbidden` 으로 표시하고 화면이 섹션을 숨긴다 — 서버 판정을 반영하는 것이라 이중 판정이
/// 아니다. **두 엔드포인트 모두 ADMIN 전용**이라 USER 는 사유 조회에서 먼저 403 을 받는다(D11).
///
/// ⚠️ 취소는 되돌릴 수 없고 쿠팡 판매자 점수가 하락한다 — 자동 재시도를 넣지 말 것(D13).
class OrderCancelBloc extends Bloc<OrderCancelEvent, OrderCancelState> {
  final OrderUseCase useCase;

  OrderCancelBloc({required this.useCase})
      : super(const OrderCancelState.initial()) {
    on<CancelReasonsRequested>(_onReasonsRequested);
    on<CancelRequested>(_onSubmit);
    on<CancelResultCleared>(_onResultCleared);
  }

  Future<void> _onReasonsRequested(
    CancelReasonsRequested event,
    Emitter<OrderCancelState> emit,
  ) async {
    if (state.loadingReasons) return;
    emit(state.copyWith(loadingReasons: true, reasonsFailed: false));

    final result = await useCase.getCancelReasons();
    if (emit.isDone) return; // 조회 중 화면을 벗어난 경우

    result.fold(
      (failure) {
        final code = failure is ServerFailure ? failure.statusCode : null;
        // 403 = ADMIN 아님 → 섹션 자체를 숨긴다(로드 실패 안내를 띄우면 거짓 안내다).
        // 그 외 실패는 [다시 시도] 버튼을 띄운다 — 기본 사유를 임의로 채우지 않는다(D4).
        emit(state.copyWith(
          loadingReasons: false,
          forbidden: code == 403,
          reasonsFailed: code != 403,
        ));
      },
      (reasons) => emit(state.copyWith(
        loadingReasons: false,
        reasonsFailed: false,
        reasons: reasons,
      )),
    );
  }

  Future<void> _onSubmit(
    CancelRequested event,
    Emitter<OrderCancelState> emit,
  ) async {
    // 중복 전송 차단 — 되돌릴 수 없는 작업이라 재진입을 막는다.
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearError: true, clearResult: true));

    final result = await useCase.cancelOrders(event.lines, event.reason);
    if (emit.isDone) return; // 전송 중 화면을 벗어난 경우

    result.fold(
      (failure) {
        final code = failure is ServerFailure ? failure.statusCode : null;
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
    CancelResultCleared event,
    Emitter<OrderCancelState> emit,
  ) {
    if (state.result == null && state.errorMessage == null) return;
    emit(state.copyWith(clearResult: true, clearError: true));
  }

  /// `OrderAcknowledgeBloc._errorMessage` 와 같은 매핑 — Dio 원문을 그대로 보여주지 않는다.
  /// 400 만 서버 본문 message 를 쓴다(수량 초과·빈 요청·라인 없음으로 사유가 여럿이다).
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 404) return '주문을 찾을 수 없습니다.';
    if (code == 400) return failure.message;
    return '주문 취소에 실패했습니다.';
  }
}
