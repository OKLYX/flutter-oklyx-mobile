import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/usecases/dashboard_usecase.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_grid_spec.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_layout.dart';

/// Dashboard cards of the logged-in member (FEATURE_2610_29 / D2 · D3 · D6 ·
/// D11 · D16) — the web `DashboardHome` logic.
///
/// - Edit mode: move · resize · add · remove change [DashboardState.cards]
///   without saving; [DashboardEditFinished] saves and leaves edit mode when
///   it worked.
/// - Outside edit mode a period change is saved at once.
/// - A save answers with the stored cards, which replace the state.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardUseCase dashboardUseCase;

  DashboardBloc({required this.dashboardUseCase})
      : super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardEditStarted>(
        (event, emit) => emit(state.copyWith(editing: true)));
    on<DashboardCardMoved>((event, emit) => emit(state.copyWith(
        cards: moveCard(state.cards, event.dragged, event.target))));
    on<DashboardCardResized>(_onResized);
    on<DashboardCardAdded>(_onAdded);
    on<DashboardCardRemoved>((event, emit) => emit(state.copyWith(
        cards: state.cards.where((card) => card.type != event.type).toList())));
    on<DashboardEditFinished>(_onEditFinished);
    on<DashboardPeriodChanged>(_onPeriodChanged);
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
