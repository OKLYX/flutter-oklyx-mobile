import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';

/// 「정산 기준」 (payout → sales) / 「판매월 기준」 (sales → payout).
enum PayoutViewMode { payout, saleMonth }

/// State of the 「정산 내역」 list (FEATURE_2610_20 / D18 · D19 · D24 · D45 ⑦) — the
/// mobile twin of the web `PayoutListContainer` state.
class PayoutListState extends Equatable {
  /// A lookup of [rows] is running. The first load shows the spinner; a reload
  /// keeps the old rows.
  final bool loading;

  /// The server answered 403 — the page shows 「관리자만 볼 수 있습니다.」 (D20).
  final bool forbidden;

  /// List lookup failure text. Empty = none.
  final String error;
  final List<PayoutSummary> rows;
  final List<Seller> sellers;
  final List<SettlementSyncTarget> targets;
  final int? sellerId;
  final int? accountId;

  /// Payout-date range, `yyyy-MM-dd`; empty = none.
  final String from;
  final String to;
  final PayoutViewMode viewMode;
  final List<SaleMonthSettlement> saleMonths;
  final bool saleMonthsLoading;
  final String saleMonthsError;
  final bool syncing;
  final bool payoutSyncing;
  final bool backfillRunning;

  /// e.g. 「11번가 · 메인 · 매출 2026년 7월 (2/24)」.
  final String backfillProgress;

  /// Normal notice (skip · load result) — blue, not a failure.
  final String syncNotice;
  final String syncError;

  /// Rate-limit text (429). Not empty → the three buttons are hidden (D24).
  final String rateLimited;
  final List<FirstMonthQuestion> questions;
  final int? answeringLinkId;
  final String questionError;

  const PayoutListState({
    this.loading = true,
    this.forbidden = false,
    this.error = '',
    this.rows = const [],
    this.sellers = const [],
    this.targets = const [],
    this.sellerId,
    this.accountId,
    this.from = '',
    this.to = '',
    this.viewMode = PayoutViewMode.payout,
    this.saleMonths = const [],
    this.saleMonthsLoading = false,
    this.saleMonthsError = '',
    this.syncing = false,
    this.payoutSyncing = false,
    this.backfillRunning = false,
    this.backfillProgress = '',
    this.syncNotice = '',
    this.syncError = '',
    this.rateLimited = '',
    this.questions = const [],
    this.answeringLinkId,
    this.questionError = '',
  });

  /// Channel choices = the sync targets of the chosen seller (all when 「전체」).
  List<SettlementSyncTarget> get channels => sellerId == null
      ? targets
      : targets.where((t) => t.sellerId == sellerId).toList();

  /// A refresh button is running — every refresh button is disabled.
  bool get busy => syncing || payoutSyncing || backfillRunning;

  bool get invalidRange =>
      from.isNotEmpty && to.isNotEmpty && from.compareTo(to) > 0;

  PayoutListState copyWith({
    bool? loading,
    bool? forbidden,
    String? error,
    List<PayoutSummary>? rows,
    List<Seller>? sellers,
    List<SettlementSyncTarget>? targets,
    int? sellerId,
    bool clearSeller = false,
    int? accountId,
    bool clearAccount = false,
    String? from,
    String? to,
    PayoutViewMode? viewMode,
    List<SaleMonthSettlement>? saleMonths,
    bool? saleMonthsLoading,
    String? saleMonthsError,
    bool? syncing,
    bool? payoutSyncing,
    bool? backfillRunning,
    String? backfillProgress,
    String? syncNotice,
    String? syncError,
    String? rateLimited,
    List<FirstMonthQuestion>? questions,
    int? answeringLinkId,
    bool clearAnswering = false,
    String? questionError,
  }) =>
      PayoutListState(
        loading: loading ?? this.loading,
        forbidden: forbidden ?? this.forbidden,
        error: error ?? this.error,
        rows: rows ?? this.rows,
        sellers: sellers ?? this.sellers,
        targets: targets ?? this.targets,
        sellerId: clearSeller ? null : (sellerId ?? this.sellerId),
        accountId: clearAccount ? null : (accountId ?? this.accountId),
        from: from ?? this.from,
        to: to ?? this.to,
        viewMode: viewMode ?? this.viewMode,
        saleMonths: saleMonths ?? this.saleMonths,
        saleMonthsLoading: saleMonthsLoading ?? this.saleMonthsLoading,
        saleMonthsError: saleMonthsError ?? this.saleMonthsError,
        syncing: syncing ?? this.syncing,
        payoutSyncing: payoutSyncing ?? this.payoutSyncing,
        backfillRunning: backfillRunning ?? this.backfillRunning,
        backfillProgress: backfillProgress ?? this.backfillProgress,
        syncNotice: syncNotice ?? this.syncNotice,
        syncError: syncError ?? this.syncError,
        rateLimited: rateLimited ?? this.rateLimited,
        questions: questions ?? this.questions,
        answeringLinkId:
            clearAnswering ? null : (answeringLinkId ?? this.answeringLinkId),
        questionError: questionError ?? this.questionError,
      );

  @override
  List<Object?> get props => [
        loading,
        forbidden,
        error,
        rows,
        sellers,
        targets,
        sellerId,
        accountId,
        from,
        to,
        viewMode,
        saleMonths,
        saleMonthsLoading,
        saleMonthsError,
        syncing,
        payoutSyncing,
        backfillRunning,
        backfillProgress,
        syncNotice,
        syncError,
        rateLimited,
        questions,
        answeringLinkId,
        questionError,
      ];
}
