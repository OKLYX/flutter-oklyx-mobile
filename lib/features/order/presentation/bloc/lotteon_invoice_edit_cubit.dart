import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../../shipping_label/data/models/manual_shipment_result.dart';
import '../../../shipping_label/domain/usecases/shipping_label_usecase.dart';
import '../../data/models/lotteon_invoice_records.dart';
import '../../domain/usecases/order_usecase.dart';

/// State of the LotteON 「송장 수정」 sheet (FEATURE_2611_23 / D19 ⑥ · R52).
class LotteonInvoiceEditState {
  /// The record list is loading (true until [LotteonInvoiceEditCubit.open]
  /// ends).
  final bool loading;

  /// The record list failed — the server text (null = loaded).
  final String? loadError;

  /// One block per product line of the delivery (D19 ⑥-1).
  final List<LotteonInvoiceRecords> lines;

  /// Checked records — key = '$orderItemId:$procSeq' (D19 ⑥-3).
  final Set<String> checked;

  /// The picked LotteON carrier code.
  final String? carrierCode;

  /// The new invoice as typed.
  final String invoiceNumber;

  /// The update request is running.
  final bool submitting;

  /// The update request itself failed — red text in the sheet, not locked.
  final String? submitError;

  /// The 200 answer — the inputs lock and every record row shows its
  /// outcome (D19 ⑥-7).
  final ManualShipmentResult? result;

  const LotteonInvoiceEditState({
    this.loading = true,
    this.loadError,
    this.lines = const [],
    this.checked = const {},
    this.carrierCode,
    this.invoiceNumber = '',
    this.submitting = false,
    this.submitError,
    this.result,
  });

  /// No more input — sending, or a 200 already came back.
  bool get locked => submitting || result != null;

  /// [수정] is on — one checked record + a carrier + a new invoice, not
  /// locked (R52).
  bool get canSubmit =>
      checked.isNotEmpty &&
      carrierCode != null &&
      invoiceNumber.trim().isNotEmpty &&
      !locked;

  /// The outcome of one record in [result], null when it was not sent.
  ManualShipmentRecordOutcome? outcomeOf(int orderItemId, String procSeq) {
    for (final outcome in result?.records ?? const []) {
      if (outcome.orderItemId == orderItemId && outcome.procSeq == procSeq) {
        return outcome;
      }
    }
    return null;
  }

  LotteonInvoiceEditState copyWith({
    bool? loading,
    String? loadError,
    List<LotteonInvoiceRecords>? lines,
    Set<String>? checked,
    String? carrierCode,
    String? invoiceNumber,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    ManualShipmentResult? result,
  }) =>
      LotteonInvoiceEditState(
        loading: loading ?? this.loading,
        loadError: loadError ?? this.loadError,
        lines: lines ?? this.lines,
        checked: checked ?? this.checked,
        carrierCode: carrierCode ?? this.carrierCode,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        submitting: submitting ?? this.submitting,
        submitError:
            clearSubmitError ? null : (submitError ?? this.submitError),
        result: result ?? this.result,
      );
}

/// Cubit of the LotteON 「송장 수정」 sheet (FEATURE_2611_23 / D19 ⑥ · R52).
///
/// **Purpose**: loads the LotteON records of the delivery, keeps the picks and
/// sends one update with the picked records.
/// **File**:
/// lib/features/order/presentation/bloc/lotteon_invoice_edit_cubit.dart
///
/// - [open] checks every pickable record (D19 ⑥-8).
/// - A 200 locks the inputs; the sheet stays open with the outcome per record.
/// - A failed request keeps the inputs open with a red text (400 = the server
///   text).
/// ⚠️ GetIt factory — a new one for every sheet (R57).
class LotteonInvoiceEditCubit extends Cubit<LotteonInvoiceEditState> {
  final OrderUseCase orderUseCase;
  final ShippingLabelUseCase shippingLabelUseCase;

  LotteonInvoiceEditCubit({
    required this.orderUseCase,
    required this.shippingLabelUseCase,
  }) : super(const LotteonInvoiceEditState());

  static String _key(int orderItemId, String procSeq) =>
      '$orderItemId:$procSeq';

  /// Loads the records of the delivery of [orderItemId].
  Future<void> open(int orderItemId) async {
    final result = await orderUseCase.getLotteonInvoiceRecords(orderItemId);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        loadError:
            failure.message.isEmpty ? '발송 기록을 불러오지 못했습니다.' : failure.message,
      )),
      (lines) => emit(state.copyWith(
        loading: false,
        lines: lines,
        checked: {
          for (final line in lines)
            for (final record in line.records)
              if (record.pickable) _key(line.orderItemId, record.procSeq),
        },
      )),
    );
  }

  /// Checks / unchecks one record — ignored when locked or not pickable.
  void toggle(int orderItemId, String procSeq) {
    if (state.locked) {
      return;
    }
    final pickable = state.lines.any((line) =>
        line.orderItemId == orderItemId &&
        line.records.any((r) => r.procSeq == procSeq && r.pickable));
    if (!pickable) {
      return;
    }
    final key = _key(orderItemId, procSeq);
    final checked = Set<String>.of(state.checked);
    if (!checked.remove(key)) {
      checked.add(key);
    }
    emit(state.copyWith(checked: checked));
  }

  /// The carrier was picked.
  void selectCarrier(String code) {
    if (state.locked) {
      return;
    }
    emit(state.copyWith(carrierCode: code));
  }

  /// The new invoice was typed.
  void setInvoiceNumber(String value) {
    if (state.locked) {
      return;
    }
    emit(state.copyWith(invoiceNumber: value));
  }

  /// [수정] — sends the checked records with the carrier and the new invoice.
  Future<void> submit(int orderItemId) async {
    if (!state.canSubmit) {
      return;
    }
    final records = [
      for (final line in state.lines)
        for (final record in line.records)
          if (state.checked.contains(_key(line.orderItemId, record.procSeq)))
            {'orderItemId': line.orderItemId, 'procSeq': record.procSeq},
    ];
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    final result = await shippingLabelUseCase.confirmManualShipment(
      orderItemId: orderItemId,
      deliveryCompanyCode: state.carrierCode!,
      invoiceNumber: state.invoiceNumber.trim(),
      lotteonRecords: records,
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        submitting: false,
        submitError: failure is ServerFailure && failure.statusCode == 400
            ? failure.message
            : '송장 수정에 실패했습니다. 다시 시도해주세요.',
      )),
      (done) => emit(state.copyWith(submitting: false, result: done)),
    );
  }
}
