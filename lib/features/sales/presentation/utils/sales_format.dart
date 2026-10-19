import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';

/// 「매출」 words and number formats (FEATURE_2610_20 / D26) — the mobile twin of
/// the web `SalesSummary.ts` · `PackingSavingsEntity.ts` helpers. Money and
/// counts reuse the settlement formats.

/// Profit: `—` until the cost basis is ready — never 0 (0 reads "nothing
/// left").
String formatProfit(num? estNetProfit, {required bool costBasisReady}) =>
    costBasisReady && estNetProfit != null ? formatMoney(estNetProfit) : '—';

/// Fixed cost: a cost, so a minus sign; 0 = `—`. Never the warning color.
String formatFixedCost(num? value) =>
    value == null || value == 0 ? '—' : '−${formatMoney(value)}';

/// The fixed-cost rule of a channel other than 11st (web `FIXED_COST_HINT`).
const String kFixedCostHint = '그 달 상품 매출이 기준 이상인 달에만 부과됩니다. 일할 계산은 없습니다.';

/// The fixed-cost rule of an 11st channel (web `ELEVENST_FIXED_COST_HINT`,
/// FEATURE_2610_20 / D42).
const String kElevenstFixedCostHint =
    '전달 11번가 구매확정액(판매가 + 옵션가)이 기준 이상인 달에만 부과됩니다. 일할 계산은 없습니다.';

/// Both rules, for a value that mixes platforms — a seller row sums its
/// channels (web `FIXED_COST_HINT_MIXED`, D42).
const String kFixedCostHintMixed = '11번가 외 채널: 그 달 상품 매출이 기준 이상인 달에만 부과됩니다. '
    '11번가: 전달 11번가 구매확정액(판매가 + 옵션가)이 기준 이상인 달에만 부과됩니다. '
    '일할 계산은 없습니다.';

/// The fixed-cost rule of one channel: [kElevenstFixedCostHint] for 11st,
/// otherwise [kFixedCostHint] (web `fixedCostHintFor`).
String fixedCostHintFor(String? platform) =>
    platform == 'ELEVENST' ? kElevenstFixedCostHint : kFixedCostHint;

/// Why a profit is `—` (web `PROFIT_PENDING_HINT`).
const String kProfitPendingHint =
    '순이익 추정치는 상품 단가와 비용(택배비, 상자비 등)이 모두 작성 완료되어야 표시가능합니다.';

/// Saving in won with 「원」; null = `—` (no record, not 0).
String formatSaving(num? value) =>
    value == null ? '—' : '${formatMoney(value)}원';

/// Saving color: none = outline gray, negative = error red, otherwise the
/// normal text color.
Color savingColor(num? value, ColorScheme scheme) {
  if (value == null) {
    return scheme.outline;
  }
  return value < 0 ? scheme.error : scheme.onSurface;
}

/// Box count; null = `—`.
String formatParcelCount(num? value) =>
    value == null ? '—' : formatCount(value);

const String kSavingsBasisNotice =
    '포장한 날 기준입니다. 같은 화면의 매출은 주문일 기준이라 기간이 덮는 주문이 다릅니다.';
const String kSavingsProfitNotice =
    '순이익이 계산된 상품에 한해, 이 금액만큼 추정 순이익에 더해집니다. 지금 손익 화면은 옵션마다 상자·택배가 든다고 가정합니다.';
const String kSavingsOverlapNotice = '일부 박스는 재활용과 합포장 양쪽에 모두 해당합니다.';
const String kSavingsNoRecordHint = '포장 화면을 거치지 않은 주문입니다';
const String kSavingsChannelNotice = '포장 절약은 채널과 무관해 채널별 보기에서는 표시하지 않습니다.';

/// Same month and not the whole month — the fixed-cost note then adds that a
/// full month is charged.
bool isShorterThanMonth(String from, String to) {
  final start = DateTime.tryParse(from);
  final end = DateTime.tryParse(to);
  if (start == null || end == null || from.compareTo(to) > 0) {
    return false;
  }
  if (start.year != end.year || start.month != end.month) {
    return false;
  }
  final lastDay = DateTime(end.year, end.month + 1, 0).day;
  return start.day != 1 || end.day != lastDay;
}

/// A sale-date range `yyyy-MM-dd`.
typedef SalesRange = ({String from, String to});

/// Default = the 1st of this month ~ today.
SalesRange currentMonthRange() {
  final today = DateTime.now();
  return (
    from: toDateText(DateTime(today.year, today.month)),
    to: toDateText(today)
  );
}

SalesRange _lastMonthRange() {
  final today = DateTime.now();
  return (
    from: toDateText(DateTime(today.year, today.month - 1)),
    to: toDateText(DateTime(today.year, today.month, 0)),
  );
}

SalesRange _recentDaysRange(int days) {
  final today = DateTime.now();
  return (
    from: toDateText(DateTime(today.year, today.month, today.day - (days - 1))),
    to: toDateText(today),
  );
}

/// The three preset chips of the period filter, in the web order.
final List<({String label, SalesRange Function() range})> kSalesPeriodPresets =
    [
  (label: '이번 달', range: currentMonthRange),
  (label: '지난 달', range: _lastMonthRange),
  (label: '최근 7일', range: () => _recentDaysRange(7)),
];
