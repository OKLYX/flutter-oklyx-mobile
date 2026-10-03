import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/inquiry.dart';
import '../bloc/inquiry_list_bloc.dart';
import '../bloc/inquiry_list_event.dart';
import '../bloc/inquiry_list_state.dart';
import '../widgets/inquiry_card.dart';
import '../widgets/inquiry_status_filter_bar.dart';
import '../widgets/inquiry_type_tabs.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';

/// 「주문관리 > 고객문의」 page (FEATURE_2609_36 — lookup + fetching inquiries
/// only).
///
/// **Features**:
/// - Type tabs (`InquiryTypeTabs`) — the choices and labels come from the
///   server `/types` (PLAN M2). **Reloads from the server**
/// - Pick seller / channel / period / search text, then [조회] reloads
///   (`GET /api/inquiries`)
/// - Status chips: client filter (count badges) — no server call
/// - [동기화]: fetches **inquiries only** for the picked channel (all when
///   none) (`POST /api/inquiries/sync`)
/// - Card tap → inquiry detail (`extra` + the detail API is called again, M1)
///
/// ⚠️ **No sync dialog** (M4) — progress is one line + a progress bar in place
/// of the button. `SyncProgressDialog` reads `OrderListBloc` directly and
/// cannot be reused.
/// ⚠️ **The channel chip offers the sync targets only** (M12) — the union
/// rule of the order history (2609_15 D7-a) belongs to that page only.
/// ⚠️ The period chip calls `buildPeriodOptions()` **without arguments** (M9)
/// — inquiries have no monthly count API, so there is no ground to mark a
/// month '(데이터 없음)'.
/// ❌ Do not add a reply button or input — replies are a separate scope.
class InquiryListPage extends StatelessWidget {
  const InquiryListPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<InquiryListBloc>()..add(LoadInquiries()),
        child: const _InquiryListView(),
      );
}

class _InquiryListView extends StatefulWidget {
  const _InquiryListView();

  @override
  State<_InquiryListView> createState() => _InquiryListViewState();
}

class _InquiryListViewState extends State<_InquiryListView> {
  /// 검색어 입력 컨트롤러. ⚠️ [_LoadedBody] 안에서 만들면 rebuild 마다 커서가 튄다 —
  /// 여기(State)에서 만들어 주입한다.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      // 메뉴 일관성: 주문내역·반품/교환과 같은 navBarIndex·Drawer 버튼 노출.
      ScaffoldWithNavBar(
        title: '고객문의',
        navBarIndex: 2,
        showDrawer: true,
        showAppBarDrawerButton: false,
        body: BlocConsumer<InquiryListBloc, InquiryListState>(
          // Only reload / sync results (the current list is kept) are reported
          // with a toast.
          // ⚠️ Shown **only when the text changes** — the reload after a sync
          // emits a state carrying the same text once more, so looking at curr
          // alone would show the same toast twice.
          listenWhen: (prev, curr) =>
              curr is InquiryListLoaded &&
              _message(curr) != null &&
              _message(prev) != _message(curr),
          listener: (context, state) {
            final message = _message(state);
            if (message == null) return;
            // actionError = failure, syncSummary = success (one field each).
            if ((state as InquiryListLoaded).actionError != null) {
              showErrorToast(context, message);
            } else {
              showSuccessToast(context, message);
            }
            // 같은 문구가 다음 rebuild 에서 다시 뜨지 않게 소비 후 비운다.
            context.read<InquiryListBloc>().add(ActionErrorCleared());
          },
          builder: (context, state) {
            if (state is InquiryListInitial || state is InquiryListLoading) {
              return const AppPageBody(children: [AppLoading()]);
            }

            if (state is InquiryListError) {
              return AppPageBody(
                children: [
                  AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () => context.read<InquiryListBloc>().add(LoadInquiries()),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              );
            }

            return _LoadedBody(
              state: state as InquiryListLoaded,
              searchController: _searchController,
            );
          },
        ),
      );
}

/// Toast text — the failure ([InquiryListLoaded.actionError]) takes precedence
/// over the success summary.
String? _message(InquiryListState state) {
  if (state is! InquiryListLoaded) return null;
  return state.actionError ?? state.syncSummary;
}

class _LoadedBody extends StatelessWidget {
  final InquiryListLoaded state;
  final TextEditingController searchController;

  const _LoadedBody({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final bloc = context.read<InquiryListBloc>();
    final inquiries = s.visible;
    final busy = s.busy;

    // 🔴 채널 옵션 = 동기화 대상뿐이다(M12). 목록에만 있는 계정 id 를 합치지 않는다.
    final accountOptions = <int, String>{
      for (final target in s.syncTargets)
        target.accountId:
            inquiryChannelLabel(target.accountId, target.accountAlias),
    };
    // When the picked channel is no longer an option, fall back to all
    // channels (the BLoC also clears it when the seller changes, but a frame
    // can come in between).
    final accountValue = accountOptions.containsKey(s.selectedAccountId)
        ? s.selectedAccountId
        : null;

    return AppPageBody.slivers(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유형 탭 — 칩과 달리 서버를 다시 부른다(조회 중에는 잠근다).
          // 후보가 1개 이하면 위젯이 스스로 아무것도 그리지 않는다.
          InquiryTypeTabs(
            options: s.typeOptions,
            value: s.selectedType,
            enabled: !busy,
            onChanged: (type) => bloc.add(SelectType(type: type)),
          ),
          if (s.typeOptions.length > 1) const SizedBox(height: 12),
          AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              AppFilterChip<int?>(
                                label: s.sellers
                                        .where((seller) =>
                                            seller.id == s.selectedSellerId)
                                        .firstOrNull
                                        ?.sellerName ??
                                    '판매자',
                                value: s.selectedSellerId,
                                options: [
                                  const AppFilterOption(null, '전체'),
                                  for (final seller in s.sellers)
                                    AppFilterOption(
                                        seller.id, seller.sellerName),
                                ],
                                highlighted: s.selectedSellerId != null,
                                onSelected: busy
                                    ? null
                                    : (value) =>
                                        bloc.add(SelectSeller(sellerId: value)),
                              ),
                              const SizedBox(width: 8),
                              // 채널 필터 — 옵션은 동기화 대상뿐(M12). 판매자를 바꾸면 좁아진다.
                              AppFilterChip<int?>(
                                label: accountValue == null
                                    ? '채널'
                                    : accountOptions[accountValue]!,
                                value: accountValue,
                                options: [
                                  const AppFilterOption(null, '전체'),
                                  for (final entry in accountOptions.entries)
                                    AppFilterOption(entry.key, entry.value),
                                ],
                                highlighted: accountValue != null,
                                onSelected: busy
                                    ? null
                                    : (value) =>
                                        bloc.add(SelectChannel(accountId: value)),
                              ),
                              const SizedBox(width: 8),
                              // Period chip — the picked value reaches the list
                              // only with [조회].
                              // ⚠️ No monthsWithData (= null) — inquiries have
                              // no monthly count API, and '(데이터 없음)' would
                              // falsely mark every month (M9).
                              AppFilterChip<String>(
                                label: buildPeriodOptions()
                                        .where(
                                            (o) => o.value == s.selectedPeriod)
                                        .firstOrNull
                                        ?.label ??
                                    s.selectedPeriod,
                                value: s.selectedPeriod,
                                options: [
                                  for (final o in buildPeriodOptions())
                                    AppFilterOption(o.value, o.label),
                                ],
                                highlighted: s.selectedPeriod != kRecentPeriod,
                                onSelected: busy
                                    ? null
                                    : (value) =>
                                        bloc.add(SelectPeriod(period: value)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed:
                            busy ? null : () => bloc.add(SearchInquiries()),
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 검색어는 **서버로** 보낸다 — [조회] 를 눌러야 반영된다.
                  AppSearchField(
                    controller: searchController,
                    hintText: '문의 내용·상품명·주문번호 검색',
                    enabled: !busy,
                    onChanged: (value) =>
                        bloc.add(ChangeSearchTerm(term: value)),
                    onSubmitted: (_) =>
                        busy ? null : bloc.add(SearchInquiries()),
                  ),
                  const SizedBox(height: 8),
                  // 동기화 — 진행은 이 자리의 한 줄이다(다이얼로그 금지, M4).
                  if (s.isSyncing)
                    _SyncProgress(
                      done: s.syncDone,
                      total: s.syncTotal,
                      channelName: s.syncingChannelName,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: busy || s.syncTargets.isEmpty
                                ? null
                                : () => bloc.add(SyncInquiries()),
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text('동기화'),
                          ),
                        ),
                      ],
                    ),
                  // 대상이 없으면 버튼이 왜 꺼져 있는지 한 줄로 알린다.
                  if (!s.isSyncing && s.syncTargets.isEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '가져올 채널이 없습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ),
          const SizedBox(height: 8),

          // 상태 칩 — 클라이언트 필터. 같은 칩 재선택 시 전체 해제.
          InquiryStatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: s.statusCounts,
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
          ),
          const SizedBox(height: 8),

          Text(
            '총 ${inquiries.length}건',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
          ),
        ),
        if (s.isSearching)
          const SliverToBoxAdapter(child: AppLoading())
        else if (inquiries.isEmpty)
          SliverToBoxAdapter(
            child: AppEmpty(
              // 문구 2종을 구분한다 — 칩으로 0건인지, 기간에 아예 없는지.
              s.selectedStatus != null
                  ? '이 상태의 문의가 없습니다.'
                  : '해당 기간에 문의가 없습니다.',
            ),
          )
        else
          SliverList.separated(
            itemCount: inquiries.length,
            separatorBuilder: (_, __) => const AppRowGap(),
            itemBuilder: (context, index) {
              final inquiry = inquiries[index];
              return InquiryCard(
                inquiry: inquiry,
                // 상세는 진입 후 단건 API 를 다시 부른다 — `extra` 는 헤더를
                // 먼저 그리기 위한 것이다(M1).
                onTap: () => context.push(
                  Routes.inquiryDetailPath,
                  extra: inquiry,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// 동기화 진행 한 줄 + 진행바 (M4 — 다이얼로그를 쓰지 않는 이유는 페이지 주석 참고).
class _SyncProgress extends StatelessWidget {
  final int done;
  final int total;
  final String? channelName;

  const _SyncProgress({
    required this.done,
    required this.total,
    this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    // 진행 중인 채널은 done + 1 번째다(끝난 개수 + 1).
    final current = total == 0 ? 0 : (done + 1).clamp(1, total);
    final name = channelName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '동기화 중 ($current/$total)${name == null ? '' : ' · $name'}',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total == 0 ? null : done / total,
        ),
      ],
    );
  }
}
