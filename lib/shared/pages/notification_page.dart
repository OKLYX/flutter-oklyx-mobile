import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/alert/domain/entities/alert_feed_item.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_feed_bloc.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_feed_event.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_feed_state.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_bloc.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_event.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_state.dart';
import 'package:flutter_oklyn_mobile/features/claim/domain/usecases/claim_usecase.dart';
import 'package:flutter_oklyn_mobile/features/inquiry/domain/usecases/inquiry_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/widgets/platform_options.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// 알림 화면 = 처리해야 할 일 목록 (FEATURE_2609_51).
///
/// **용도**: 결제완료 주문·미완결 반품/교환·미답변 문의를 한 화면에서 보고 그 건으로 바로 이동한다.
/// **파일**: lib/shared/pages/notification_page.dart
///
/// 🔴 확인·읽음 버튼이 없다(D2). 일이 처리되면(발주처리·클레임 종결·문의 답변) 다음 조회에서
///    저절로 빠진다 — 목록을 손으로 비우는 수단을 만들지 말 것.
/// ❌ 화면 문구에 `미처리`·`미확인` 을 쓰지 말 것 — `처리해야 할 일` 로 통일한다(D4).
/// ⚠️ 이 화면이 **모바일의 알림 센터**다(D13) — 별도 알림 화면을 새로 만들지 않는다.
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<AlertFeedBloc>()..add(LoadAlertFeed()),
        child: const _NotificationView(),
      );
}

class _NotificationView extends StatefulWidget {
  const _NotificationView();

  @override
  State<_NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<_NotificationView> {
  /// 무한 스크롤 컨트롤러 — 화면(State)이 소유하고 [dispose] 한다(판매상품 조회와 같은 모양).
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      // 마지막 장·중복 요청 판정은 BLoC 이 한다(커서는 상태 안에만 있다).
      context.read<AlertFeedBloc>().add(LoadMoreAlerts());
    }
  }

  /// 당겨서 새로고침 — 목록과 배지 숫자를 같이 맞춘다(발주처리·답변 뒤 둘 다 줄어야 한다).
  Future<void> _refresh() async {
    context.read<AlertFeedBloc>().add(LoadAlertFeed());
    context.read<AlertSummaryBloc>().add(LoadAlertSummary());
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '알림',
        navBarIndex: 3,
        showDrawer: true,
        showAppBarDrawerButton: false,
        body: BlocConsumer<AlertFeedBloc, AlertFeedState>(
          // 다음 장 실패만 SnackBar 로 알린다 — 보던 목록은 그대로 둔다.
          listenWhen: (prev, curr) =>
              curr is AlertFeedLoaded &&
              curr.loadMoreError != null &&
              _loadMoreError(prev) != curr.loadMoreError,
          listener: (context, state) {
            final message = _loadMoreError(state);
            if (message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
              ),
            );
          },
          builder: (context, state) => Column(
            children: [
              _FilterBar(filter: _filterOf(state)),
              Expanded(child: _body(context, state)),
            ],
          ),
        ),
      );

  Widget _body(BuildContext context, AlertFeedState state) {
    if (state is AlertFeedLoading || state is AlertFeedInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AlertFeedError) {
      return _ErrorBody(message: state.message);
    }
    final loaded = state as AlertFeedLoaded;
    final bottomInset =
        kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom;

    if (loaded.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        // 비어 있어도 당겨서 새로고침이 되게 스크롤 가능한 목록으로 감싼다.
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
            const Center(child: Text('처리해야 할 일이 없습니다.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 16),
        // 마지막 장이면 꼬리를 그리지 않는다 — `모두 확인했습니다` 같은 문구는 할 일이
        // 끝났다는 오해를 준다. 읽는 중일 때만 스피너 한 줄.
        itemCount: loaded.items.length + (loaded.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= loaded.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = loaded.items[index];
          return _AlertCard(item: item, onTap: () => _open(item));
        },
      ),
    );
  }

  /// 행 탭 → 대상을 **먼저 가져와** 기존 상세 화면에 넘긴다(D9). route 는 손대지 않는다.
  Future<void> _open(AlertFeedItem item) async {
    switch (item.alertType) {
      case AlertType.claim:
        final result = await getIt<ClaimUseCase>().getClaim(item.refId);
        if (!mounted) return;
        result.fold(
          _showError,
          (claim) => context.push(Routes.claimDetailPath, extra: claim),
        );
        break;
      case AlertType.inquiry:
        final result = await getIt<InquiryUseCase>().getInquiry(item.refId);
        if (!mounted) return;
        result.fold(
          _showError,
          // 상세는 진입 후 어차피 단건 조회를 다시 한다 — extra 는 헤더 즉시 표시용이다.
          (detail) =>
              context.push(Routes.inquiryDetailPath, extra: detail.inquiry),
        );
        break;
      case AlertType.order:
        // 출고관리로 이동만 한다(D9) — 검색어는 넘기지 않는다(화면이 자기 BLoC 을 새로 만드는
        // 구조라 배선이 늘고, 목록이 14일 창이라 새 주문이 맨 위에 있다).
        context.go(Routes.shipmentManagementPath);
        break;
    }
  }

  /// 조회 실패는 한 줄로 알리고 **이동하지 않는다**(`extra: null` 은 "정보를 찾을 수 없습니다" 화면이 된다).
  void _showError(Failure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure.message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
      ),
    );
  }

  static AlertType? _filterOf(AlertFeedState state) {
    if (state is AlertFeedLoaded) return state.filter;
    if (state is AlertFeedLoading) return state.filter;
    return null;
  }

  static String? _loadMoreError(AlertFeedState state) =>
      state is AlertFeedLoaded ? state.loadMoreError : null;
}

/// 필터 칩 4개 + 처리해야 할 일 건수.
class _FilterBar extends StatelessWidget {
  final AlertType? filter;

  const _FilterBar({required this.filter});

  @override
  Widget build(BuildContext context) {
    const options = <(AlertType?, String)>[
      (null, '전체'),
      (AlertType.order, '새 주문'),
      (AlertType.claim, '반품/교환'),
      (AlertType.inquiry, '문의'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in options)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(option.$2),
                        selected: filter == option.$1,
                        onSelected: (_) => context
                            .read<AlertFeedBloc>()
                            .add(ChangeAlertFilter(option.$1)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 🔴 목록 길이가 아니라 배지와 같은 숫자를 쓴다 — 목록은 한 장씩 읽어 오므로
          //    화면에 그려진 행 수가 전체 건수가 아니다(D3).
          BlocBuilder<AlertSummaryBloc, AlertSummaryState>(
            builder: (context, alerts) => Text(
              '처리해야 할 일 ${alerts.todoCount}건',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 알림 1건 카드.
class _AlertCard extends StatelessWidget {
  final AlertFeedItem item;
  final VoidCallback onTap;

  const _AlertCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = item.detail?.trim();
    final title = item.itemName?.trim();
    final showItemCount = item.itemCount != null && item.itemCount! > 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _typeLabel(item),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title == null || title.isEmpty ? '상품 정보 없음' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showItemCount) ...[
                    const SizedBox(width: 6),
                    Text(
                      '상품 ${item.itemCount}개',
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(item),
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _typeLabel(AlertFeedItem item) {
    switch (item.alertType) {
      case AlertType.order:
        return '새 주문';
      case AlertType.claim:
        return item.claimType == 'EXCHANGE' ? '교환' : '반품';
      case AlertType.inquiry:
        return '문의';
    }
  }

  /// '쿠팡 · 판매자명 · 3시간 전' — 🔴 시각은 마켓 KST 전용 함수를 쓴다(D8).
  static String _subtitle(AlertFeedItem item) {
    final parts = <String>[
      if (item.platform.isNotEmpty) platformLabel(item.platform),
      if (item.sellerName != null && item.sellerName!.isNotEmpty)
        item.sellerName!,
      formatMarketRelativeTime(item.occurredAt),
    ];
    return parts.join(' · ');
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;

  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    context.read<AlertFeedBloc>().add(LoadAlertFeed()),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
}
