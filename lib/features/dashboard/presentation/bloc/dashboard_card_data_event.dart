/// Event of `DashboardCardDataBloc` (FEATURE_2610_29 / D20).
sealed class DashboardCardDataEvent {
  const DashboardCardDataEvent();
}

/// Card shown — reads its data once (no polling, D20).
class DashboardCardDataRequested extends DashboardCardDataEvent {
  const DashboardCardDataRequested();
}
