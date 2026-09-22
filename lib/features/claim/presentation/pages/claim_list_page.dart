import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/claim_list_bloc.dart';
import '../bloc/claim_list_event.dart';
import '../bloc/claim_list_state.dart';
import '../widgets/claim_card.dart';
import '../widgets/claim_status_filter_bar.dart';
import '../widgets/claim_type_tabs.dart';

/// 주문관리 > 반품/교환 페이지 (FEATURE_2609_18 조회 + FEATURE_2609_70 동기화).
///
/// **기능**:
/// - 반품 / 교환 탭 전환 (`ClaimTypeTabs`) — **서버 재조회**를 부른다
/// - 판매자 / 기간 / 검색어를 고르고 [조회] 로 서버 재조회 (`GET /api/claims`)
/// - 상태 칩: 클라이언트 필터(건수 배지) — 서버를 부르지 않는다. 후보는 탭마다 다르다
/// - [동기화]: 동기화 대상 채널(판매자 필터로 좁혀진다)의 **반품·교환만** 가져온다
///   (`POST /api/claims/sync` — 2609_70 / D14). 끝나면 목록을 다시 조회한다
/// - 「마지막 동기화」: 채널들의 `lastClaimSyncAt` 중 가장 최근 값(D16). 없으면 줄을 안 그린다
/// - 카드 탭 → 클레임 상세(`extra` 전달, 상세 API 재조회 없음)
///
/// ⚠️ **처리 버튼(승인·입고확인)을 이 화면에 만들지 말 것** — 목록은 조회다. 처리 액션은
/// 상세의 `ClaimActionSheet` 가 서버 판정(`availableActions`)대로만 그린다(2609_21 D9).
/// 🔴 이 화면에 있는 유일한 쓰기 성격 버튼은 [동기화]이며, 그것도 마켓에서 **읽어오는** 동작이다.
/// ⚠️ **동기화 다이얼로그를 띄우지 않는다**(2609_70 / 04 Step 3) — 진행은 버튼 자리의 한 줄 +
/// 진행바다. `SyncProgressDialog` 는 `OrderListBloc` 을 직접 읽어 재사용할 수 없다.
/// ⚠️ 기간 드롭다운은 `buildPeriodOptions()` 를 **인자 없이** 부른다 —
/// 클레임에는 월별 건수 API 가 없어 '(데이터 없음)' 을 판정할 근거가 없다.
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
        // 재조회 실패·동기화 결과(기존 목록 유지)를 SnackBar 로 알린다.
        // ⚠️ 문구가 **바뀔 때만** 띄운다 — 같은 문구를 실은 상태가 연달아 emit 되면 SnackBar 가
        // 두 번 뜬다(고객문의 화면과 같은 가드).
        listenWhen: (prev, curr) =>
            curr is ClaimListLoaded &&
            _message(curr) != null &&
            _message(prev) != _message(curr),
        listener: (context, state) {
          final message = _message(state);
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
              ),
            );
        },
        builder: (context, state) {
          if (state is ClaimListInitial || state is ClaimListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClaimListError) {
            return _ErrorRetry(
              message: state.message,
              onRetry: () => context.read<ClaimListBloc>().add(LoadClaims()),
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

/// SnackBar 문구 — 실패([ClaimListLoaded.actionError])가 성공 요약보다 우선이다.
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

    return Padding(
      padding: const EdgeInsets.all(16),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: s.selectedSellerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: '판매자',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('전체'),
                            ),
                            ...s.sellers.map(
                              (Seller seller) => DropdownMenuItem<int?>(
                                value: seller.id,
                                child: Text(
                                  seller.sellerName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: busy
                              ? null
                              : (value) =>
                                  bloc.add(SelectSeller(sellerId: value)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            busy ? null : () => bloc.add(SearchClaims()),
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 기간 드롭다운 — 고른 값은 [조회] 를 눌러야 목록에 반영된다.
                  // ⚠️ monthsWithData 를 넘기지 않는다(= null) — 클레임엔 월별 건수 API 가 없어
                  // '(데이터 없음)' 을 붙이면 전 달이 거짓으로 표시된다.
                  DropdownButtonFormField<String>(
                    value: s.selectedPeriod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '기간',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: buildPeriodOptions()
                        .map((o) => DropdownMenuItem<String>(
                              value: o.value,
                              child: Text(
                                o.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: busy
                        ? null
                        : (value) => bloc.add(SelectPeriod(period: value!)),
                  ),
                  const SizedBox(height: 8),
                  // 검색어는 **서버로** 보낸다 — [조회] 를 눌러야 반영된다.
                  TextField(
                    controller: searchController,
                    enabled: !busy,
                    onChanged: (value) =>
                        bloc.add(ChangeSearchTerm(term: value)),
                    onSubmitted: (_) => busy ? null : bloc.add(SearchClaims()),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: '주문번호·접수번호·상품명 검색',
                      suffixIcon: s.searchTerm.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchController.clear();
                                bloc.add(ChangeSearchTerm(term: ''));
                              },
                            ),
                    ),
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

          Expanded(
            child: s.isSearching
                ? const Center(child: CircularProgressIndicator())
                : claims.isEmpty
                    ? Center(
                        child: Text(
                          // 문구 2종을 구분한다 — 칩으로 0건인지, 기간에 아예 없는지.
                          s.selectedStatus != null
                              ? '이 상태의 ${s.typeLabel}이 없습니다.'
                              : '해당 기간에 ${s.typeLabel} 내역이 없습니다.',
                        ),
                      )
                    : ListView.separated(
                        // ScaffoldWithNavBar 는 내비바를 오버레이하므로 하단 여백을 확보한다.
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight +
                              MediaQuery.paddingOf(context).bottom +
                              24,
                        ),
                        itemCount: claims.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            ClaimCard(claim: claims[index]),
                      ),
          ),
        ],
      ),
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

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
