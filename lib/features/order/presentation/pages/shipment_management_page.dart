import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/dialogs/shipment_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/sync_target.dart';
import '../bloc/order_acknowledge_bloc.dart';
import '../bloc/order_acknowledge_event.dart';
import '../bloc/order_acknowledge_state.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';
import '../bloc/order_refresh_bloc.dart';
import '../bloc/order_refresh_event.dart';
import '../bloc/order_refresh_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_search_bar.dart';
import '../widgets/order_status_filter_bar.dart';
import '../widgets/sync_progress_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// 주문관리 > 출고관리 페이지 (미발송 주문 작업대)
///
/// **용도**: 아직 내보내지 않은 주문(결제완료·상품준비중)만 모아, 송장 접수시트를 뽑고
/// 택배사 결과 파일로 발송처리하는 **작업 화면**. 지난 주문 조회는 주문내역이 담당한다
/// (PLAN 2609_15 D1·D4).
///
/// **필수 규칙**:
/// - 목록·배지는 [kShipmentStatuses] 로 좁히고 전량취소(서버가 내려주는 `cancelled`)는 제외한다.
///   화면에서 리터럴 상태 배열이나 자체 취소 판정을 만들지 말 것(PLAN 2609_26 D26).
/// - 동기화 오케스트레이션은 기존 [OrderListBloc] 이벤트를 그대로 쓴다(신규 이벤트 금지, D6).
/// - 목록 카드·상태 칩은 공유 위젯([OrderCard]·[OrderStatusFilterBar])을 쓴다.
///
/// - 판정은 두 개다(리터럴 조건 사본 금지) — 체크박스를 그릴지는 [_isSelectable](쿠팡이면
///   상태 무관), 실제로 발주처리할지는 [_isAcknowledgeTarget](결제완료만). 둘을 합치지 말 것:
///   합치면 고착된 상품준비중 주문을 선택할 수 없어 [주문 상태 갱신] 이 영구 비활성이 된다.
///
/// ⚠️ [OrderListBloc] 은 `registerFactory` 라 주문내역과 **인스턴스를 공유하지 않는다** —
/// 두 화면의 선택 상태가 이어질 거라 기대하지 말 것.
/// ⚠️ 기간 선택 UI 없음(D8) — 기본 창(14일)만 쓴다. `SelectPeriod` 를 호출하지 않는다.
/// - 검색은 주문내역과 **같은 규칙**을 쓴다(공용 [OrderSearchBar] + 기존 `ChangeSearchField`·
///   `ChangeSearchTerm` 이벤트, 신규 이벤트 금지). 서버 창은 14일 그대로이고 검색은 그 안에서만
///   걸리는 클라이언트 필터다.
/// ❌ 채널 필터를 BLoC 이벤트로 만들지 말 것 — 화면 로컬 state 다(D3).
class ShipmentManagementPage extends StatelessWidget {
  const ShipmentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderListBloc>(
          create: (_) => getIt<OrderListBloc>()..add(LoadOrders()),
        ),
        // 전송 전용 BLoC — 선택 상태는 화면 state 다(D3 과 같은 판단).
        BlocProvider<OrderAcknowledgeBloc>(
          create: (_) => getIt<OrderAcknowledgeBloc>(),
        ),
        // 상태 갱신도 전송 전용 BLoC 을 따로 둔다(2609_50 D20) — 발주처리와 한 BLoC 에 담으면
        // submitting 이 어느 쪽인지 화면이 구분하지 못한다.
        BlocProvider<OrderRefreshBloc>(
          create: (_) => getIt<OrderRefreshBloc>(),
        ),
      ],
      child: const _ShipmentManagementView(),
    );
  }
}

/// 발주처리 선택 가능 판정 (PLAN 2609_17 D2·D10).
///
/// 결제완료([OrderStatus.paid])·쿠팡·박스 ID 보유 셋을 모두 만족해야 한다. **화이트리스트**인 것이
/// 발송처리(2609_07 D1)의 블랙리스트와 반대 방향인 이유: 발주처리는 되돌릴 수 없어
/// "모르는 상태면 안 보낸다" 가 맞다(발송처리는 안 보내면 발송 누락이라 반대).
bool _isAcknowledgeTarget(OrderItem order) =>
    order.status == OrderStatus.paid &&
    order.platform == 'COUPANG' &&
    (order.externalBoxId?.isNotEmpty ?? false);

/// 체크박스를 그릴지 = **쿠팡 주문이면 상태 무관**.
///
/// 🔴 발주처리 화이트리스트([_isAcknowledgeTarget])를 체크박스 판정으로 쓰면 안 된다 — 그러면
/// 상품준비중으로 고착된 주문에 체크박스가 없어서 [주문 상태 갱신] 이 영구 비활성이 된다.
/// 고착 건을 푸는 것이 2609_50 의 존재 이유이므로 판정을 액션별로 나눈다.
///
/// 발주처리는 좁은 쪽이 맞다(되돌릴 수 없는 쓰기) — 넓어진 선택에서 발주처리 대상만 추려
/// 보내므로(`_LoadedBody` 의 `ackTargetIds`) 비대상이 요청에 섞이지 않는다.
bool _isSelectable(OrderItem order) => order.platform == 'COUPANG';

class _ShipmentManagementView extends StatefulWidget {
  const _ShipmentManagementView();

  @override
  State<_ShipmentManagementView> createState() =>
      _ShipmentManagementViewState();
}

class _ShipmentManagementViewState extends State<_ShipmentManagementView> {
  /// 진행 다이얼로그 중복 표시 방지 (주문내역과 같은 패턴 — 동기화 중 채널마다 emit 된다).
  bool _syncDialogOpen = false;

  /// 채널(계정) 필터. null = 전체. BLoC 이 아니라 화면 로컬 state 다(D3).
  int? _selectedAccountId;

  /// 발주처리로 선택한 order_item id. BLoC 이 아니라 화면 state 다(2609_15 D3 과 같은 판단).
  /// 목록이 바뀌면(필터·조회·동기화) 선택은 무효라 초기화한다.
  final Set<int> _selectedIds = {};

  /// 검색어 입력 컨트롤러. 값 자체는 BLoC(`searchTerm`)이 갖고, 이건 입력칸 표시·[X] 지우기용이다.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelect(int id) => setState(() => _selectedIds.contains(id)
      ? _selectedIds.remove(id)
      : _selectedIds.add(id));

  void _clearSelection() {
    if (_selectedIds.isNotEmpty) setState(_selectedIds.clear);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '출고관리',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      // 두 BLoC 을 한 Consumer 에 섞지 않는다 — 발주처리 결과는 별도 리스너가 듣는다.
      body: BlocListener<OrderAcknowledgeBloc, OrderAcknowledgeState>(
        // 같은 값이 다시 emit 될 때(권한 없음 재노출 등) SnackBar 가 겹치지 않도록 전이만 듣는다.
        listenWhen: (prev, curr) =>
            (curr.forbidden && !prev.forbidden) ||
            (curr.result != null && curr.result != prev.result) ||
            (curr.errorMessage != null &&
                curr.errorMessage != prev.errorMessage),
        listener: _onAcknowledgeState,
        child: BlocListener<OrderRefreshBloc, OrderRefreshState>(
          // 발주처리와 같은 규칙 — 전이만 듣는다(SnackBar 중복 방지).
          listenWhen: (prev, curr) =>
              (curr.result != null && curr.result != prev.result) ||
              (curr.errorMessage != null &&
                  curr.errorMessage != prev.errorMessage),
          listener: _onRefreshState,
          child: BlocConsumer<OrderListBloc, OrderListState>(
            // 기간 UI 가 없어 backfillPrompt 는 채워지지 않는다 — 두 분기만 듣는다.
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
                    margin:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 70),
                  ),
                );
            },
            builder: (context, state) {
              if (state is OrderListInitial || state is OrderListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is OrderListError) {
                return _ErrorRetry(
                  message: '출고 대상 조회에 실패했습니다.',
                  onRetry: () => context.read<OrderListBloc>().add(LoadOrders()),
                );
              }

              return _LoadedBody(
                state: state as OrderListLoaded,
                searchController: _searchController,
                selectedAccountId: _selectedAccountId,
                onSelectAccount: (accountId) => setState(() {
                  _selectedAccountId = accountId;
                  // 채널이 바뀌면 목록이 바뀐다 — 화면 밖 건이 전송되지 않게 선택을 버린다.
                  _selectedIds.clear();
                }),
                selectedIds: _selectedIds,
                onToggleSelect: _toggleSelect,
                onClearSelection: _clearSelection,
                onAcknowledge: _onAcknowledgePressed,
                onRefresh: _onRefreshPressed,
              );
            },
          ),
        ),
      ),
    );
  }

  /// 주문 상태 갱신 버튼 — 🔴 **확인 다이얼로그가 없다**(2609_50 D15 와 같은 판단).
  /// 마켓에 쓰지 않는 읽기라 되돌릴 것이 없다.
  ///
  /// 🔴 50건 상한은 서버가 판정한다(D3) — 앱에서 미리 막지 않고 400 의 서버 메시지를
  /// 그대로 보여준다.
  void _onRefreshPressed() {
    if (_selectedIds.isEmpty) return;
    context
        .read<OrderRefreshBloc>()
        .add(RefreshRequested(_selectedIds.toList()));
  }

  /// 주문 상태 갱신 결과 처리. `empty`(쿠팡 0박스 = 전량취소 추정)·`unsupported`(비-쿠팡)는 실패가
  /// 아니라 따로 세지 않는다 — 사용자가 조치할 것이 없다.
  ///
  /// ⚠️ 건수는 모두 **주문번호 단위**다(D1) — 같은 주문의 옵션 3줄을 체크해도 1건이다.
  void _onRefreshState(BuildContext context, OrderRefreshState state) {
    final result = state.result;
    if (result != null) {
      final failedCount = result.failed.length;
      final cancelledCount = result.cancelled.length;
      var summary = failedCount == 0
          ? '주문 상태 갱신 완료 — 갱신 ${result.refreshed}건 / 조회 ${result.requestedOrders}건'
          : '주문 상태 갱신 완료 — 갱신 ${result.refreshed}건 / 실패 $failedCount건';
      if (cancelledCount > 0) {
        summary += ' / 마켓에서 취소·반품됨 $cancelledCount건';
      }
      // 실패 사유는 서버 원문 그대로, 중복 제거 최대 3종(발주처리와 같은 형태).
      final details = result.failed
          .map((f) => '${f.externalOrderId}: ${f.reason}')
          .toSet()
          .take(3)
          .toList();
      _showAckSnackBar(context, summary, details);
      _clearSelection();
      // 판매자 필터를 유지하는 SearchOrders 를 쓴다(발주처리 성공 후 처리와 같은 이벤트).
      context.read<OrderListBloc>().add(SearchOrders());
      context.read<OrderRefreshBloc>().add(const RefreshResultCleared());
      return;
    }

    final message = state.errorMessage;
    if (message == null) return;
    // 요청 자체가 실패 — 선택은 유지한다(재시도가 정답).
    _showAckSnackBar(context, message, const []);
    context.read<OrderRefreshBloc>().add(const RefreshResultCleared());
  }

  /// 발주처리 버튼 — **되돌릴 수 없으므로 확인 다이얼로그를 반드시 거친다**
  /// (PLAN 2609_17 "남는 위험").
  /// [ids] = 선택 중 **발주처리 대상만** 추린 것(`_LoadedBody` 가 추려 넘긴다). 체크박스가
  /// 상태 무관으로 넓어졌으므로 `_selectedIds` 를 그대로 보내면 비대상이 섞인다.
  Future<void> _onAcknowledgePressed(List<int> ids) async {
    final count = ids.length;
    if (count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('발주처리'),
        content: Text('$count건을 발주처리합니다. 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('발주처리'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<OrderAcknowledgeBloc>().add(AcknowledgeRequested(ids));
  }

  /// 전송 결과 처리 (D8·D9). `skipped`·`unsupported` 는 표시하지 않는다 —
  /// 발주처리 대상만 추려 보내므로(`ackTargetIds`) 애초에 그 분류로 돌아올 것이 없다.
  void _onAcknowledgeState(BuildContext context, OrderAcknowledgeState state) {
    if (state.forbidden) {
      _showAckSnackBar(context, '발주처리 권한이 없습니다.', const []);
      return;
    }

    final result = state.result;
    if (result != null) {
      final failedCount = result.failed.length;
      final summary = failedCount == 0
          ? '발주처리 완료 — 성공 ${result.succeeded}건'
          : '발주처리 완료 — 성공 ${result.succeeded}건 / 실패 $failedCount건';
      // 실패 사유는 쿠팡 원문 그대로, 중복 제거 최대 3종(D8).
      final details = result.failed
          .map((f) => '${f.resultCode}: ${f.message}')
          .toSet()
          .take(3)
          .toList();
      _showAckSnackBar(context, summary, details);
      _clearSelection();
      // 판매자 필터를 유지하는 SearchOrders 를 쓴다(발송처리 성공 후 처리와 같은 이벤트).
      context.read<OrderListBloc>().add(SearchOrders());
      context
          .read<OrderAcknowledgeBloc>()
          .add(const AcknowledgeResultCleared());
      return;
    }

    final message = state.errorMessage;
    if (message == null) return;
    // 요청 자체가 실패 — 선택은 유지한다(재시도가 정답).
    _showAckSnackBar(context, message, const []);
    context.read<OrderAcknowledgeBloc>().add(const AcknowledgeResultCleared());
  }

  /// 하단 내비를 오버레이하는 [ScaffoldWithNavBar] 를 피해 floating + bottom 70 으로 띄운다.
  void _showAckSnackBar(
    BuildContext context,
    String summary,
    List<String> details,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary),
              ...details.map(
                (d) => Text(d, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
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
  final OrderListLoaded state;

  /// 화면(State)이 소유·dispose 하는 검색 입력 컨트롤러.
  final TextEditingController searchController;

  final int? selectedAccountId;
  final void Function(int? accountId) onSelectAccount;

  /// 발주처리 선택 — 값·콜백 모두 부모 state 다(`_LoadedBody` 를 Stateful 로 승격하지 말 것:
  /// 선택을 초기화해야 하는 채널 필터 콜백이 부모에 있다).
  final Set<int> selectedIds;
  final void Function(int orderItemId) onToggleSelect;

  /// 목록이 바뀌는 이벤트(`bloc.add`) **직전**에 함께 부른다 — 선택이 무효가 된다.
  final VoidCallback onClearSelection;

  /// 확인 다이얼로그와 `AcknowledgeRequested` 발행은 부모가 한다.
  /// 🔴 발주처리 대상만 추려서 넘긴다 — 체크박스는 상태 무관이라 선택 전체와 다르다.
  final void Function(List<int> ids) onAcknowledge;

  /// `RefreshRequested` 발행은 부모가 한다(확인 다이얼로그 없음 — 읽기다).
  final VoidCallback onRefresh;

  const _LoadedBody({
    required this.state,
    required this.searchController,
    required this.selectedAccountId,
    required this.onSelectAccount,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onClearSelection,
    required this.onAcknowledge,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    final bloc = context.read<OrderListBloc>();
    final busy = s.isSearching || s.isSyncing;

    // 출고관리는 미발송 주문만 다루므로 채널 옵션 = 동기화 대상 그대로다(주문내역과 다름, D7-a).
    final targets = s.syncTargets;
    // 대상 목록이 늦게 오거나 바뀌면 고른 값이 items 에서 사라져 드롭다운이 assert 로 죽는다.
    final accountValue = targets.any((t) => t.accountId == selectedAccountId)
        ? selectedAccountId
        : null;

    // s.filteredOrders 는 전 상태 기준이다. 출고관리 범위를 먼저 좁히고, 배지도 이 목록으로 센다
    // — s.statusCounts 를 쓰면 취소·배송 건까지 세어 목록과 배지가 어긋난다.
    // 순서는 주문내역과 같다: 채널 → 검색 → 상태. 배지 건수도 검색 결과를 센다.
    final scoped = s.orders
        .where((o) => kShipmentStatuses.contains(o.status))
        .where((o) => !o.cancelled) // 전량취소는 발송 대상 아님 (서버 판정, D26)
        .where((o) =>
            accountValue == null || o.marketplaceAccountId == accountValue)
        .where((o) => matchesOrderSearch(o, s.searchField, s.searchTerm))
        .toList();
    final counts = <OrderStatus, int>{
      for (final status in kShipmentStatuses)
        status: scoped.where((o) => o.status == status).length,
    };
    final visible = s.selectedStatus == null
        ? scoped
        : scoped.where((o) => o.status == s.selectedStatus).toList();
    // 선택 중 실제로 발주처리되는 라인 id. 상태 탭은 선택을 비우지 않으므로 `visible` 이 아니라
    // 채널 필터까지만 적용한 `scoped` 에서 찾는다 — 탭에 가려진 선택도 세어야 한다.
    final ackTargetIds = scoped
        .where((o) => selectedIds.contains(o.id) && _isAcknowledgeTarget(o))
        .map((o) => o.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목록(클라이언트 필터)과 접수시트(서버 30일 창)의 범위가 다르다는 고지.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              border: Border.all(color: AppColors.infoSurface),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '목록은 최근 14일 기준입니다. 접수시트는 30일까지 포함합니다.',
              style: TextStyle(fontSize: 13, color: AppColors.infoForeground),
            ),
          ),
          const SizedBox(height: 8),

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
                              : (value) {
                                  onClearSelection();
                                  bloc.add(SelectSeller(sellerId: value));
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: busy
                            ? null
                            : () {
                                onClearSelection();
                                bloc.add(SearchOrders());
                              },
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 채널(계정) 필터 — 목록과 동기화 범위를 함께 좁힌다(D7).
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
                      ...targets.map(
                        (SyncTarget target) => DropdownMenuItem<int?>(
                          value: target.accountId,
                          child: Text(
                            target.accountAlias ?? '채널 #${target.accountId}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: busy ? null : onSelectAccount,
                  ),
                  const SizedBox(height: 8),
                  // 검색 — 클라이언트 필터라 서버를 부르지 않는다(주문내역과 같은 규칙).
                  // 목록이 줄어들면 화면 밖 건이 전송되지 않게 선택을 버린다.
                  OrderSearchBar(
                    controller: searchController,
                    field: s.searchField,
                    term: s.searchTerm,
                    onFieldChanged: (f) {
                      onClearSelection();
                      bloc.add(ChangeSearchField(field: f));
                    },
                    onTermChanged: (t) {
                      onClearSelection();
                      bloc.add(ChangeSearchTerm(term: t));
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          // 채널 미선택이면 전 채널, 선택돼 있으면 그 채널만(D7).
                          onPressed: busy
                              ? null
                              : () {
                                  // 조회 범위는 서버가 정한다(기본 preset = QUICK) — 화면이
                                  // 범위를 선언하지 않는다(FEATURE_2609_49).
                                  onClearSelection();
                                  if (accountValue == null) {
                                    bloc.add(SyncOrders());
                                    return;
                                  }
                                  bloc.add(SyncSelectedChannels(
                                    targets: targets
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
                              onClearSelection();
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

          OrderStatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: counts,
            onSelect: (status) {
              onClearSelection();
              bloc.add(SelectStatus(status: status));
            },
            statuses: kShipmentStatuses,
          ),
          const SizedBox(height: 8),

          // ⚠️ BlocBuilder 는 이 한 줄만 감싼다 — Column 이나 ListView 를 감싸면 전송할 때마다
          // 목록 전체가 리빌드된다(주문 상세의 같은 주의와 동일).
          BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
            builder: (context, ackState) => Row(
              children: [
                Text(
                  '총 ${visible.length}건',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // 선택 건수를 말하는 자리는 여기 한 곳뿐이다 — 버튼 글자에 건수를 넣지 않는다.
                // 발주처리 블록 안에 두면 비-ADMIN 에게는 건수가 아예 안 보인다(이전 동작).
                if (selectedIds.isNotEmpty) ...[
                  Text(
                    '선택 ${selectedIds.length}건',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // 주문 상태 갱신 — 발주처리와 달리 권한 게이트가 없고(2609_50 D18),
                // 선택이 없어도 버튼은 보이되 비활성이다.
                BlocBuilder<OrderRefreshBloc, OrderRefreshState>(
                  builder: (context, refreshState) => OutlinedButton(
                    onPressed: selectedIds.isEmpty || refreshState.submitting
                        ? null
                        : onRefresh,
                    child: refreshState.submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('주문 상태 갱신'),
                  ),
                ),
                // 전체선택은 두지 않는다(D17) — 화면 밖 일괄 선택이 되어 D7 과 어긋난다.
                if (ackTargetIds.isNotEmpty && !ackState.forbidden) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: ackState.submitting
                        ? null
                        : () => onAcknowledge(ackTargetIds),
                    child: ackState.submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('발주처리'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('발송할 주문이 없습니다.'))
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight + 24,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final o = visible[index];
                      return OrderCard(
                        order: o,
                        selected: selectedIds.contains(o.id),
                        selectable: _isSelectable(o),
                        onToggleSelect: onToggleSelect,
                      );
                    },
                  ),
          ),
        ],
      ),
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
          ElevatedButton(onPressed: onRetry, child: const Text('재시도')),
        ],
      ),
    );
  }
}
