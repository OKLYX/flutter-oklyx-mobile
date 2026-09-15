abstract class AlertSummaryEvent {}

/// 배지 숫자 갱신 — Drawer 가 열릴 때(`AppDrawer.initState`) 1회.
///
/// ⚠️ 인자가 없다. 배지는 전 테넌트 공통 카운트라 화면의 필터(판매자·기간)를 싣지 않는다.
class LoadAlertSummary extends AlertSummaryEvent {}
