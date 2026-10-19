import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/usecases/sales_usecase.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/product_profit_event.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/product_profit_state.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';

/// 「상품별 매출」 BLoC (FEATURE_2610_20 / D26) — the mobile twin of the web
/// `ProductProfitContainer`.
///
/// - Option savings are a separate call without `crossChannel` (packing has no
///   channel); a failure leaves the savings column `—` and keeps the product
///   rows.
/// - Sorting is done on screen ([ProductProfitState.sortedRows]); the server
///   order is not relied on.
class ProductProfitBloc extends Bloc<ProductProfitEvent, ProductProfitState> {
  final SalesUseCase salesUseCase;
  final GetSellersUseCase getSellersUseCase;

  int _rowsRequest = 0;
  int _savingsRequest = 0;

  ProductProfitBloc(
      {required this.salesUseCase, required this.getSellersUseCase})
      : super(ProductProfitState(
            from: currentMonthRange().from, to: currentMonthRange().to)) {
    on<ProductProfitStarted>(_onStarted);
    on<ProductProfitRetried>(_onLoad);
    on<ProductProfitPeriodChanged>((event, emit) async {
      emit(state.copyWith(from: event.from, to: event.to, clearExpanded: true));
      await _onLoad(event, emit);
    });
    on<ProductProfitSellerChanged>((event, emit) async {
      emit(state.copyWith(
          sellerId: event.sellerId, clearSeller: event.sellerId == null));
      await _onLoad(event, emit);
    });
    on<ProductProfitCrossChannelChanged>((event, emit) async {
      emit(state.copyWith(
          crossChannel: event.crossChannel, clearExpanded: true));
      await _loadRows(emit);
    });
    on<ProductProfitSortChanged>(_onSortChanged);
    on<ProductProfitSavingsToggled>((event, emit) => emit(
        state.expandedSavingsMasterId == event.masterProductId
            ? state.copyWith(clearExpanded: true)
            : state.copyWith(expandedSavingsMasterId: event.masterProductId)));
  }

  Future<void> _onStarted(
      ProductProfitStarted event, Emitter<ProductProfitState> emit) async {
    // A seller failure leaves the chip at 「전체」 only — the rows still load.
    final sellers =
        (await getSellersUseCase()).fold((_) => <Seller>[], (list) => list);
    if (emit.isDone) {
      return;
    }
    emit(state.copyWith(sellers: sellers));
    await _onLoad(event, emit);
  }

  Future<void> _onLoad(
      ProductProfitEvent event, Emitter<ProductProfitState> emit) async {
    if (state.from.isEmpty || state.to.isEmpty || state.invalidRange) {
      return;
    }
    await Future.wait([_loadRows(emit), _loadSavings(emit)]);
  }

  void _onSortChanged(
      ProductProfitSortChanged event, Emitter<ProductProfitState> emit) {
    if (state.sortKey == event.key) {
      emit(state.copyWith(sortDescending: !state.sortDescending));
      return;
    }
    emit(state.copyWith(sortKey: event.key, sortDescending: true));
  }

  Future<void> _loadRows(Emitter<ProductProfitState> emit) async {
    final request = ++_rowsRequest;
    emit(state.copyWith(loading: true, error: ''));
    final result = await salesUseCase.getProductProfit(
      from: state.from,
      to: state.to,
      crossChannel: state.crossChannel,
      sellerId: state.sellerId,
    );
    if (emit.isDone || request != _rowsRequest) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        forbidden: failure is ServerFailure && failure.statusCode == 403,
        error: '상품별 매출 조회에 실패했습니다.',
        rows: const [],
      )),
      (rows) => emit(state.copyWith(loading: false, rows: rows)),
    );
  }

  Future<void> _loadSavings(Emitter<ProductProfitState> emit) async {
    final request = ++_savingsRequest;
    final result = await salesUseCase.getOptionSavings(
        from: state.from, to: state.to, sellerId: state.sellerId);
    if (emit.isDone || request != _savingsRequest) {
      return;
    }
    emit(state.copyWith(
        optionSavings: result.fold((_) => const [], (rows) => rows)));
  }
}
