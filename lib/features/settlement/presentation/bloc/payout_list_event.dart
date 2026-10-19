import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_state.dart';

/// Events of `PayoutListBloc` (FEATURE_2610_20 / D18 · D19 · D24 · D25 · D45
/// ⑦).
sealed class PayoutListEvent {
  const PayoutListEvent();
}

/// Screen entry — sellers · sync targets · payouts · first-month questions
/// (lookups only, no market call — D19).
class PayoutListStarted extends PayoutListEvent {
  const PayoutListStarted();
}

/// Seller filter (null = 「전체」). The channel choice is cleared — it belonged to
/// another seller.
class PayoutSellerChanged extends PayoutListEvent {
  final int? sellerId;
  const PayoutSellerChanged(this.sellerId);
}

/// Channel filter (null = 「전체」).
class PayoutChannelChanged extends PayoutListEvent {
  final int? accountId;
  const PayoutChannelChanged(this.accountId);
}

/// Payout-date range (`yyyy-MM-dd`; both empty = no range).
class PayoutPeriodChanged extends PayoutListEvent {
  final String from;
  final String to;
  const PayoutPeriodChanged({required this.from, required this.to});
}

/// 「정산 기준」 / 「판매월 기준」.
class PayoutViewModeChanged extends PayoutListEvent {
  final PayoutViewMode viewMode;
  const PayoutViewModeChanged(this.viewMode);
}

/// [다시 시도] — the same filter again.
class PayoutListRetried extends PayoutListEvent {
  const PayoutListRetried();
}

/// [갱신] — revenue lines of the filter's channel / seller / all (market call).
class PayoutRevenueSyncRequested extends PayoutListEvent {
  const PayoutRevenueSyncRequested();
}

/// [지급내역 갱신] — payouts (market call; 11st = rebuilt from stored lines).
class PayoutPayoutSyncRequested extends PayoutListEvent {
  const PayoutPayoutSyncRequested();
}

/// [과거 정산 불러오기] → [불러오기]: one channel, months `fromMonth`..`toMonth`.
class PayoutBackfillRequested extends PayoutListEvent {
  final int accountId;
  final String fromMonth;
  final String toMonth;
  const PayoutBackfillRequested(
      {required this.accountId,
      required this.fromMonth,
      required this.toMonth});
}

/// D25: the page went away or the app went to the background — the months not
/// called yet are skipped.
class PayoutBackfillStopped extends PayoutListEvent {
  const PayoutBackfillStopped();
}

/// [예] / [아니오] on a first-month question (D45 ⑦).
class PayoutFirstMonthAnswered extends PayoutListEvent {
  final int linkId;
  final bool charged;
  const PayoutFirstMonthAnswered({required this.linkId, required this.charged});
}
