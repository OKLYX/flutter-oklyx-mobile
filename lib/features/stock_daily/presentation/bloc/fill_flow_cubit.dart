import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stock_fill.dart';
import '../../domain/usecases/fill_outbound_usecase.dart';
import '../../domain/usecases/get_fill_candidates_usecase.dart';

/// One row's check and count in a 「채울까요?」 sheet (FEATURE_2611_22 D23).
class FillDraft {
  final bool checked;

  /// 「채울 개수」 as typed.
  final String quantity;

  const FillDraft({required this.checked, required this.quantity});
}

/// State of the 「채울까요?」 sheets (FEATURE_2611_22 D3 ① · D31 · D39).
class FillFlowState {
  /// One sheet per product, in save order.
  final List<FillCandidate> windows;

  /// The sheet shown.
  final int index;

  /// `{lotId}:{movementId}` → the row's check and count in that lot's part.
  final Map<String, FillDraft> drafts;

  final bool busy;

  /// Error text inside the sheet, blank when none.
  final String error;

  /// The load failed — the caller shows it as a toast; blank when none.
  final String loadError;

  /// Every sheet is done — the sheet closes.
  final bool done;

  const FillFlowState({
    this.windows = const [],
    this.index = 0,
    this.drafts = const {},
    this.busy = false,
    this.error = '',
    this.loadError = '',
    this.done = false,
  });

  FillCandidate? get current => index < windows.length ? windows[index] : null;

  FillFlowState copyWith({
    List<FillCandidate>? windows,
    int? index,
    Map<String, FillDraft>? drafts,
    bool? busy,
    String? error,
    String? loadError,
    bool? done,
  }) =>
      FillFlowState(
        windows: windows ?? this.windows,
        index: index ?? this.index,
        drafts: drafts ?? this.drafts,
        busy: busy ?? this.busy,
        error: error ?? this.error,
        loadError: loadError ?? this.loadError,
        done: done ?? this.done,
      );
}

/// The key of one row in one lot's part of a sheet.
String fillDraftKey(int lotId, int movementId) => '$lotId:$movementId';

/// Cubit of the 「채울까요?」 sheets after an intake save (FEATURE_2611_22 D3 ① ·
/// D19 · D23 · D31 · D32 · D39).
///
/// **Purpose**: the product sheets of one save, one after another.
/// **File**: lib/features/stock_daily/presentation/bloc/fill_flow_cubit.dart
///
/// - The checks and counts start as the server sent them (D23 · D32);
///   checking a row starts its count at its empty pieces.
/// - [채우기] saves the shown product only; a refusal keeps the sheet with the
///   server text, a success shows the next product. [건너뛰기] shows the next
///   product. After the last one [FillFlowState.done] is set.
/// ⚠️ GetIt factory — a new one for every save (`showFillFlow`).
class FillFlowCubit extends Cubit<FillFlowState> {
  final GetFillCandidatesUseCase getFillCandidatesUseCase;
  final FillOutboundUseCase fillOutboundUseCase;

  FillFlowCubit({
    required this.getFillCandidatesUseCase,
    required this.fillOutboundUseCase,
  }) : super(const FillFlowState());

  /// Loads the sheets of the saved lots [lotIds].
  Future<void> load(List<int> lotIds) async {
    final result = await getFillCandidatesUseCase(lotIds);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(loadError: failure.message)),
      (windows) => emit(FillFlowState(
        windows: windows,
        drafts: windows.isEmpty ? const {} : _initialDrafts(windows.first),
      )),
    );
  }

  /// A row's check of one lot's part changed.
  void toggle(int lotId, FillRow row, {required bool checked}) {
    if (state.busy) {
      return;
    }
    final key = fillDraftKey(lotId, row.movementId);
    final now = state.drafts[key];
    emit(state.copyWith(drafts: {
      ...state.drafts,
      key: FillDraft(
        checked: checked,
        quantity: checked ? '${row.emptyQuantity}' : (now?.quantity ?? ''),
      ),
    }));
  }

  /// A row's 「채울 개수」 was typed.
  void setQuantity(int lotId, int movementId, String quantity) {
    final key = fillDraftKey(lotId, movementId);
    final now = state.drafts[key];
    if (state.busy || now == null) {
      return;
    }
    emit(state.copyWith(drafts: {
      ...state.drafts,
      key: FillDraft(checked: now.checked, quantity: quantity),
    }));
  }

  /// [건너뛰기]: the next product, or done after the last one.
  void skip() {
    if (state.busy) {
      return;
    }
    _next();
  }

  /// [채우기] of the shown product.
  Future<void> submit() async {
    final window = state.current;
    if (state.busy || window == null) {
      return;
    }
    final fills = <FillRequestLot>[];
    for (final lot in window.lots) {
      final lines = <FillRequestLine>[];
      for (final row in lot.rows) {
        final draft = state.drafts[fillDraftKey(lot.lotId, row.movementId)];
        if (draft == null || !draft.checked) {
          continue;
        }
        lines.add(FillRequestLine(
          movementId: row.movementId,
          quantity: int.tryParse(draft.quantity.trim()) ?? 0,
        ));
      }
      if (lines.isNotEmpty) {
        fills.add(FillRequestLot(lotId: lot.lotId, lines: lines));
      }
    }
    emit(state.copyWith(busy: true, error: ''));
    final result = await fillOutboundUseCase(fills);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) {
        emit(state.copyWith(busy: false));
        _next();
      },
    );
  }

  void _next() {
    final next = state.index + 1;
    if (next >= state.windows.length) {
      emit(state.copyWith(error: '', done: true));
      return;
    }
    emit(state.copyWith(
      index: next,
      drafts: _initialDrafts(state.windows[next]),
      error: '',
    ));
  }

  static Map<String, FillDraft> _initialDrafts(FillCandidate window) => {
        for (final lot in window.lots)
          for (final row in lot.rows)
            fillDraftKey(lot.lotId, row.movementId): FillDraft(
              checked: row.checkedQuantity > 0,
              quantity: row.checkedQuantity > 0
                  ? '${row.checkedQuantity}'
                  : '${row.emptyQuantity}',
            ),
      };
}
