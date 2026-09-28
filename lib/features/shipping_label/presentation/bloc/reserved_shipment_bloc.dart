import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
import '../../data/models/stored_invoice.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import 'reserved_shipment_event.dart';
import 'reserved_shipment_state.dart';

/// 예약 발송 현황 BLoC (FEATURE_2609_75 / D15·D16·D18·D30).
///
/// **범위**: [ReservedShipmentsRequested.externalOrderId] 가 없으면 전체 현황(출고관리 > 예약 발송 현황),
/// 있으면 그 주문의 기록 + 「송장」(주문 상세 · 출고관리 [송장 수정] 시트). 작업이 성공하면 같은 범위를 다시 불러온다
/// — 응답 1건으로 고쳐 쓰지 않는다.
/// **권한**: 403 이면 [ReservedShipmentState.forbidden].
/// ❌ 판정을 서버와 다르게 만들지 않는다 — 버튼 노출만 가르고 거절은 서버 문구를 보인다.
class ReservedShipmentBloc
    extends Bloc<ReservedShipmentEvent, ReservedShipmentState> {
  final ShippingLabelUseCase useCase;

  /// [예약 취소]는 order 계층(E7)이다(Step 2).
  final OrderUseCase orderUseCase;

  ReservedShipmentBloc({required this.useCase, required this.orderUseCase})
      : super(const ReservedShipmentState.initial()) {
    on<ReservedShipmentsRequested>(_onLoad);
    on<ReservationRetryRequested>((e, emit) => _act(e.row.id,
        ReservedAction.retry, emit, () => useCase.retryReservation(e.row.id)));
    on<ReservationTimeChanged>((e, emit) => _act(e.row.id, ReservedAction.time,
        emit, () => useCase.changeReservationTime(e.row.id, e.executeAt)));
    on<ReservationInvoiceChanged>((e, emit) => _act(
        e.row.id,
        ReservedAction.invoice,
        emit,
        () => useCase.changeReservedInvoice(
              e.row.orderShipmentId,
              deliveryCompanyCode: e.deliveryCompanyCode,
              invoiceNumber: e.invoiceNumber,
            )));
    on<ReservationCancelRequested>((e, emit) => _act(
        e.row.id,
        ReservedAction.cancel,
        emit,
        () => orderUseCase.cancelReservedItems(e.row.orderItemIds)));
    on<StoredInvoiceChanged>((e, emit) => _act(
        e.invoice.orderShipmentId,
        ReservedAction.storedInvoice,
        emit,
        () => useCase.changeReservedInvoice(
              e.invoice.orderShipmentId,
              deliveryCompanyCode: e.deliveryCompanyCode,
              invoiceNumber: e.invoiceNumber,
            )));
  }

  Future<void> _onLoad(
    ReservedShipmentsRequested event,
    Emitter<ReservedShipmentState> emit,
  ) async {
    emit(state.copyWith(
      loading: true,
      externalOrderId: event.externalOrderId,
      clearLoadError: true,
    ));
    if (state.carrierOptions.isEmpty) {
      final options = await useCase.getCarrierOptions(platform: 'COUPANG');
      if (emit.isDone) return;
      options.fold((_) {}, (list) => emit(state.copyWith(carrierOptions: list)));
    }
    await _reload(emit);
  }

  Future<void> _reload(Emitter<ReservedShipmentState> emit) async {
    final scope = state.externalOrderId;
    if (scope != null) {
      // 「송장」(E14, D18) — 실패하면 빈 목록(섹션이 숨는다). 기록 조회와 따로 센다.
      final invoices = await useCase.getStoredInvoices(scope);
      if (emit.isDone) return;
      emit(state.copyWith(
          storedInvoices:
              invoices.fold((_) => const <StoredInvoice>[], (list) => list)));
    }
    final result = scope == null
        ? await useCase.getReservedShipments()
        : await useCase.getReservedShipmentsByOrder(scope);
    if (emit.isDone) return;
    result.fold(
      (failure) {
        final code = failure is ServerFailure ? failure.statusCode : null;
        emit(state.copyWith(
          loading: false,
          forbidden: code == 403,
          loadError: '예약 발송을 불러오지 못했습니다.',
        ));
      },
      (rows) =>
          emit(state.copyWith(loading: false, rows: rows, clearLoadError: true)),
    );
  }

  Future<void> _act(
    int rowId,
    ReservedAction action,
    Emitter<ReservedShipmentState> emit,
    Future<Either<Failure, Object>> Function() call,
  ) async {
    if (state.busyId != null) return;
    emit(state.copyWith(
        busyId: rowId, busyAction: action, clearActionError: true));
    final result = await call();
    if (emit.isDone) return;
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(
          clearBusy: true,
          actionError: _errorMessage(failure),
          errorAction: action));
      return;
    }
    await _reload(emit);
    if (emit.isDone) return;
    emit(state.copyWith(clearBusy: true));
  }

  /// 400 은 서버 문구 그대로(「지난 시각은 고를 수 없습니다」·「예약 발송이 처리 중인 주문이 있습니다…」 등).
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 400) return failure.message;
    return '처리에 실패했습니다. 다시 시도해주세요.';
  }
}
