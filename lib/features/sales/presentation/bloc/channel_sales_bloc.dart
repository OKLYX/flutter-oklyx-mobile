import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/usecases/sales_usecase.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/channel_sales_event.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/channel_sales_state.dart';

/// 「채널별 매출」 BLoC (FEATURE_2610_20 / D26) — the mobile twin of the web
/// `ChannelSalesContainer`.
///
/// - Entry values (period · channel) come from the route query when opened from
///   「통합 매출 조회」.
/// - No channel given, or one not in the list → the first channel (never an
///   empty screen).
/// - Changing the channel calls the order lines only; the period calls
///   everything again.
class ChannelSalesBloc extends Bloc<ChannelSalesEvent, ChannelSalesState> {
  final SalesUseCase salesUseCase;

  int _channelsRequest = 0;
  int _recordsRequest = 0;

  ChannelSalesBloc(
      {required this.salesUseCase, required ChannelSalesState initial})
      : super(initial) {
    on<ChannelSalesStarted>(_onLoad);
    on<ChannelSalesRetried>(_onLoad);
    on<ChannelSalesPeriodChanged>(_onPeriodChanged);
    on<ChannelSalesChannelChanged>(_onChannelChanged);
    on<ChannelSalesHideCanceledChanged>(
        (event, emit) => emit(state.copyWith(hideCanceled: event.hide)));
    on<ChannelSalesHidePendingChanged>(
        (event, emit) => emit(state.copyWith(hidePending: event.hide)));
  }

  Future<void> _onPeriodChanged(
      ChannelSalesPeriodChanged event, Emitter<ChannelSalesState> emit) async {
    emit(state.copyWith(from: event.from, to: event.to));
    await _onLoad(event, emit);
  }

  Future<void> _onChannelChanged(
      ChannelSalesChannelChanged event, Emitter<ChannelSalesState> emit) async {
    emit(state.copyWith(accountId: event.accountId));
    await _loadRecords(emit);
  }

  Future<void> _onLoad(
      ChannelSalesEvent event, Emitter<ChannelSalesState> emit) async {
    if (state.from.isEmpty || state.to.isEmpty || state.invalidRange) {
      return;
    }
    final request = ++_channelsRequest;
    emit(state.copyWith(
        loading: true, productsLoading: true, error: '', productsError: ''));
    final channelsCall =
        salesUseCase.getChannelSales(from: state.from, to: state.to);
    final productsCall = salesUseCase.getProductProfit(
        from: state.from, to: state.to, crossChannel: false);
    final channelsResult = await channelsCall;
    final productsResult = await productsCall;
    if (emit.isDone || request != _channelsRequest) {
      return;
    }
    final products = productsResult.fold((_) => null, (value) => value);
    emit(state.copyWith(
      productsLoading: false,
      products: products ?? const [],
      productsError: products == null ? '상품별 매출 조회에 실패했습니다.' : '',
    ));
    channelsResult.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        forbidden: failure is ServerFailure && failure.statusCode == 403,
        error: '채널별 매출 조회에 실패했습니다.',
        channels: const [],
      )),
      (channels) {
        final keep = channels.any((c) => c.accountId == state.accountId);
        final first = channels.isEmpty ? null : channels.first.accountId;
        emit(state.copyWith(
          loading: false,
          channels: channels,
          accountId: keep ? state.accountId : first,
          clearAccount: !keep && first == null,
        ));
      },
    );
    await _loadRecords(emit);
  }

  Future<void> _loadRecords(Emitter<ChannelSalesState> emit) async {
    final accountId = state.accountId;
    if (accountId == null || state.invalidRange) {
      emit(state.copyWith(records: const []));
      return;
    }
    final request = ++_recordsRequest;
    emit(state.copyWith(recordsLoading: true, recordsError: ''));
    final result = await salesUseCase.getSalesLines(
        from: state.from, to: state.to, accountId: accountId);
    if (emit.isDone || request != _recordsRequest) {
      return;
    }
    result.fold(
      (_) => emit(state.copyWith(
          recordsLoading: false,
          records: const [],
          recordsError: '판매 내역 조회에 실패했습니다.')),
      (records) =>
          emit(state.copyWith(recordsLoading: false, records: records)),
    );
  }
}
