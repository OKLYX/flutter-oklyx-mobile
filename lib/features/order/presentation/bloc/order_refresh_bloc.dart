import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/order_usecase.dart';
import 'order_refresh_event.dart';
import 'order_refresh_state.dart';

/// 주문 최신화(쿠팡 단건 조회 → 로컬 상태 갱신) 전용 BLoC (FEATURE_2609_50).
///
/// **선택 상태는 여기 두지 않는다** — 화면 로컬 state 다(D19). 이 BLoC 은
/// "보내는 중 / 결과 / 실패"만 안다.
///
/// 🔴 발주처리 BLoC 을 재사용하지 않는다(D20) — 결과 모델·분류가 다르고, 한 BLoC 에 두 작업을
/// 담으면 `submitting` 이 어느 쪽인지 화면이 구분하지 못한다.
///
/// 🔴 403 게이트가 없다(D18) — 최신화는 ADMIN 전용이 아니라 인증만 필요하다(D2).
class OrderRefreshBloc extends Bloc<OrderRefreshEvent, OrderRefreshState> {
  final OrderUseCase useCase;

  OrderRefreshBloc({required this.useCase})
      : super(const OrderRefreshState.initial()) {
    on<RefreshRequested>(_onSubmit);
    on<RefreshResultCleared>(_onResultCleared);
  }

  Future<void> _onSubmit(
    RefreshRequested event,
    Emitter<OrderRefreshState> emit,
  ) async {
    // 중복 전송 차단 — 되돌릴 수 없어서가 아니라 쿠팡 호출을 두 벌 쓰지 않기 위해서다(D21).
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearError: true, clearResult: true));

    final result = await useCase.refreshOrders(event.orderItemIds);
    // 50건이면 10초를 넘긴다 — 그 사이 화면을 벗어나기 쉽다.
    if (emit.isDone) return;

    result.fold(
      (failure) => emit(state.copyWith(
        submitting: false,
        errorMessage: _errorMessage(failure),
      )),
      // 부분 실패도 성공 경로다(응답이 왔다) — 실패 사유는 result.failed 로 화면이 편다.
      (r) => emit(state.copyWith(submitting: false, result: r)),
    );
  }

  void _onResultCleared(
    RefreshResultCleared event,
    Emitter<OrderRefreshState> emit,
  ) {
    if (state.result == null && state.errorMessage == null) return;
    emit(state.copyWith(clearResult: true, clearError: true));
  }

  /// Dio 원문("Http status error [500]")을 사용자에게 그대로 보여주지 않는다.
  /// 400 만 서버 본문 message 를 쓴다 — 50건 상한 판정이 서버에 있다(D3).
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 404) return '주문을 찾을 수 없습니다.';
    if (code == 400) return failure.message;
    return '최신화에 실패했습니다.';
  }
}
