import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/claim_list_bloc.dart';
import '../bloc/claim_list_event.dart';
import '../bloc/claim_list_state.dart';
import '../widgets/claim_card.dart';
import '../widgets/claim_status_filter_bar.dart';
import '../widgets/claim_type_tabs.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';

/// 「주문관리 > 반품/교환」 page (FEATURE_2609_18 lookup + FEATURE_2609_70
/// sync).
///
/// **Features**:
/// - Return / exchange tabs (`ClaimTypeTabs`) — **reload from the server**
/// - Pick seller / period / search text, then [조회] reloads from the server
///   (`GET /api/claims`)
/// - Status chips: client filter (count badges) — no server call. The
///   choices differ per tab
/// - [동기화]: fetches **returns and exchanges only** for the sync target
///   channels (narrowed by the seller filter) (`POST /api/claims/sync` —
///   2609_70 / D14). Reloads the list when done
/// - 「마지막 동기화」: the latest `lastClaimSyncAt` of the channels (D16). No
///   line when there is none
/// - Card tap → claim detail (`extra`, the detail API is not called again)
///
/// ⚠️ **Do not put action buttons (approve · confirm receipt) on this page** —
/// the list is for lookup. Actions are drawn only by `ClaimActionSheet` of the
/// detail, following the server decision (`availableActions`) (2609_21 D9).
/// 🔴 The only write-like button on this page is [동기화], and it also only
/// **reads** from the marketplace.
/// ⚠️ **No sync dialog** (2609_70 / 04 Step 3) — progress is one line + a
/// progress bar in place of the button. `SyncProgressDialog` reads
/// `OrderListBloc` directly and cannot be reused.
/// ⚠️ The period chip calls `buildPeriodOptions()` **without arguments** —
/// claims have no monthly count API, so there is no ground to mark a month
/// '(데이터 없음)'.
class ClaimListPage extends StatelessWidget {
  const ClaimListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClaimListBloc>()..add(LoadClaims()),
      child: const _ClaimListView(),
    );
  }
}

class _ClaimListView extends StatefulWidget {
  const _ClaimListView();

  @override
  State<_ClaimListView> createState() => _ClaimListViewState();
}

class _ClaimListViewState extends State<_ClaimListView> {
  /// 검색어 입력 컨트롤러. ⚠️ [_LoadedBody] 안에서 만들면 rebuild 마다 커서가 튄다 —
  /// 여기(State)에서 만들어 주입한다.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 메뉴 일관성: 주문내역과 같은 navBarIndex·Drawer 버튼 노출.
    return ScaffoldWithNavBar(
      title: '반품/교환',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<ClaimListBloc, ClaimListState>(
        // Reload failures and sync results (the current list is kept) are
        // reported with a toast.
        // ⚠️ Shown **only when the text changes** — when states carrying the
        // same text are emitted in a row the toast shows twice (same guard as
        // the customer inquiry screen).
        listenWhen: (prev, curr) =>
            curr is ClaimListLoaded &&
            _message(curr) != null &&
            _message(prev) != _message(curr),
        listener: (context, state) {
          final message = _message(state);
          if (message == null) return;
          // actionError = failure, syncSummary = success (one field each).
          if ((state as ClaimListLoaded).actionError != null) {
            showErrorToast(context, message);
          } else {
            showSuccessToast(context, message);
          }
        },
        builder: (context, state) {
          if (state is ClaimListInitial || state is ClaimListLoading) {
            return const AppPageBody(children: [AppLoading()]);
          }

          if (state is ClaimListError) {
            return AppPageBody(
              children: [
                AppErrorBox(
                  message: state.message,
                  action: FilledButton(
                    onPressed: () => context.read<ClaimListBloc>().add(LoadClaims()),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            );
          }

          return _LoadedBody(
            state: state as ClaimListLoaded,
            searchController: _searchController,
          );
        },
      ),
    );
  }
}

/// Toast text — the failure ([ClaimListLoaded.actionError]) takes precedence
/// over the success summary.
String? _message(ClaimListState state) {
  if (state is! ClaimListLoaded) return null;
  return state.actionError ?? state.syncSummary;
}

class _LoadedBody extends StatelessWidget {
  final ClaimListLoaded state;
  final TextEditingController searchController;

  const _LoadedBody({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final bloc = context.read<ClaimListBloc>();
    final claims = s.visible;
    // 조회·동기화 중에는 컨트롤을 잠근다(둘 다 서버 왕복이다).
    final busy = s.busy;

    return AppPageBody.slivers(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 반품 ↔ 교환 — 칩과 달리 서버를 다시 부른다(조회 중에는 잠근다).
          ClaimTypeTabs(
            value: s.claimType,
            enabled: !busy,
            onChanged: (t) => bloc.add(SelectClaimType(type: t)),
          ),
          const SizedBox(height: 12),
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
                              // Period chip — the picked value reaches the list
                              // only with [조회].
                              // ⚠️ No monthsWithData (= null) — claims have no
                              // monthly count API, and '(데이터 없음)' would
                              // falsely mark every month.
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
                            busy ? null : () => bloc.add(SearchClaims()),
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 검색어는 **서버로** 보낸다 — [조회] 를 눌러야 반영된다.
                  AppSearchField(
                    controller: searchController,
                    hintText: '주문번호·접수번호·상품명 검색',
                    enabled: !busy,
                    onChanged: (value) =>
                        bloc.add(ChangeSearchTerm(term: value)),
                    onSubmitted: (_) => busy ? null : bloc.add(SearchClaims()),
                  ),
                  const SizedBox(height: 8),
                  // 동기화 — 진행은 이 자리의 한 줄이다(다이얼로그 금지).
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
                                : () => bloc.add(SyncClaims()),
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
          // 후보 목록은 탭마다 다르다(state 파생 — 화면이 분기를 들지 않는다).
          ClaimStatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: s.statusCounts,
            statuses: s.statusFilters,
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${claims.length}건',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              // 값이 없으면(한 번도 가져온 적 없는 채널들) 줄을 그리지 않는다 —
              // '기록 없음' 을 띄우면 실패한 것처럼 읽힌다(주문내역과 같은 자세).
              if (s.lastClaimSyncedAt != null)
                Text(
                  '마지막 동기화: ${formatRelativeTime(s.lastClaimSyncedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
          ),
        ),
        if (s.isSearching)
          const SliverToBoxAdapter(child: AppLoading())
        else if (claims.isEmpty)
          SliverToBoxAdapter(
            child: AppEmpty(
              // 문구 2종을 구분한다 — 칩으로 0건인지, 기간에 아예 없는지.
              s.selectedStatus != null
                  ? '이 상태의 ${s.typeLabel}이 없습니다.'
                  : '해당 기간에 ${s.typeLabel} 내역이 없습니다.',
            ),
          )
        else
          SliverList.separated(
            itemCount: claims.length,
            separatorBuilder: (_, __) => const AppRowGap(),
            itemBuilder: (context, index) => ClaimCard(claim: claims[index]),
          ),
      ],
    );
  }
}

/// 동기화 진행 한 줄 + 진행바.
/// 🔴 다이얼로그를 쓰지 않는 이유는 페이지 주석 참고(고객문의 화면과 같은 구성).
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
