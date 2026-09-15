import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/alert_feed_item.dart';
import '../../domain/usecases/alert_usecase.dart';
import 'alert_feed_event.dart';
import 'alert_feed_state.dart';

/// 처리해야 할 일 목록 BLoC (FEATURE_2609_51).
///
/// **용도**: 알림 화면(`NotificationPage`)의 목록 — 새 주문·반품/교환·문의 합본 최신순.
/// **파일**: lib/features/alert/presentation/bloc/alert_feed_bloc.dart
///
/// 🔴 **factory 로 등록한다**(알림 화면 수명과 같이 간다). 배지의 `AlertSummaryBloc` 만
///    싱글턴이다 — 둘을 헷갈리지 말 것.
/// 🔴 **커서는 상태 안에만** 둔다 — 화면이 들고 다니면 "어디까지 봤는지"가 두 곳에 생긴다.
/// 🔴 정렬은 **서버가 준 최신순 그대로** 쓴다(화면에서 다시 정렬하지 않는다).
/// ⚠️ 다음 장 실패는 목록을 비우지 않는다 — 기존 행을 유지한 채 문구만 올린다.
class AlertFeedBloc extends Bloc<AlertFeedEvent, AlertFeedState> {
  /// 한 번에 읽는 행 수. 서버가 소스마다 이 크기로 읽으므로 키우면 읽는 양이 3배로 는다.
  static const int pageSize = 50;

  final AlertUseCase alertUseCase;

  AlertFeedBloc({required this.alertUseCase}) : super(AlertFeedInitial()) {
    on<LoadAlertFeed>(_onLoad);
    on<ChangeAlertFilter>(_onChangeFilter);
    on<LoadMoreAlerts>(_onLoadMore);
  }

  Future<void> _onLoad(
    LoadAlertFeed event,
    Emitter<AlertFeedState> emit,
  ) async {
    // 새로고침·[다시 시도] 는 화면이 이미 보여주던 필터를 유지한다.
    final filter = event.type ?? _currentFilter();
    await _loadFirstPage(emit, filter);
  }

  Future<void> _onChangeFilter(
    ChangeAlertFilter event,
    Emitter<AlertFeedState> emit,
  ) async {
    final current = state;
    if (current is AlertFeedLoaded && current.filter == event.type) return;
    await _loadFirstPage(emit, event.type);
  }

  Future<void> _onLoadMore(
    LoadMoreAlerts event,
    Emitter<AlertFeedState> emit,
  ) async {
    final current = state;
    if (current is! AlertFeedLoaded) return;
    // 🔴 마지막 장이거나 이미 읽는 중이면 즉시 반환 — 무한 스크롤은 같은 장을 두 번 요청하기 쉽다.
    if (current.nextCursor == null || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    final result = await alertUseCase.getFeed(
      type: current.filter,
      cursor: current.nextCursor,
      size: pageSize,
    );
    if (emit.isDone) return;

    emit(result.fold(
      // 보던 목록을 지우지 않는다 — 문구만 올리고 커서는 그대로 둔다(재시도 가능).
      (failure) => current.copyWith(
        isLoadingMore: false,
        loadMoreError: failure.message,
      ),
      (page) => current.copyWith(
        items: [...current.items, ...page.items],
        nextCursor: page.nextCursor,
        clearNextCursor: page.nextCursor == null,
        isLoadingMore: false,
      ),
    ));
  }

  /// 첫 장 조회 — 진입·새로고침·필터 전환이 같은 경로를 쓴다.
  Future<void> _loadFirstPage(
    Emitter<AlertFeedState> emit,
    AlertType? filter,
  ) async {
    emit(AlertFeedLoading(filter: filter));

    final result = await alertUseCase.getFeed(type: filter, size: pageSize);
    if (emit.isDone) return;

    emit(result.fold(
      (failure) => AlertFeedError(message: failure.message),
      (page) => AlertFeedLoaded(
        items: page.items,
        filter: filter,
        nextCursor: page.nextCursor,
      ),
    ));
  }

  /// 현재 화면이 보고 있던 필터(없으면 전체).
  AlertType? _currentFilter() {
    final current = state;
    if (current is AlertFeedLoaded) return current.filter;
    if (current is AlertFeedLoading) return current.filter;
    return null;
  }
}
