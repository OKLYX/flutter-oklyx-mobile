/// Events of the 「통합 매출 조회」 BLoC (FEATURE_2610_20 / D26).
sealed class SalesSummaryEvent {
  const SalesSummaryEvent();
}

/// Screen entry — seller summary + packing savings of this month.
class SalesSummaryStarted extends SalesSummaryEvent {
  /// The shared 「출고 전 주문 제외」 value on entry (FEATURE_2611_04 / D9).
  final bool excludeUnshipped;
  const SalesSummaryStarted({this.excludeUnshipped = false});
}

/// Sale-date range `yyyy-MM-dd`. Folds the open seller (its rows belong to the
/// old period).
class SalesSummaryPeriodChanged extends SalesSummaryEvent {
  final String from;
  final String to;
  const SalesSummaryPeriodChanged({required this.from, required this.to});
}

/// [다시 시도] — the same period again.
class SalesSummaryRetried extends SalesSummaryEvent {
  const SalesSummaryRetried();
}

/// 「출고 전 주문 제외」 switch (FEATURE_2611_04) — folds the open seller and
/// reloads the seller rows only (packing savings do not depend on it).
class SalesSummaryExcludeUnshippedChanged extends SalesSummaryEvent {
  final bool excludeUnshipped;
  const SalesSummaryExcludeUnshippedChanged({required this.excludeUnshipped});
}

/// A seller row tapped — opens it (channels + payouts of the period), or folds
/// it when already open.
class SalesSellerToggled extends SalesSummaryEvent {
  final int sellerId;
  const SalesSellerToggled(this.sellerId);
}
