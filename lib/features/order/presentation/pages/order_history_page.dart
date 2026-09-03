import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/dialogs/shipment_confirm_dialog.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_period.dart';
import '../../domain/entities/sync_target.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';
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
/// - 카드 항목(프론트 OrderTable과 동일): 주문번호 / 상품명 / 주문수량 / 취소 / 결제일
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
    return ScaffoldWithNavBar(
      title: '주문내역',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<OrderListBloc, OrderListState>(
        // 동기화 시작(다이얼로그) + 일시적 오류/다운로드 완료(SnackBar) 알림.
        listenWhen: (prev, curr) =>
            curr is OrderListLoaded &&
            (curr.isSyncing || curr.actionError != null),
        listener: (context, state) {
          final s = state as OrderListLoaded;
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
          );
        },
      ),
    );
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

  const _LoadedBody({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final s = state as OrderListLoaded;
    final bloc = context.read<OrderListBloc>();
    final busy = s.isSearching || s.isSyncing;
    // getter 는 호출마다 리스트를 새로 만들고 그때마다 searchedOrders 까지 다시 돈다 —
    // 아래 네 곳(총 N건 · isEmpty · itemCount · itemBuilder)이 쓰도록 한 번만 받는다.
    final orders = s.filteredOrders;

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
                          onPressed: busy ? null : () => bloc.add(SyncOrders()),
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
                  const SizedBox(height: 8),
                  // 주문목록 다운로드: preview 페이지에서 택배수량 편집 후 다운로드.
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push(Routes.shippingLabelPreviewPath),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('주문목록 다운로드'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 발송처리 (Shipping Label 업로드): 택배사 결과 xlsx → 쿠팡 송장업로드 배치.
                  // OrderListBloc.busy 와 무관 — 별도 BLoC·다이얼로그.
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uploaded =
                                await showShipmentConfirmDialog(context);
                            // Guard isClosed: the page can be popped while the
                            // dialog is open.
                            if (uploaded == true && !bloc.isClosed) {
                              // 백엔드가 배송지시로 바꾼 상태를 즉시 반영 —
                              // 판매자 필터를 유지하는 SearchOrders 를 쓴다.
                              bloc.add(SearchOrders());
                            }
                          },
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('발송처리'),
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
          _StatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: s.statusCounts,
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
          ),
          // 칩 라벨을 '추적불가' 로 줄인 대신, 그 상태를 고른 동안만 설명을 편다.
          if (s.selectedStatus == 'NONE_TRACKING') ...[
            const SizedBox(height: 8),
            const Text(
              '업체가 직접 배송해 배송 연동이 적용되지 않는 주문입니다 — 송장 추적이 불가합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
                  '마지막 동기화: ${_formatDate(s.lastSyncedAt)}',
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
                        _OrderCard(order: orders[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 항목 탭 → 주문 상세 페이지로 이동 (선택한 OrderItem 을 extra 로 전달).
        onTap: () => context.push(Routes.orderHistoryDetailPath, extra: order),
        child: Padding(
          padding: const EdgeInsets.all(12),
          // 카드 항목은 프론트 OrderTable 컬럼과 동일:
          // 주문번호 / 고객명 / 상품명 / 주문수량 / 취소 / 결제일.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.externalOrderId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '고객 ${getCustomerName(order)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
              const SizedBox(height: 6),
              Text(order.itemName ?? '-', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _metric('주문수량', order.orderCount),
                  _metric('취소', order.cancelCount),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '결제일 ${_formatDate(order.paidAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, int value) => Text(
        '$label $value',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      );
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

/// 상태 필터 버튼 바 (프론트 OrderStatusFilter와 동일).
///
/// 6개 상태 버튼을 가로 스크롤로 배치하고, 각 버튼에 해당 상태의 건수 배지를
/// 표시한다. 활성 버튼을 다시 누르면 [onSelect]에 null을 전달해 필터를
/// 해제(전체)한다.
class _StatusFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final Map<String, int> counts;
  final void Function(String? status) onSelect;

  const _StatusFilterBar({
    required this.selectedStatus,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kOrderStatuses.map((status) {
          final isActive = selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StatusChip(
              label: getOrderStatusLabel(status),
              count: counts[status] ?? 0,
              isActive: isActive,
              onTap: () => onSelect(isActive ? null : status),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isActive ? Colors.white : Colors.grey[800];
    return Material(
      color: isActive ? Colors.blue[600] : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ISO LocalDateTime → 'yyyy-MM-dd HH:mm'. null/파싱 실패 시 '-' 또는 원본 반환.
String _formatDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}
