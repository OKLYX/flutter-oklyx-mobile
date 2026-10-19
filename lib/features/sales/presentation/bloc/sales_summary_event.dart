/// Events of the 「통합 매출 조회」 BLoC (FEATURE_2610_20 / D26).
sealed class SalesSummaryEvent {
  const SalesSummaryEvent();
}

/// Screen entry — seller summary + packing savings of this month.
class SalesSummaryStarted extends SalesSummaryEvent {
  const SalesSummaryStarted();
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

/// A seller row tapped — opens it (channels + payouts of the period), or folds
/// it when already open.
class SalesSellerToggled extends SalesSummaryEvent {
  final int sellerId;
  const SalesSellerToggled(this.sellerId);
}
