import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';

/// Events of the dashboard BLoC (FEATURE_2610_29 / D2 · D3 · D16).
sealed class DashboardEvent {
  const DashboardEvent();
}

/// Screen entry and [다시 시도] — reads the stored cards.
class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

/// [편집] — cards can be moved, resized, added and removed until
/// [DashboardEditFinished].
class DashboardEditStarted extends DashboardEvent {
  const DashboardEditStarted();
}

/// A card dropped on another card — it takes that card's place.
class DashboardCardMoved extends DashboardEvent {
  final DashboardCardType dragged;
  final DashboardCardType target;
  const DashboardCardMoved({required this.dragged, required this.target});
}

/// The corner of a card dragged — its new width in cells.
class DashboardCardResized extends DashboardEvent {
  final DashboardCardType type;
  final int width;
  const DashboardCardResized({required this.type, required this.width});
}

/// A card picked in 「카드 넣기」 — added at the end.
class DashboardCardAdded extends DashboardEvent {
  final DashboardCardType type;
  const DashboardCardAdded(this.type);
}

/// ✕ on a card.
class DashboardCardRemoved extends DashboardEvent {
  final DashboardCardType type;
  const DashboardCardRemoved(this.type);
}

/// [편집 완료] — saves to the server; edit mode ends when it succeeds.
class DashboardEditFinished extends DashboardEvent {
  const DashboardEditFinished();
}

/// A period picked on a card outside edit mode — saved at once.
class DashboardPeriodChanged extends DashboardEvent {
  final DashboardCardType type;
  final DashboardPeriod period;
  const DashboardPeriodChanged({required this.type, required this.period});
}

/// A seller picked on a chart card — not saved (FEATURE_2610_30 / D36);
/// null = 「전체」.
class DashboardChartSellerChanged extends DashboardEvent {
  final DashboardCardType type;
  final int? sellerId;
  const DashboardChartSellerChanged({required this.type, this.sellerId});
}
