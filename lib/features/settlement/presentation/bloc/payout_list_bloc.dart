import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/usecases/settlement_usecase.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_event.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_state.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';

/// 「정산 내역」 list BLoC (FEATURE_2610_20 / D18 · D19 · D24 · D25 · D45 ⑦) — the
/// mobile twin of the web `PayoutListContainer`: same calls, same order, same
/// notices.
///
/// - Entry calls the four lookups only (sellers · sync targets · payouts ·
///   first-month questions) — never a `sync*` call (D19).
/// - The rate limit (429) hides the three refresh buttons and shows the
///   server's text (D24).
/// - The backfill calls month by month, revenue first, then payouts; a 429
///   stops it; [PayoutBackfillStopped] (page left / app in the background)
///   skips the months not called yet (D25).
/// - A 403 on the list makes the page show 「관리자만 볼 수 있습니다.」 (D20).
class PayoutListBloc extends Bloc<PayoutListEvent, PayoutListState> {
  final SettlementUseCase settlementUseCase;
  final GetSellersUseCase getSellersUseCase;

  /// The last list request — an older answer that arrives later is dropped.
  int _requestId = 0;
  bool _backfillStopped = false;

  PayoutListBloc(
      {required this.settlementUseCase, required this.getSellersUseCase})
      : super(const PayoutListState()) {
    on<PayoutListStarted>(_onStarted);
    on<PayoutSellerChanged>(_onSellerChanged);
    on<PayoutChannelChanged>(_onChannelChanged);
    on<PayoutPeriodChanged>(_onPeriodChanged);
    on<PayoutViewModeChanged>(_onViewModeChanged);
    on<PayoutListRetried>(_onRetried);
    on<PayoutRevenueSyncRequested>(_onRevenueSync);
    on<PayoutPayoutSyncRequested>(_onPayoutSync);
    on<PayoutBackfillRequested>(_onBackfill);
    on<PayoutBackfillStopped>(_onBackfillStopped);
    on<PayoutFirstMonthAnswered>(_onAnswered);
  }

  Future<void> _onStarted(
      PayoutListStarted event, Emitter<PayoutListState> emit) async {
    // Sellers and questions are not fatal: a failure leaves 「전체」 only / no
    // question row.
    final sellers =
        (await getSellersUseCase()).fold((_) => <Seller>[], (list) => list);
    if (emit.isDone) {
      return;
    }
    emit(state.copyWith(sellers: sellers));
    await _loadTargets(emit);
    await _loadRows(emit);
    await _loadSaleMonths(emit);
    await _loadQuestions(emit);
  }

  Future<void> _onSellerChanged(
      PayoutSellerChanged event, Emitter<PayoutListState> emit) async {
    // A new seller makes the old channel choice another seller's — it is
    // cleared together.
    emit(state.copyWith(
      sellerId: event.sellerId,
      clearSeller: event.sellerId == null,
      clearAccount: true,
    ));
    await _loadTargets(emit);
    await _loadRows(emit);
    await _loadSaleMonths(emit);
  }

  Future<void> _onChannelChanged(
      PayoutChannelChanged event, Emitter<PayoutListState> emit) async {
    emit(state.copyWith(
        accountId: event.accountId, clearAccount: event.accountId == null));
    await _loadRows(emit);
    await _loadSaleMonths(emit);
  }

  Future<void> _onPeriodChanged(
      PayoutPeriodChanged event, Emitter<PayoutListState> emit) async {
    emit(state.copyWith(from: event.from, to: event.to));
    await _loadRows(emit);
    await _loadSaleMonths(emit);
  }

  Future<void> _onViewModeChanged(
      PayoutViewModeChanged event, Emitter<PayoutListState> emit) async {
    emit(state.copyWith(viewMode: event.viewMode));
    await _loadSaleMonths(emit);
  }

  Future<void> _onRetried(
      PayoutListRetried event, Emitter<PayoutListState> emit) async {
    await _loadRows(emit);
    await _loadSaleMonths(emit);
  }

  Future<void> _onRevenueSync(
      PayoutRevenueSyncRequested event, Emitter<PayoutListState> emit) async {
    emit(state.copyWith(syncing: true, syncNotice: '', syncError: ''));
    final result = await settlementUseCase.syncSettlement(
        accountId: state.accountId, sellerId: state.sellerId);
    if (emit.isDone) {
      return;
    }
    await result.fold(
      (failure) async => emit(
          _syncFailure(failure, '정산 갱신에 실패했습니다.', _filterMarket())
              .copyWith(syncing: false)),
      (sync) async {
        if (sync.skipped) {
          // Not an error — within the minimum interval the market was not
          // called (D11 of 2609_30).
          emit(state.copyWith(
            syncing: false,
            syncNotice:
                '방금 갱신했습니다. ${formatDateTime(sync.nextAvailableAt)} 이후 다시 시도할 '
                '수 있습니다.',
          ));
          return;
        }
        emit(state.copyWith(
          syncing: false,
          syncNotice:
              '채널 ${sync.accounts}개 · 판매 ${sync.lines}건 갱신 (매칭 ${sync.matched} '
              '· 미분류 ${sync.unmatched})',
          syncError: sync.failedAccounts.isEmpty
              ? ''
              : '일부 채널 실패: ${sync.failedAccounts.join(', ')}',
        ));
        await _loadTargets(emit);
        await _loadRows(emit);
        await _loadQuestions(emit);
      },
    );
  }

  Future<void> _onPayoutSync(
      PayoutPayoutSyncRequested event, Emitter<PayoutListState> emit) async {
    emit(state.copyWith(payoutSyncing: true, syncNotice: '', syncError: ''));
    final result =
        await settlementUseCase.syncPayouts(accountId: state.accountId);
    if (emit.isDone) {
      return;
    }
    await result.fold(
      (failure) async => emit(
          _syncFailure(failure, '지급내역 갱신에 실패했습니다.', _filterMarket())
              .copyWith(payoutSyncing: false)),
      (sync) async {
        // `attributedLines == 0` is normal too (additional / reserve payouts
        // take no line).
        emit(state.copyWith(
          payoutSyncing: false,
          syncNotice:
              '지급 묶음 ${sync.payouts}건 · 조정 ${sync.adjustments}건 갱신 (판매 건 연결 '
              '${sync.attributedLines}건)',
          syncError: sync.failedAccounts.isEmpty
              ? ''
              : '일부 채널 실패: ${sync.failedAccounts.join(', ')}',
        ));
        await _loadTargets(emit);
        await _loadRows(emit);
      },
    );
  }

  /// Revenue for every month first, then payouts for every month (2609_31 D2);
  /// sequential; a 429 stops at once (D6); [PayoutBackfillStopped] skips the
  /// months not called yet (D25). The filter is left as it is.
  Future<void> _onBackfill(
      PayoutBackfillRequested event, Emitter<PayoutListState> emit) async {
    final months = monthsBetween(event.fromMonth, event.toMonth);
    if (months.isEmpty) {
      return;
    }
    _backfillStopped = false;
    final total = months.length * 2;
    final target =
        state.channels.where((c) => c.accountId == event.accountId).firstOrNull;
    final name = target == null
        ? '채널 #${event.accountId}'
        : channelLabel(target.platform, target.accountAlias, target.accountId);
    final market = marketName(target?.platform);
    final periodLabel =
        '${monthLabel(months.first)}~${monthLabel(months.last)}';
    final failedMonths = <String>{};
    var done = 0;
    var rateLimited = false;
    var payouts = 0;
    var adjustments = 0;
    var attributedLines = 0;

    emit(state.copyWith(backfillRunning: true, syncNotice: '', syncError: ''));

    for (final month in months) {
      if (_backfillStopped || emit.isDone) {
        break;
      }
      emit(state.copyWith(
          backfillProgress:
              '$name · 매출 ${monthLabel(month)} (${done + 1}/$total)'));
      final range = monthRange(month);
      final result = await settlementUseCase.syncRevenuePeriod(
        accountId: event.accountId,
        from: range.from,
        to: range.to,
      );
      if (emit.isDone) {
        return;
      }
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null && _statusOf(failure) == 429) {
        rateLimited = true;
        emit(_syncFailure(failure, '$market 호출이 일시 제한되었습니다.', market));
        break;
      }
      if (failure != null ||
          result.fold((_) => false, (sync) => sync.failedAccounts.isNotEmpty)) {
        failedMonths.add(monthLabel(month));
      }
      done++;
    }

    if (!rateLimited) {
      for (final month in months) {
        if (_backfillStopped || emit.isDone) {
          break;
        }
        emit(state.copyWith(
            backfillProgress:
                '$name · 지급 ${monthLabel(month)} (${done + 1}/$total)'));
        final result = await settlementUseCase.syncPayouts(
            accountId: event.accountId, month: month);
        if (emit.isDone) {
          return;
        }
        final failure = result.fold((f) => f, (_) => null);
        if (failure != null && _statusOf(failure) == 429) {
          rateLimited = true;
          emit(_syncFailure(failure, '$market 호출이 일시 제한되었습니다.', market));
          break;
        }
        result.fold((_) => failedMonths.add(monthLabel(month)), (sync) {
          payouts += sync.payouts;
          adjustments += sync.adjustments;
          attributedLines += sync.attributedLines;
          if (sync.failedAccounts.isNotEmpty) {
            failedMonths.add(monthLabel(month));
          }
        });
        done++;
      }
    }

    var notice = state.syncNotice;
    if (!rateLimited) {
      // Zero payouts is not a failure — the market simply announced no
      // settlement in that period.
      final summary = payouts == 0
          ? '$periodLabel에 ${withSubjectParticle(market)} 통보한 정산이 없습니다.'
          : '$periodLabel · 정산 $payouts건 · 조정 $adjustments건 불러왔습니다 (판매 건 연결 '
              '$attributedLines건)';
      final filtered = state.from.isNotEmpty || state.to.isNotEmpty
          ? ' 지급일 필터가 걸려 있어 그 밖의 정산은 목록에 보이지 않습니다.'
          : '';
      notice = '$summary$filtered';
    }
    emit(state.copyWith(
      backfillRunning: false,
      backfillProgress: '',
      syncNotice: notice,
      syncError: failedMonths.isEmpty
          ? state.syncError
          : '실패: ${failedMonths.join(', ')}',
    ));
    await _loadTargets(emit);
    await _loadRows(emit);
    await _loadQuestions(emit);
  }

  void _onBackfillStopped(
      PayoutBackfillStopped event, Emitter<PayoutListState> emit) {
    _backfillStopped = true;
  }

  Future<void> _onAnswered(
      PayoutFirstMonthAnswered event, Emitter<PayoutListState> emit) async {
    emit(state.copyWith(answeringLinkId: event.linkId, questionError: ''));
    final result = await settlementUseCase.answerFirstMonth(event.linkId,
        charged: event.charged);
    if (emit.isDone) {
      return;
    }
    await result.fold(
      (failure) async => emit(state.copyWith(
        clearAnswering: true,
        questionError: _text(failure, '답을 저장하지 못했습니다.'),
      )),
      (_) async {
        emit(state.copyWith(clearAnswering: true));
        await _loadQuestions(emit);
      },
    );
  }

  Future<void> _loadRows(Emitter<PayoutListState> emit) async {
    if (state.invalidRange) {
      return;
    }
    final requestId = ++_requestId;
    emit(state.copyWith(loading: true, error: ''));
    final result = await settlementUseCase.getPayouts(
      sellerId: state.sellerId,
      accountId: state.accountId,
      from: state.from.isEmpty ? null : state.from,
      to: state.to.isEmpty ? null : state.to,
    );
    if (emit.isDone || requestId != _requestId) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        forbidden: _statusOf(failure) == 403,
        rows: const [],
        error: _text(failure, '정산 내역 조회에 실패했습니다.'),
      )),
      (rows) => emit(state.copyWith(loading: false, rows: rows)),
    );
  }

  /// The channel choices and "last refresh". A failure only loses the labels.
  Future<void> _loadTargets(Emitter<PayoutListState> emit) async {
    final result =
        await settlementUseCase.getSyncTargets(sellerId: state.sellerId);
    if (emit.isDone) {
      return;
    }
    emit(state.copyWith(
        targets: result.fold(
            (_) => const <SettlementSyncTarget>[], (list) => list)));
  }

  /// 「판매월 기준」 needs a channel and both dates (the server answers 400
  /// otherwise).
  Future<void> _loadSaleMonths(Emitter<PayoutListState> emit) async {
    final accountId = state.accountId;
    if (state.viewMode != PayoutViewMode.saleMonth ||
        accountId == null ||
        state.from.isEmpty ||
        state.to.isEmpty) {
      emit(state.copyWith(saleMonths: const []));
      return;
    }
    emit(state.copyWith(saleMonthsLoading: true, saleMonthsError: ''));
    final result = await settlementUseCase.getSaleMonthSettlements(
      accountId: accountId,
      from: state.from,
      to: state.to,
    );
    if (emit.isDone) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        saleMonthsLoading: false,
        saleMonths: const [],
        saleMonthsError: _text(failure, '판매월 정산 조회에 실패했습니다.'),
      )),
      (rows) =>
          emit(state.copyWith(saleMonthsLoading: false, saleMonths: rows)),
    );
  }

  /// A failure only hides the question rows.
  Future<void> _loadQuestions(Emitter<PayoutListState> emit) async {
    final result = await settlementUseCase.getFirstMonthQuestions();
    if (emit.isDone) {
      return;
    }
    emit(state.copyWith(
        questions:
            result.fold((_) => const <FirstMonthQuestion>[], (list) => list)));
  }

  /// 429 → the rate-limit text (buttons hidden); anything else → the error
  /// line.
  PayoutListState _syncFailure(
      Failure failure, String fallback, String market) {
    if (_statusOf(failure) == 429) {
      return state.copyWith(
          rateLimited: _text(failure, '$market 호출이 일시 제한되었습니다.'));
    }
    return state.copyWith(syncError: _text(failure, fallback));
  }

  /// D14: the filter's channel names the market; no channel chosen = 「마켓」.
  String _filterMarket() {
    final accountId = state.accountId;
    if (accountId == null) {
      return marketName(null);
    }
    return marketName(state.channels
        .where((c) => c.accountId == accountId)
        .firstOrNull
        ?.platform);
  }

  static int? _statusOf(Failure failure) =>
      failure is ServerFailure ? failure.statusCode : null;

  /// The server's text first (web `extractErrorMessage`), otherwise [fallback].
  static String _text(Failure failure, String fallback) =>
      failure.message.trim().isNotEmpty ? failure.message : fallback;
}
