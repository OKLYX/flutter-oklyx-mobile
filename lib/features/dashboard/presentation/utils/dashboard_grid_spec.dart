import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';

/// Mobile dashboard grid and card sizes — defined here (FEATURE_2610_29 /
/// D5 · D7 · D10 · D15 · D17).
///
/// **Purpose**: the invisible grid of the dashboard (2 columns, rows without
/// end, a card is 1 row high) and the widths each card may take.
/// **Rule**: cards do not write a column count or a pixel size — they read
/// this file. Change a value here and the cards follow on the next build; a
/// stored width the new spec does not have is shrunk on screen (D18,
/// `dashboard_layout.dart`).
/// **File**: lib/features/dashboard/presentation/utils/dashboard_grid_spec.dart
///
/// **Usage**:
/// ```dart
/// kDashboardCardSpecs[DashboardCardType.periodSales]!.minWidth  // 2
/// allowedWidths(DashboardCardType.paidOrders)                   // [1, 2]
/// effectivePeriod(DashboardCardType.periodSales, null)  // thisMonth
/// ```
///
/// ⚠️ The web has its own copy of the card table (`src/config/dashboardGrid.ts`)
///    — titles and periods must stay the same text.
/// ❌ Do not add a card here without a decision (D8 list).
class MobileGrid {
  /// Columns across (D5).
  static const int columns = 2;

  /// Height of the one row a card takes, in logical px (D17).
  static const double rowHeight = 104;

  /// Height of a tall card's row — 1.5 × [rowHeight] (2026-10-24, the chart
  /// and payout cards read too short at one row).
  static const double tallRowHeight = 156;

  /// Space between cells, both directions (D17).
  static const double gap = 12;

  /// Card widths in cells (D7).
  static const List<int> widths = [1, 2];

  /// Channel rows the 「채널별 매출」 card shows before it folds the rest
  /// into one 「외 K개」 line (DASHBOARD_CARDS D41 · D44) — 3 × 22px rows +
  /// the 16px fold line fit the 104px chart area of a tall card.
  /// ⚠️ Same value as the web `CHANNEL_CHART_ROWS.narrow`.
  static const int channelChartRows = 3;
}

/// One card of the catalog.
class DashboardCardSpec {
  /// Card title on the card and in the picker.
  final String title;

  /// true = hidden from non-admin members (D9).
  final bool adminOnly;

  /// Smallest width in cells (D15).
  final int minWidth;

  /// Width a new card gets (D15).
  final int initialWidth;

  /// Screen a tap opens (D21).
  final String route;

  /// Periods the card offers, in selector order; empty = no period.
  final List<DashboardPeriod> periods;

  /// Period used while none is stored; null = no period (D22 · D23).
  final DashboardPeriod? defaultPeriod;

  /// true = drawn [MobileGrid.tallRowHeight] high instead of one row; only
  /// full-width cards, so a row never mixes heights.
  final bool tall;

  const DashboardCardSpec({
    required this.title,
    required this.adminOnly,
    required this.minWidth,
    required this.initialWidth,
    required this.route,
    this.periods = const [],
    this.defaultPeriod,
    this.tall = false,
  });
}

/// The catalog in the D8 order (map order = picker order).
const Map<DashboardCardType, DashboardCardSpec> kDashboardCardSpecs = {
  DashboardCardType.paidOrders: DashboardCardSpec(
    title: '결제완료 주문 수',
    adminOnly: false,
    minWidth: 1,
    initialWidth: 1,
    route: Routes.shipmentManagementPath,
  ),
  DashboardCardType.newOrders: DashboardCardSpec(
    title: '새 주문 수',
    adminOnly: false,
    minWidth: 1,
    initialWidth: 1,
    route: Routes.shipmentManagementPath,
  ),
  DashboardCardType.openClaims: DashboardCardSpec(
    title: '처리 안 된 반품 · 교환',
    adminOnly: false,
    minWidth: 1,
    initialWidth: 1,
    route: Routes.claimListPath,
  ),
  DashboardCardType.unansweredInquiries: DashboardCardSpec(
    title: '답 안 한 고객문의',
    adminOnly: false,
    minWidth: 1,
    initialWidth: 1,
    route: Routes.inquiryListPath,
  ),
  DashboardCardType.periodSales: DashboardCardSpec(
    title: '기간 매출',
    adminOnly: true,
    minWidth: 2,
    initialWidth: 2,
    route: Routes.salesSummaryPath,
    periods: [
      DashboardPeriod.today,
      DashboardPeriod.days7,
      DashboardPeriod.thisMonth,
    ],
    defaultPeriod: DashboardPeriod.thisMonth,
  ),
  DashboardCardType.settlementPayouts: DashboardCardSpec(
    title: '정산 지급',
    adminOnly: true,
    minWidth: 2,
    initialWidth: 2,
    route: Routes.settlementPayoutsPath,
    tall: true,
  ),
  DashboardCardType.purchaseList: DashboardCardSpec(
    title: '구매목록 남은 품목',
    adminOnly: true,
    minWidth: 1,
    initialWidth: 1,
    route: Routes.listToShopPath,
  ),
  DashboardCardType.reservedShipments: DashboardCardSpec(
    title: '예약 발송',
    adminOnly: true,
    minWidth: 2,
    initialWidth: 2,
    route: Routes.reservedShipmentPath,
  ),
  DashboardCardType.dailySalesChart: DashboardCardSpec(
    title: '날짜별 매출 · 주문 수',
    adminOnly: true,
    minWidth: 2,
    initialWidth: 2,
    route: Routes.salesSummaryPath,
    periods: [
      DashboardPeriod.days7,
      DashboardPeriod.thisMonth,
      DashboardPeriod.lastMonth,
    ],
    defaultPeriod: DashboardPeriod.days7,
    tall: true,
  ),
  DashboardCardType.channelSalesChart: DashboardCardSpec(
    title: '채널별 매출',
    adminOnly: true,
    minWidth: 2,
    initialWidth: 2,
    route: Routes.salesByChannelPath,
    periods: [
      DashboardPeriod.days7,
      DashboardPeriod.thisMonth,
      DashboardPeriod.lastMonth,
    ],
    defaultPeriod: DashboardPeriod.days7,
    tall: true,
  ),
};

/// The spec of a card.
DashboardCardSpec specOf(DashboardCardType type) => kDashboardCardSpecs[type]!;

/// Selector labels of the periods (D22 · D23).
const Map<DashboardPeriod, String> kPeriodLabels = {
  DashboardPeriod.today: '오늘',
  DashboardPeriod.days7: '최근 7일',
  DashboardPeriod.days30: '최근 30일',
  DashboardPeriod.thisMonth: '이번 달',
  DashboardPeriod.lastMonth: '지난 달',
};

/// Height in px the card is drawn at on the grid.
double cardHeight(DashboardCardType type) =>
    specOf(type).tall ? MobileGrid.tallRowHeight : MobileGrid.rowHeight;

/// Widths the card may take: the D7 widths at or above its minimum.
List<int> allowedWidths(DashboardCardType type) =>
    MobileGrid.widths.where((width) => width >= specOf(type).minWidth).toList();

/// A stored 「최근 30일」 is 「이번 달」 when the card offers 「이번 달」
/// (FEATURE_2610_30 / D33); otherwise the stored period when the card offers
/// it, else the card's default period; null = the card has no period.
DashboardPeriod? effectivePeriod(
    DashboardCardType type, DashboardPeriod? period) {
  final spec = specOf(type);
  if (period == DashboardPeriod.days30 &&
      spec.periods.contains(DashboardPeriod.thisMonth)) {
    return DashboardPeriod.thisMonth;
  }
  return period != null && spec.periods.contains(period)
      ? period
      : spec.defaultPeriod;
}
