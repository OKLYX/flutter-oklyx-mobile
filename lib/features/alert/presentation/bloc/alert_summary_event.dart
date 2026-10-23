abstract class AlertSummaryEvent {}

/// Refresh the badge numbers — sent once by `AppDrawer.initState`,
/// `ScaffoldWithNavBar.initState`, the notification page refresh and
/// `DashboardPage.initState`.
///
/// ⚠️ No arguments. The badges are tenant-wide counts, so screen filters
/// (seller, period) are not carried.
class LoadAlertSummary extends AlertSummaryEvent {}
