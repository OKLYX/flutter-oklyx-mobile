import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_period.dart';
import '../../domain/entities/sync_target.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_filter_bar.dart';
import '../widgets/sync_progress_dialog.dart';

/// 주문관리 > 주문내역 페이지 (조회 + 동기화)
///
/// **용도**: Coupang 등 외부 마켓플레이스에서 동기화된 주문 목록 조회 및 동기화.
/// 프론트엔드 주문관리 > 주문내역(dashboard/orders)을 모바일로 이식.
///
/// **기능(Frontend OrderContainer와 동일)**:
/// - 판매자 필터 드롭다운 (기존 seller 기능 재사용)
/// - 조회: GET /api/orders?sellerId=
/// - 동기화: 대상 채널 조회 → 계정 단위 순차 호출. 진행 다이얼로그([SyncProgressDialog])로
///   차단 표시하고, 끝나면 신규/수정/취소 건수 배너 + 채널 상태 배너를 표시
/// - 상태 필터: 6개 상태 버튼(건수 배지) — 선택 상태만 표시, 재선택 시 전체
/// - 채널(계정) 필터: 목록과 동기화 범위를 함께 좁힌다(PLAN 2609_15 D7)
/// - 카드 항목(프론트 OrderTable과 동일): 주문번호 / 상품명 / 주문수량 / 취소 / 결제일
///
/// ⚠️ 이 화면은 **조회 전용**이다. 주문목록 다운로드·발송처리는 출고관리
/// ([ShipmentManagementPage])로 옮겼다(PLAN 2609_15 D4) — 여기에 되돌려 놓지 말 것.
/// 주문 상세의 단건 발송처리 섹션은 조회 맥락의 행동이라 그대로 남는다(D5).
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderListBloc>()..add(LoadOrders()),
      child: const _OrderHistoryView(),
    );
  }
}

class _OrderHistoryView extends StatefulWidget {
  const _OrderHistoryView();

  @override
  State<_OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<_OrderHistoryView> {
  /// 진행 다이얼로그 중복 표시 방지. 동기화 중에는 상태가 채널마다 emit 되므로
  /// 리스너가 여러 번 불리는데, 다이얼로그는 실행당 1번만 띄운다.
  bool _syncDialogOpen = false;

  /// 백필 확인 다이얼로그 중복 표시 방지 (_syncDialogOpen 과 같은 패턴).
  bool _backfillDialogOpen = false;

  /// 검색어 입력 컨트롤러. ⚠️ [_LoadedBody] 안에서 만들면 rebuild 마다 커서가 튄다 —
  /// 여기(State)에서 만들어 주입한다.
  final TextEditingController _searchController = TextEditingController();

  /// 채널(계정) 필터. null = 전체. BLoC 이 아니라 화면 로컬 state 다(PLAN 2609_15 D3·D7).
  int? _selectedAccountId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '주문내역',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<OrderListBloc, OrderListState>(
        // 동기화 시작(다이얼로그) + 일시적 오류/다운로드 완료(SnackBar) 알림.
        listenWhen: (prev, curr) =>
            curr is OrderListLoaded &&
            (curr.isSyncing ||
                curr.actionError != null ||
                curr.backfillPrompt != null),
        listener: (context, state) {
          final s = state as OrderListLoaded;
          // 진행 다이얼로그 검사보다 먼저 — 백필은 여기서 시작된다.
          if (s.backfillPrompt != null && !_backfillDialogOpen) {
            _showBackfillDialog(context, s);
            return;
          }
          if (s.isSyncing) {
            _showSyncDialog(context);
            return;
          }
          final message = s.actionError;
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
          if (state is OrderListInitial || state is OrderListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderListError) {
            return _ErrorRetry(
              message: state.message,
              onRetry: () => context.read<OrderListBloc>().add(LoadOrders()),
            );
          }

          final loaded = state as OrderListLoaded;
          return _LoadedBody(
            state: loaded,
            searchController: _searchController,
            selectedAccountId: _selectedAccountId,
            onSelectAccount: (accountId) =>
                setState(() => _selectedAccountId = accountId),
          );
        },
      ),
    );
  }

  /// 빈 달 백필 확인 다이얼로그. 승낙하면 [BackfillPeriod] 로 그 기간을 불러온다(PLAN D2).
  void _showBackfillDialog(BuildContext context, OrderListLoaded s) {
    _backfillDialogOpen = true;
    // await 뒤 context 사용 금지 → BLoC 을 미리 캡처한다.
    final bloc = context.read<OrderListBloc>();
    // 🔴 목록이 담고 있는 기간이다(selectedPeriod 아님).
    final period = s.appliedPeriod;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${s.backfillPrompt} 주문 데이터가 없습니다'),
        content: const Text(
          '쿠팡에서 이 기간의 주문을 불러올까요?\n계정 수에 따라 수십 초가 걸릴 수 있습니다.\n\n'
          '· 이미 불러온 주문은 중복되지 않습니다.\n'
          '· 이 기간의 취소 내역은 일부 반영되지 않을 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('불러오기'),
          ),
        ],
      ),
    ).then((confirmed) {
      _backfillDialogOpen = false;
      if (bloc.isClosed) return;
      bloc.add(DismissBackfillPrompt()); // 어느 쪽이든 상태를 비운다
      if (confirmed == true) bloc.add(BackfillPeriod(period: period));
    });
  }

  /// 동기화 진행 다이얼로그. 끝나도 자동으로 닫지 않는다 — 리포트를 보고 사용자가 닫는다.
  void _showSyncDialog(BuildContext context) {
    if (_syncDialogOpen) return;
    _syncDialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        // 다이얼로그는 별도 route → BLoC 을 .value 로 넘겨야 한다.
        value: context.read<OrderListBloc>(),
        child: const SyncProgressDialog(),
      ),
    ).then((_) => _syncDialogOpen = false);
  }
}

class _LoadedBody extends StatelessWidget {
  final OrderListState state;
  final TextEditingController searchController;
  final int? selectedAccountId;
  final void Function(int? accountId) onSelectAccount;

  const _LoadedBody({
    required this.state,
    required this.searchController,
    required this.selectedAccountId,
    required this.onSelectAccount,
  });

  @override
  Widget build(BuildContext context) {
    final s = state as OrderListLoaded;
    final bloc = context.read<OrderListBloc>();
    final busy = s.isSearching || s.isSyncing;

    // 채널 옵션 = 동기화 대상 ∪ 조회된 목록의 marketplaceAccountId(PLAN 2609_15 D7-a).
    // 서버의 동기화 대상은 활성 계정만이라, 그것만으로 채우면 **비활성 채널의 과거 주문이
    // 필터에서 사라진다**. 목록에만 있는 계정은 이름을 모르므로 '채널 #{id}' 로 표시한다.
    final syncableIds = s.syncTargets.map((t) => t.accountId).toSet();
    final extraIds = s.orders
        .map((o) => o.marketplaceAccountId)
        .where((id) => !syncableIds.contains(id))
        .toSet()
        .toList()
      ..sort();
    final accountOptions = <int, String>{
      for (final target in s.syncTargets)
        target.accountId: target.accountAlias ?? '채널 #${target.accountId}',
      for (final id in extraIds) id: '채널 #$id',
    };
    // 고른 계정이 옵션에서 사라지면 드롭다운이 assert 로 죽는다 — 그때는 전체로 되돌린다.
    final accountValue =
        accountOptions.containsKey(selectedAccountId) ? selectedAccountId : null;
    // 비활성 계정은 조회만 되고 동기화는 불가하다(서버 대상 목록에 없다).
    final canSyncSelected =
        accountValue == null || syncableIds.contains(accountValue);

    // searchedOrders(검색까지 반영된 목록) 위에 채널만 얹고, 배지·목록·건수를 전부 여기서
    // 파생한다. s.filteredOrders·s.statusCounts 를 그대로 쓰면 목록만 줄고 배지·건수는 안 줄어
    // 화면이 어긋난다.
    final chScoped = accountValue == null
        ? s.searchedOrders
        : s.searchedOrders
            .where((o) => o.marketplaceAccountId == accountValue)
            .toList();
    final counts = <OrderStatus, int>{};
    for (final order in chScoped) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    final orders = s.selectedStatus == null
        ? chScoped
        : chScoped.where((o) => o.status == s.selectedStatus).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 판매자 필터 + 조회/동기화 컨트롤 (프론트 OrderSearchCard)
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
                        onPressed: busy ? null : () => bloc.add(SearchOrders()),
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 기간 드롭다운 — 고른 값은 [조회] 를 눌러야 목록에 반영된다(PLAN D8).
                  // ⚠️ items 는 State 밖에 캐시하지 말고 build 에서 만든다 —
                  // monthsWithData 가 늦게 도착했을 때 라벨이 갱신되지 않는다.
                  DropdownButtonFormField<String>(
                    value: s.selectedPeriod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '기간',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: buildPeriodOptions(monthsWithData: s.monthsWithData)
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
                  // 채널(계정) 필터 — 목록·배지·건수·동기화 범위를 함께 좁힌다
                  // (PLAN 2609_15 D7). 화면 로컬 state 라 BLoC 이벤트가 없다.
                  DropdownButtonFormField<int?>(
                    value: accountValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '채널',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('전체'),
                      ),
                      ...accountOptions.entries.map(
                        (entry) => DropdownMenuItem<int?>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) {
                            onSelectAccount(value);
                            // 비활성 채널은 조회만 된다 — 동기화 버튼이 왜 꺼지는지 알린다.
                            if (value == null || syncableIds.contains(value)) {
                              return;
                            }
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('동기화할 수 없는 채널입니다(비활성).'),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.only(
                                      left: 16, right: 16, bottom: 70),
                                ),
                              );
                          },
                  ),
                  const SizedBox(height: 8),
                  // 검색 — 클라이언트 필터라 서버를 부르지 않는다(PLAN D9).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('고객명'),
                          selected: s.searchField == OrderSearchField.customer,
                          onSelected: (_) => bloc.add(ChangeSearchField(
                              field: OrderSearchField.customer)),
                        ),
                        ChoiceChip(
                          label: const Text('주문번호'),
                          selected: s.searchField == OrderSearchField.orderNo,
                          onSelected: (_) => bloc.add(ChangeSearchField(
                              field: OrderSearchField.orderNo)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        bloc.add(ChangeSearchTerm(term: value)),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: s.searchField == OrderSearchField.orderNo
                          ? '주문번호 검색'
                          : '고객명 검색 (주문자·수취인)',
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          // 채널 미선택이면 전 채널, 선택돼 있으면 그 채널만(D7).
                          // 비활성 채널(대상 목록에 없음)은 동기화 자체가 불가하다.
                          onPressed: busy || !canSyncSelected
                              ? null
                              : () {
                                  if (accountValue == null) {
                                    bloc.add(SyncOrders());
                                    return;
                                  }
                                  bloc.add(SyncSelectedChannels(
                                    targets: s.syncTargets
                                        .where(
                                            (t) => t.accountId == accountValue)
                                        .toList(),
                                  ));
                                },
                          icon: s.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync, size: 18),
                          label: Text(s.isSyncing ? '동기화 중...' : '동기화'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 동기화 결과 배너 (프론트 syncResult 배너와 동일)
          if (s.syncResult != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '동기화 완료 — 신규 ${s.syncResult!.newOrders}건, '
                '수정 ${s.syncResult!.updatedOrders}건, '
                '취소 ${s.syncResult!.canceledUpdated}건',
                style: TextStyle(fontSize: 13, color: Colors.green[800]),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 채널 상태 배너 — 서버가 낙인한 마지막 동기화 상태(PARTIAL/FAILED)만 표시한다.
          // ⚠️ 사유 문구는 서버 lastSyncError 를 그대로 노출한다(가공 금지, PLAN D18).
          if (s.nonSuccessTargets.isNotEmpty) ...[
            _ChannelStatusBanner(
              targets: s.nonSuccessTargets,
              onRetry: busy
                  ? null
                  : () => bloc.add(
                      SyncSelectedChannels(targets: s.nonSuccessTargets)),
            ),
            const SizedBox(height: 8),
          ],

          // 과거 기간 안내 — **조회로 반영된** 기간(appliedPeriod)이 월일 때만 뜬다.
          // 고르기만 하고 [조회] 를 안 눌렀으면 목록이 아직 안 바뀌었으므로 뜨지 않는다(PLAN D8).
          if (isMonthPeriod(s.appliedPeriod)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '최근 2주 이전 주문은 배송 상태가 최신이 아닐 수 있습니다 (동기화해도 갱신되지 않습니다).',
                style: TextStyle(fontSize: 13, color: Colors.amber[900]),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 상태 필터 버튼 (프론트 OrderStatusFilter). 같은 버튼 재선택 시 전체 해제.
          OrderStatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: counts,
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${orders.length}건',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (s.lastSyncedAt != null)
                Text(
                  '마지막 동기화: ${formatOrderDateTime(s.lastSyncedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('조회 결과가 없습니다.'))
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight + 24,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        OrderCard(order: orders[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 마지막 동기화가 완료되지 않은 채널 배너 (PLAN D6·D14).
///
/// 소스는 서버 영속 상태(`syncTargets`)다 — 진행 리스트(`syncChannels`)로 그리면 PARTIAL 과
/// 서버 사유 문구가 사라진다. 사유는 `lastSyncError` 를 그대로 노출한다(앱에서 만들지 않음).
class _ChannelStatusBanner extends StatelessWidget {
  final List<SyncTarget> targets;
  final VoidCallback? onRetry;

  const _ChannelStatusBanner({required this.targets, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️ 마지막 동기화가 완료되지 않은 채널 ${targets.length}개',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.amber[900],
            ),
          ),
          const SizedBox(height: 6),
          ...targets.map(
            (target) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· ${target.sellerName}·${target.platform} — ${_reason(target)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.amber[900]),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('해당 채널만 다시 조회'),
            ),
          ),
        ],
      ),
    );
  }

  /// 서버가 확정한 사유. lastSyncError 가 없는 PARTIAL 만 '부분 성공' 으로 폴백한다.
  String _reason(SyncTarget target) {
    if (target.lastSyncStatus == 'FAILED') {
      return '(실패) ${target.lastSyncError ?? ''}'.trim();
    }
    return target.lastSyncError ?? '부분 성공';
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
          ElevatedButton(onPressed: onRetry, child: const Text('재시도')),
        ],
      ),
    );
  }
}
