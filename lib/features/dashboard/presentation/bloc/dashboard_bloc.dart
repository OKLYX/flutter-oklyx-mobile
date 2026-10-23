import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/usecases/dashboard_usecase.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_grid_spec.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_layout.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';

/// Dashboard cards of the logged-in member (FEATURE_2610_29 / D2 · D3 · D6 ·
/// D11 · D16) — the web `DashboardHome` logic.
///
/// - Edit mode: move · resize · add · remove change [DashboardState.cards]
///   without saving; [DashboardEditFinished] saves and leaves edit mode when
///   it worked.
/// - Outside edit mode a period change is saved at once.
/// - A save answers with the stored cards, which replace the state.
/// - An admin's entry also reads the seller list of the chart cards once
///   (FEATURE_2610_30 / D37); a seller picked on a chart card stays in this
///   state and is not saved (D36).
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardUseCase dashboardUseCase;
  final GetSellersUseCase getSellersUseCase;

  DashboardBloc(
      {required this.dashboardUseCase, required this.getSellersUseCase})
      : super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardEditStarted>(
        (event, emit) => emit(state.copyWith(editing: true)));
    on<DashboardCardMoved>((event, emit) => emit(state.copyWith(
        cards: moveCard(state.cards, event.dragged, event.target))));
    on<DashboardCardResized>(_onResized);
    on<DashboardCardAdded>(_onAdded);
    on<DashboardCardRemoved>((event, emit) => emit(state.copyWith(
          cards: state.cards.where((card) => card.type != event.type).toList(),
          chartSellers: Map<DashboardCardType, int>.of(state.chartSellers)
            ..remove(event.type),
        )));
    on<DashboardEditFinished>(_onEditFinished);
    on<DashboardPeriodChanged>(_onPeriodChanged);
    on<DashboardChartSellerChanged>(_onChartSellerChanged);
  }

  Future<void> _onStarted(
      DashboardStarted event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    final result = await dashboardUseCase.getLayout();
    emit(result.fold(
      (_) => state.copyWith(status: DashboardStatus.error),
      (layout) => state.copyWith(
        status: DashboardStatus.ready,
        admin: layout.admin,
        cards: toMobileCards(layout),
      ),
    ));
    if (state.status != DashboardStatus.ready || !state.admin) {
      return;
    }
    // After a failure the selectors offer 「전체」 alone; the cards stay.
    final sellers =
        (await getSellersUseCase()).fold((_) => <Seller>[], (list) => list);
    if (emit.isDone) {
      return;
    }
    emit(state.copyWith(sellers: sellers));
  }

  void _onChartSellerChanged(
      DashboardChartSellerChanged event, Emitter<DashboardState> emit) {
    final sellerId = event.sellerId;
    final chartSellers = Map<DashboardCardType, int>.of(state.chartSellers);
    if (sellerId == null) {
      chartSellers.remove(event.type);
    } else {
      chartSellers[event.type] = sellerId;
    }
    emit(state.copyWith(chartSellers: chartSellers));
  }

  void _onResized(DashboardCardResized event, Emitter<DashboardState> emit) {
    if (!allowedWidths(event.type).contains(event.width)) {
      return;
    }
    emit(state.copyWith(
      cards: state.cards
          .map((card) => card.type == event.type
              ? card.copyWith(width: event.width)
              : card)
          .toList(),
    ));
  }

  void _onAdded(DashboardCardAdded event, Emitter<DashboardState> emit) {
    if (state.cards.any((card) => card.type == event.type)) {
      return;
    }
    emit(state.copyWith(cards: [...state.cards, newCard(event.type)]));
  }

  Future<void> _onEditFinished(
      DashboardEditFinished event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(saving: true));
    final saved = await _save(state.cards, emit, announce: true);
    emit(state.copyWith(saving: false, editing: !saved));
  }

  Future<void> _onPeriodChanged(
      DashboardPeriodChanged event, Emitter<DashboardState> emit) async {
    final cards = state.cards
        .map((card) => card.type == event.type
            ? card.copyWith(period: event.period)
            : card)
        .toList();
    emit(state.copyWith(cards: cards));
    await _save(cards, emit, announce: false);
  }

  /// Saves [cards]; true when the server took them. A failure bumps
  /// `saveVersion` (error toast); a success bumps it when [announce]
  /// (success toast after [편집 완료], none after a period change).
  Future<bool> _save(List<MobileCard> cards, Emitter<DashboardState> emit,
      {required bool announce}) async {
    final result =
        await dashboardUseCase.saveMobileLayout(toMobileRequest(cards));
    return result.fold(
      (failure) {
        emit(state.copyWith(
          saveVersion: state.saveVersion + 1,
          saveResult: DashboardSaveResult.failed,
          saveMessage: failure.message.trim().isNotEmpty
              ? failure.message
              : '대시보드를 저장하지 못했습니다.',
        ));
        return false;
      },
      (layout) {
        emit(state.copyWith(
          admin: layout.admin,
          cards: toMobileCards(layout),
          saveVersion: announce ? state.saveVersion + 1 : state.saveVersion,
          saveResult: announce ? DashboardSaveResult.saved : state.saveResult,
          saveMessage: '',
        ));
        return true;
      },
    );
  }
}
