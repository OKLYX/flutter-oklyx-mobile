import 'package:equatable/equatable.dart';

import '../../data/models/carrier_option.dart';
import '../../data/models/reserved_shipment_row.dart';
import '../../data/models/stored_invoice.dart';

/// 작업 1개. [storedInvoice] = 「송장」의 [송장 수정](busyId = 배송 묶음 id), 나머지는 현황 행 작업(busyId = 행 id).
enum ReservedAction { retry, time, invoice, cancel, storedInvoice }

/// 예약 발송 현황 상태 (FEATURE_2609_75 / D15·D16·D18·D30).
///
/// [externalOrderId] = 조회 범위(null = 전체 현황, 값 = 그 주문의 기록 + 「송장」). [busyId]·[busyAction] = 지금 보내는
/// 작업(한 번에 하나). [actionError]·[errorAction] = 마지막 작업 실패 문구(서버 문구 그대로)와 그 작업.
/// [carrierOptions] = [송장 수정] 택배사 목록(조회 실패면 빈 목록 → 버튼이 숨는다).
/// [storedInvoices] = 그 주문의 내부 단계 배송 묶음별 현재 송장(E14, D18). 전체 현황에서는 늘 빈 목록.
class ReservedShipmentState extends Equatable {
  final bool loading;
  final List<ReservedShipmentRow> rows;
  final List<CarrierOption> carrierOptions;
  final List<StoredInvoice> storedInvoices;
  final String? externalOrderId;
  final String? loadError;
  final bool forbidden;
  final int? busyId;
  final ReservedAction? busyAction;
  final String? actionError;
  final ReservedAction? errorAction;

  const ReservedShipmentState({
    required this.loading,
    required this.rows,
    required this.carrierOptions,
    required this.storedInvoices,
    required this.externalOrderId,
    required this.loadError,
    required this.forbidden,
    required this.busyId,
    required this.busyAction,
    required this.actionError,
    required this.errorAction,
  });

  const ReservedShipmentState.initial()
      : loading = true,
        rows = const [],
        carrierOptions = const [],
        storedInvoices = const [],
        externalOrderId = null,
        loadError = null,
        forbidden = false,
        busyId = null,
        busyAction = null,
        actionError = null,
        errorAction = null;

  /// ⚠️ nullable 필드를 비우는 건 **불리언 플래그**로만 한다.
  ReservedShipmentState copyWith({
    bool? loading,
    List<ReservedShipmentRow>? rows,
    List<CarrierOption>? carrierOptions,
    List<StoredInvoice>? storedInvoices,
    String? externalOrderId,
    String? loadError,
    bool? forbidden,
    int? busyId,
    ReservedAction? busyAction,
    String? actionError,
    ReservedAction? errorAction,
    bool clearLoadError = false,
    bool clearBusy = false,
    bool clearActionError = false,
  }) =>
      ReservedShipmentState(
        loading: loading ?? this.loading,
        rows: rows ?? this.rows,
        carrierOptions: carrierOptions ?? this.carrierOptions,
        storedInvoices: storedInvoices ?? this.storedInvoices,
        externalOrderId: externalOrderId ?? this.externalOrderId,
        loadError: clearLoadError ? null : (loadError ?? this.loadError),
        forbidden: forbidden ?? this.forbidden,
        busyId: clearBusy ? null : (busyId ?? this.busyId),
        busyAction: clearBusy ? null : (busyAction ?? this.busyAction),
        actionError:
            clearActionError ? null : (actionError ?? this.actionError),
        errorAction:
            clearActionError ? null : (errorAction ?? this.errorAction),
      );

  @override
  List<Object?> get props => [
        loading,
        rows,
        carrierOptions,
        storedInvoices,
        externalOrderId,
        loadError,
        forbidden,
        busyId,
        busyAction,
        actionError,
        errorAction,
      ];
}
