import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/usecases/settlement_usecase.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';

/// Payout detail BLoC (FEATURE_2610_20 / D22 · D23 · D34 · D38 · D39) — the
/// mobile twin of the web `PayoutDetailContainer`.
///
/// - Entry calls the report and every line (lookups only — no refresh call
///   lives on this screen).
/// - One cause label at a time; lines of a label / of 「미분류」 are filtered by the
///   server.
/// - 「지급 완료」 / 「지급 완료 취소」 write the local payout only and re-read the report.
class PayoutDetailBloc extends Bloc<PayoutDetailEvent, PayoutDetailState> {
  final SettlementUseCase settlementUseCase;
  final int payoutId;

  PayoutDetailBloc({required this.settlementUseCase, required this.payoutId})
      : super(const PayoutDetailState()) {
    on<PayoutDetailStarted>(_onStarted);
    on<PayoutDetailRetried>(_onStarted);
    on<PayoutLabelToggled>(_onLabelToggled);
    on<PayoutUnmatchedToggled>(_onUnmatchedToggled);
    on<PayoutUnmatchedShown>(_onUnmatchedShown);
    on<PayoutExportRequested>(_onExport);
    on<PayoutMarkPaidRequested>(_onMarkPaid);
    on<PayoutUnmarkPaidRequested>(_onUnmarkPaid);
  }

  Future<void> _onStarted(
      PayoutDetailEvent event, Emitter<PayoutDetailState> emit) async {
    await _loadReport(emit);
    await _loadOrderLines(emit);
  }

  Future<void> _onLabelToggled(
      PayoutLabelToggled event, Emitter<PayoutDetailState> emit) async {
    emit(state.copyWith(
      unmatchedOnly: false,
      expandedLabel: state.expandedLabel == event.label ? '' : event.label,
    ));
    await _loadLines(emit);
  }

  Future<void> _onUnmatchedToggled(
      PayoutUnmatchedToggled event, Emitter<PayoutDetailState> emit) async {
    emit(
        state.copyWith(expandedLabel: '', unmatchedOnly: !state.unmatchedOnly));
    await _loadLines(emit);
  }

  Future<void> _onUnmatchedShown(
      PayoutUnmatchedShown event, Emitter<PayoutDetailState> emit) async {
    emit(state.copyWith(expandedLabel: '', unmatchedOnly: true));
    await _loadLines(emit);
  }

  Future<void> _onExport(
      PayoutExportRequested event, Emitter<PayoutDetailState> emit) async {
    final report = state.report;
    if (report == null) {
      return;
    }
    emit(state.copyWith(exporting: true));
    final result = await settlementUseCase.exportReport(payoutId);
    if (emit.isDone) {
      return;
    }
    result.fold(
      (failure) => emit(_toast(
        _statusOf(failure) == 429
            ? '${marketName(report.payout.platform)} 호출이 일시 제한되었습니다. 잠시 후 다시 '
                '시도하세요.'
            : '엑셀 다운로드에 실패했습니다. 다시 시도해주세요.',
        isError: true,
      ).copyWith(exporting: false)),
      (bytes) => emit(state.copyWith(
          exporting: false,
          exportBytes: bytes,
          exportTick: state.exportTick + 1)),
    );
  }

  Future<void> _onMarkPaid(
      PayoutMarkPaidRequested event, Emitter<PayoutDetailState> emit) async {
    emit(state.copyWith(marking: true));
    final result = await settlementUseCase.markPaid(payoutId, event.paidOn);
    if (emit.isDone) {
      return;
    }
    await result.fold(
      (failure) async => emit(
          _toast(_text(failure, '지급 완료 저장에 실패했습니다.'), isError: true)
              .copyWith(marking: false)),
      (_) async {
        await _loadReport(emit);
        emit(state.copyWith(marking: false));
      },
    );
  }

  Future<void> _onUnmarkPaid(
      PayoutUnmarkPaidRequested event, Emitter<PayoutDetailState> emit) async {
    emit(state.copyWith(marking: true));
    final result = await settlementUseCase.unmarkPaid(payoutId);
    if (emit.isDone) {
      return;
    }
    await result.fold(
      (failure) async => emit(
          _toast(_text(failure, '지급 완료 취소에 실패했습니다.'), isError: true)
              .copyWith(marking: false)),
      (_) async {
        await _loadReport(emit);
        emit(state.copyWith(marking: false));
      },
    );
  }

  Future<void> _loadReport(Emitter<PayoutDetailState> emit) async {
    emit(state.copyWith(loading: true, error: ''));
    final result = await settlementUseCase.getReport(payoutId);
    if (emit.isDone) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        forbidden: _statusOf(failure) == 403,
        error: _text(failure, '차이 리포트 조회에 실패했습니다.'),
      )),
      (report) => emit(state.copyWith(loading: false, report: report)),
    );
  }

  /// Every line of the payout — the server returns them all when no filter is
  /// sent.
  Future<void> _loadOrderLines(Emitter<PayoutDetailState> emit) async {
    emit(state.copyWith(orderLinesLoading: true, orderLinesError: ''));
    final result = await settlementUseCase.getPayoutLines(payoutId);
    if (emit.isDone) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        orderLinesLoading: false,
        orderLines: const [],
        orderLinesError: _text(failure, '주문 목록 조회에 실패했습니다.'),
      )),
      (lines) =>
          emit(state.copyWith(orderLinesLoading: false, orderLines: lines)),
    );
  }

  Future<void> _loadLines(Emitter<PayoutDetailState> emit) async {
    if (!state.unmatchedOnly && state.expandedLabel.isEmpty) {
      emit(state.copyWith(lines: const []));
      return;
    }
    emit(state.copyWith(linesLoading: true, linesError: ''));
    final result = state.unmatchedOnly
        ? await settlementUseCase.getPayoutLines(payoutId, unmatched: true)
        : await settlementUseCase.getPayoutLines(payoutId,
            label: state.expandedLabel);
    if (emit.isDone) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        linesLoading: false,
        lines: const [],
        linesError: _text(failure, '판매 내역 조회에 실패했습니다.'),
      )),
      (lines) => emit(state.copyWith(linesLoading: false, lines: lines)),
    );
  }

  PayoutDetailState _toast(String message, {required bool isError}) =>
      state.copyWith(
          toastMessage: message,
          toastIsError: isError,
          toastTick: state.toastTick + 1);

  static int? _statusOf(Failure failure) =>
      failure is ServerFailure ? failure.statusCode : null;

  static String _text(Failure failure, String fallback) =>
      failure.message.trim().isNotEmpty ? failure.message : fallback;
}
