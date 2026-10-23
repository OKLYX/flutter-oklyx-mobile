/// Dashboard entities (FEATURE_2610_29 / D6 · D8 · D11) — the mobile twin of
/// the web `DashboardEntity.ts`. Wire names = the server enum names.
///
/// 🔴 The card list and each card's period are shared by web and mobile; the
/// place and size are stored per platform (D11). A platform's fields are null
/// until that platform saves the card.
library;

/// The cards a dashboard can show, in the D8 order.
enum DashboardCardType {
  paidOrders('PAID_ORDERS'),
  newOrders('NEW_ORDERS'),
  openClaims('OPEN_CLAIMS'),
  unansweredInquiries('UNANSWERED_INQUIRIES'),
  periodSales('PERIOD_SALES'),
  settlementPayouts('SETTLEMENT_PAYOUTS'),
  purchaseList('PURCHASE_LIST'),
  reservedShipments('RESERVED_SHIPMENTS'),
  dailySalesChart('DAILY_SALES_CHART'),
  channelSalesChart('CHANNEL_SALES_CHART');

  /// Server name.
  final String wire;

  const DashboardCardType(this.wire);

  /// Server name → card; an unknown name = null (a newer server card).
  static DashboardCardType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wire == value) {
        return type;
      }
    }
    return null;
  }
}

/// Period a card reads (D22 · D23).
enum DashboardPeriod {
  today('TODAY'),
  days7('DAYS_7'),
  days30('DAYS_30'),
  thisMonth('THIS_MONTH');

  /// Server name.
  final String wire;

  const DashboardPeriod(this.wire);

  /// Server name → period; anything else = null.
  static DashboardPeriod? fromWire(Object? value) {
    for (final period in values) {
      if (period.wire == value) {
        return period;
      }
    }
    return null;
  }
}

/// One stored card.
class DashboardCardSetting {
  final DashboardCardType cardType;

  /// null = the card's default period, or the card has no period.
  final DashboardPeriod? period;
  final int? mobileOrder;
  final int? mobileW;

  const DashboardCardSetting({
    required this.cardType,
    required this.period,
    required this.mobileOrder,
    required this.mobileW,
  });
}

/// `GET /api/dashboard/layout`.
class DashboardLayout {
  /// true = ADMIN — the admin cards are shown then (D9).
  final bool admin;

  /// false = not saved yet; [cards] is empty and the screen draws the default
  /// cards (D19).
  final bool saved;
  final List<DashboardCardSetting> cards;

  const DashboardLayout({
    required this.admin,
    required this.saved,
    required this.cards,
  });
}

/// One card of `PUT /api/dashboard/layout/mobile` — place in the card order
/// and width in cells.
class DashboardMobileCard {
  final DashboardCardType cardType;
  final DashboardPeriod? period;
  final int order;
  final int width;

  const DashboardMobileCard({
    required this.cardType,
    required this.period,
    required this.order,
    required this.width,
  });
}
