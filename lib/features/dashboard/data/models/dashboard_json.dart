// JSON <-> dashboard entities — the file of this feature that knows the JSON
// keys (keys = the web `DashboardEntity.ts` field names).
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';

typedef Json = Map<String, dynamic>;

int? _intN(Object? v) => (v as num?)?.toInt();

/// One stored card; an unknown card type = null (dropped by the caller).
DashboardCardSetting? dashboardCardFromJson(Json j) {
  final type = DashboardCardType.fromWire(j['cardType']);
  if (type == null) {
    return null;
  }
  return DashboardCardSetting(
    cardType: type,
    period: DashboardPeriod.fromWire(j['period']),
    mobileOrder: _intN(j['mobileOrder']),
    mobileW: _intN(j['mobileW']),
  );
}

DashboardLayout dashboardLayoutFromJson(Json j) {
  final cards = j['cards'];
  return DashboardLayout(
    admin: j['admin'] == true,
    saved: j['saved'] == true,
    cards: cards is List
        ? cards
            .whereType<Json>()
            .map(dashboardCardFromJson)
            .whereType<DashboardCardSetting>()
            .toList()
        : const [],
  );
}

Json dashboardMobileCardToJson(DashboardMobileCard card) => <String, dynamic>{
      'cardType': card.cardType.wire,
      'period': card.period?.wire,
      'order': card.order,
      'w': card.width,
    };
