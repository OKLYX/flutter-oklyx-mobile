import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/usecases/sales_usecase.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/sales_summary_event.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/sales_summary_state.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/usecases/settlement_usecase.dart';

/// 「통합 매출 조회」 BLoC (FEATURE_2610_20 / D26) — the mobile twin of the web
/// `SalesSummaryContainer`.
///
/// - The seller summary and the packing savings are separate calls — a savings
///   failure keeps the sales rows.
/// - Opening a seller calls its channels and its payouts (recognition axis)
///   once each, side by side.
/// - Only the last request of each kind lands — an older answer that arrives
///   later is dropped.
class SalesSummaryBloc extends Bloc<SalesSummaryEvent, SalesSummaryState> {
  final SalesUseCase salesUseCase;
  final SettlementUseCase settlementUseCase;

  int _rowsRequest = 0;
  int _savingsRequest = 0;
  int _sellerRequest = 0;

  SalesSummaryBloc(
      {required this.salesUseCase, required this.settlementUseCase})
      : super(SalesSummaryState(
            from: currentMonthRange().from, to: currentMonthRange().to)) {
    on<SalesSummaryStarted>(_onLoad);
    on<SalesSummaryRetried>(_onLoad);
    on<SalesSummaryPeriodChanged>(_onPeriodChanged);
    on<SalesSellerToggled>(_onSellerToggled);
  }

  Future<void> _onPeriodChanged(
      SalesSummaryPeriodChanged event, Emitter<SalesSummaryState> emit) async {
    _sellerRequest++;
    emit(state.copyWith(
      from: event.from,
      to: event.to,
      clearExpanded: true,
      channels: const [],
      channelsError: '',
      payouts: const [],
      payoutsError: '',
    ));
    await _onLoad(event, emit);
  }

  Future<void> _onLoad(
      SalesSummaryEvent event, Emitter<SalesSummaryState> emit) async {
    if (state.from.isEmpty || state.to.isEmpty || state.invalidRange) {
      return;
    }
    await Future.wait([_loadRows(emit), _loadSavings(emit)]);
  }

  Future<void> _loadRows(Emitter<SalesSummaryState> emit) async {
    final request = ++_rowsRequest;
    emit(state.copyWith(loading: true, error: ''));
    final result =
        await salesUseCase.getSellerSummary(from: state.from, to: state.to);
    if (emit.isDone || request != _rowsRequest) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        forbidden: _statusOf(failure) == 403,
        error: '매출 조회에 실패했습니다.',
        rows: const [],
      )),
      (rows) => emit(state.copyWith(loading: false, rows: rows)),
    );
  }

  Future<void> _loadSavings(Emitter<SalesSummaryState> emit) async {
    final request = ++_savingsRequest;
    emit(state.copyWith(savingsLoading: true, savingsError: ''));
    final summaryCall =
        salesUseCase.getSavingsSummary(from: state.from, to: state.to);
    final boxesCall =
        salesUseCase.getBoxSavings(from: state.from, to: state.to);
    final summary = (await summaryCall).fold((_) => null, (value) => value);
    final boxes = (await boxesCall).fold((_) => null, (value) => value);
    if (emit.isDone || request != _savingsRequest) {
      return;
    }
    if (summary == null || boxes == null) {
      emit(state.copyWith(
        savingsLoading: false,
        savingsError: '포장 절약 조회에 실패했습니다.',
        clearSavings: true,
        boxSavings: const [],
      ));
      return;
    }
    emit(state.copyWith(
        savingsLoading: false, savings: summary, boxSavings: boxes));
  }

  Future<void> _onSellerToggled(
      SalesSellerToggled event, Emitter<SalesSummaryState> emit) async {
    final request = ++_sellerRequest;
    if (state.expandedSellerId == event.sellerId) {
      emit(state.copyWith(clearExpanded: true));
      return;
    }
    emit(state.copyWith(
      expandedSellerId: event.sellerId,
      channels: const [],
      channelsError: '',
      channelsLoading: true,
      payouts: const [],
      payoutsError: '',
      payoutsLoading: true,
    ));
    final channelsCall = salesUseCase.getChannelSales(
        from: state.from, to: state.to, sellerId: event.sellerId);
    final payoutsCall = settlementUseCase.getPayoutsByRecognition(
        from: state.from, to: state.to, sellerId: event.sellerId);
    final channels = (await channelsCall).fold((_) => null, (value) => value);
    final payouts = (await payoutsCall).fold((_) => null, (value) => value);
    if (emit.isDone || request != _sellerRequest) {
      return;
    }
    emit(state.copyWith(
      channelsLoading: false,
      channels: channels ?? const [],
      channelsError: channels == null ? '채널별 매출 조회에 실패했습니다.' : '',
      payoutsLoading: false,
      payouts: payouts ?? const [],
      payoutsError: payouts == null ? '정산 내역 조회에 실패했습니다.' : '',
    ));
  }

  static int? _statusOf(Failure failure) =>
      failure is ServerFailure ? failure.statusCode : null;
}
