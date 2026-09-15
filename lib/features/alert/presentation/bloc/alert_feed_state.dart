import '../../domain/entities/alert_feed_item.dart';

/// 알림 목록 상태 (FEATURE_2609_51).
///
/// 🔴 배지 상태(`AlertSummaryState`)와 달리 이쪽은 저장소의 **Initial/Loading/Loaded/Error
/// 관례를 그대로 따른다** — 목록은 실패하면 실패라고 말해야 한다(배지는 직전 값을 유지한다).
abstract class AlertFeedState {}

class AlertFeedInitial extends AlertFeedState {}

class AlertFeedLoading extends AlertFeedState {
  /// 조회 중인 필터. 🔴 Loading 이 필터를 들고 있어야 재조회 동안 칩 선택이 풀리지 않는다.
  final AlertType? filter;

  AlertFeedLoading({this.filter});
}

class AlertFeedLoaded extends AlertFeedState {
  /// 서버가 준 **최신순 그대로**. 🔴 화면에서 다시 정렬하지 않는다.
  final List<AlertFeedItem> items;

  /// 선택된 필터 칩. null = 전체.
  final AlertType? filter;

  /// 다음 장 커서. null 이면 마지막 장이다(불투명 문자열 — 해석 금지).
  final String? nextCursor;

  /// 다음 장을 읽는 중. 같은 장을 두 번 요청하지 않게 막는 빗장이다.
  final bool isLoadingMore;

  /// 다음 장 조회 실패 문구 — 목록을 비우지 않고 SnackBar 한 줄로만 알린다.
  final String? loadMoreError;

  AlertFeedLoaded({
    required this.items,
    this.filter,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => nextCursor != null;

  AlertFeedLoaded copyWith({
    List<AlertFeedItem>? items,
    AlertType? filter,
    bool clearFilter = false,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) =>
      AlertFeedLoaded(
        items: items ?? this.items,
        filter: clearFilter ? null : (filter ?? this.filter),
        nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError:
            clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      );
}

class AlertFeedError extends AlertFeedState {
  final String message;

  AlertFeedError({required this.message});
}
