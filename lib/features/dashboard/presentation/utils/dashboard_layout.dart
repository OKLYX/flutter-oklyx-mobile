import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_grid_spec.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';

/// Mobile dashboard placement rules (FEATURE_2610_29 / D9 · D11 · D18 · D19)
/// — pure functions, no widgets.
///
/// **Purpose**: turn the stored cards into the cards the grid draws, and
/// back. The grid fills the cards in order, left to right (D24).
/// **File**: lib/features/dashboard/presentation/utils/dashboard_layout.dart
///
/// ⚠️ Widths come from `dashboard_grid_spec.dart` (D10).

/// One card the mobile grid draws.
class MobileCard {
  final DashboardCardType type;

  /// The period the card reads; null = the card has no period.
  final DashboardPeriod? period;

  /// Width in cells.
  final int width;

  const MobileCard({
    required this.type,
    required this.period,
    required this.width,
  });

  MobileCard copyWith({DashboardPeriod? period, int? width}) => MobileCard(
        type: type,
        period: period ?? this.period,
        width: width ?? this.width,
      );
}

/// First visit (D19): admin = the four counts + the two charts, others = the
/// four counts, in the D8 order.
const List<DashboardCardType> _defaultTypes = [
  DashboardCardType.paidOrders,
  DashboardCardType.newOrders,
  DashboardCardType.openClaims,
  DashboardCardType.unansweredInquiries,
  DashboardCardType.dailySalesChart,
  DashboardCardType.channelSalesChart,
];

/// Cards the member may see (D9), in the D8 order.
List<DashboardCardType> visibleTypes({required bool admin}) =>
    kDashboardCardSpecs.keys
        .where((type) => admin || !specOf(type).adminOnly)
        .toList();

/// A card with its first width and default period (D15).
MobileCard newCard(DashboardCardType type) => MobileCard(
      type: type,
      period: specOf(type).defaultPeriod,
      width: specOf(type).initialWidth,
    );

/// The largest allowed width at or below [stored]; the minimum when there is
/// none (D18).
int _shrink(DashboardCardType type, int stored) {
  final allowed = allowedWidths(type);
  final fitting = allowed.where((width) => width <= stored).toList();
  return fitting.isEmpty
      ? allowed.first
      : fitting.reduce((a, b) => a > b ? a : b);
}

/// Stored cards → the cards the grid draws (D9 · D11 · D18 · D19).
///
/// 1. Not saved yet → the default cards of the role (D19).
/// 2. Admin cards are dropped for a non-admin (D9).
/// 3. Cards with a mobile place come first by that place; a stored width the
///    spec does not have shrinks to the largest allowed width below it, not
///    under the minimum (D18).
/// 4. Cards without a mobile place (added on the web) follow in the D8 order
///    with their first width (D11).
List<MobileCard> toMobileCards(DashboardLayout layout) {
  if (!layout.saved) {
    return _defaultTypes
        .where((type) => layout.admin || !specOf(type).adminOnly)
        .map(newCard)
        .toList();
  }
  final visible = visibleTypes(admin: layout.admin).toSet();
  final shown =
      layout.cards.where((card) => visible.contains(card.cardType)).toList();
  final placed = shown
      .where((card) => card.mobileOrder != null && card.mobileW != null)
      .toList()
    ..sort((a, b) => a.mobileOrder!.compareTo(b.mobileOrder!));
  final unplaced = kDashboardCardSpecs.keys.where((type) => shown.any((card) =>
      card.cardType == type &&
      (card.mobileOrder == null || card.mobileW == null)));
  return [
    for (final card in placed)
      MobileCard(
        type: card.cardType,
        period: effectivePeriod(card.cardType, card.period),
        width: _shrink(card.cardType, card.mobileW!),
      ),
    for (final type in unplaced)
      newCard(type).copyWith(
        period: effectivePeriod(
          type,
          shown.firstWhere((card) => card.cardType == type).period,
        ),
      ),
  ];
}

/// Body of `PUT /api/dashboard/layout/mobile` — the place is the list index.
List<DashboardMobileCard> toMobileRequest(List<MobileCard> cards) => [
      for (var i = 0; i < cards.length; i++)
        DashboardMobileCard(
          cardType: cards[i].type,
          period: cards[i].period,
          order: i,
          width: cards[i].width,
        ),
    ];

/// [dragged] takes the place of [target]; the cards between move one step
/// (D16).
List<MobileCard> moveCard(List<MobileCard> cards, DashboardCardType dragged,
    DashboardCardType target) {
  final from = cards.indexWhere((card) => card.type == dragged);
  final to = cards.indexWhere((card) => card.type == target);
  if (from < 0 || to < 0 || from == to) {
    return cards;
  }
  final moved = [...cards];
  final card = moved.removeAt(from);
  moved.insert(to, card);
  return moved;
}

/// Cards in rows of [MobileGrid.columns] cells, filled in order; a card that
/// does not fit the rest of a row starts the next row (D24).
List<List<MobileCard>> toRows(List<MobileCard> cards) {
  final rows = <List<MobileCard>>[];
  var row = <MobileCard>[];
  var used = 0;
  for (final card in cards) {
    if (used + card.width > MobileGrid.columns) {
      rows.add(row);
      row = <MobileCard>[];
      used = 0;
    }
    row.add(card);
    used += card.width;
  }
  if (row.isNotEmpty) {
    rows.add(row);
  }
  return rows;
}

/// Dates of a period (D22 · D23), local `yyyy-MM-dd`.
SalesRange periodRange(DashboardPeriod period) {
  final today = DateTime.now();
  switch (period) {
    case DashboardPeriod.today:
      return (from: toDateText(today), to: toDateText(today));
    case DashboardPeriod.days7:
      return (
        from: toDateText(DateTime(today.year, today.month, today.day - 6)),
        to: toDateText(today),
      );
    case DashboardPeriod.days30:
      return (
        from: toDateText(DateTime(today.year, today.month, today.day - 29)),
        to: toDateText(today),
      );
    case DashboardPeriod.thisMonth:
      return currentMonthRange();
    case DashboardPeriod.lastMonth:
      return lastMonthRange();
  }
}
