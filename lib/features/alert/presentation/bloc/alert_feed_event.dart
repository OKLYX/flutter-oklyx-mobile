import '../../domain/entities/alert_feed_item.dart';

abstract class AlertFeedEvent {}

/// 첫 장 조회 — 화면 진입·당겨서 새로고침·[다시 시도].
///
/// [type] 이 null 이면 전체(세 소스 합본)다.
class LoadAlertFeed extends AlertFeedEvent {
  final AlertType? type;

  LoadAlertFeed({this.type});
}

/// 필터 칩 선택 — 서버 파라미터라 **첫 장부터** 재조회한다.
class ChangeAlertFilter extends AlertFeedEvent {
  final AlertType? type;

  ChangeAlertFilter(this.type);
}

/// 다음 장 이어 붙이기(무한 스크롤).
///
/// 🔴 커서를 인자로 받지 않는다 — 어디까지 봤는지는 **상태만** 안다.
class LoadMoreAlerts extends AlertFeedEvent {}
