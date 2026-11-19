import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/dialogs/shipment_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/widgets/stored_invoice_section.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/order_acknowledge_bloc.dart';
import '../bloc/order_acknowledge_event.dart';
import '../bloc/order_acknowledge_state.dart';
import '../bloc/order_internal_stage_bloc.dart';
import '../bloc/order_internal_stage_event.dart';
import '../bloc/order_internal_stage_state.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';
import '../bloc/order_refresh_bloc.dart';
import '../bloc/order_refresh_event.dart';
import '../bloc/order_refresh_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_search_bar.dart';
import '../widgets/order_status_filter_bar.dart';
import '../widgets/order_sync_button.dart';
import '../widgets/order_select_box.dart';
import '../widgets/paid_stage_filter_bar.dart';
import '../widgets/sync_progress_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';

/// Order management > shipment page (the workbench of unshipped orders)
///
/// **Purpose**: gathers only the orders not sent out yet (paid · preparing) to
/// pull the label sheet and ship from the carrier's result file — a **work
/// screen**. Past orders are the order history's job (PLAN 2609_15 D1·D4).
///
/// **Required rules**:
/// - The list and badges narrow with [kShipmentStatuses] and drop fully
///   cancelled orders (the server's `cancelled`). Do not build a literal status
///   array or an own cancel decision on screen (PLAN 2609_26 D26).
/// - Sync orchestration uses the existing [OrderListBloc] events as is (no new
///   event, D6).
/// - List cards and status chips use the shared widgets ([OrderCard] ·
///   [OrderStatusFilterBar]).
/// - The sync pill ([OrderSyncButton]) sits in the title bar; selection actions
///   sit in a bar pinned above the nav bar (FEATURE_2611_32 / D6 · D12);
///   「전체 선택」 picks the visible orders (D13; 🔁 PLAN 2609_17 D17).
///
/// - There are two decisions (no copied literal conditions) — whether to draw
///   the checkbox is [_isSelectable] (a Coupang, 11st or LotteON order,
///   whatever its status — FEATURE_2610_17 / D28 · FEATURE_2611_23 / D17),
///   and whether to confirm is
///   [_isAcknowledgeTarget] (paid only). Do not merge them: merged, a stuck
///   preparing order cannot be selected and [주문 상태 갱신] stays disabled
///   forever.
///
/// ⚠️ [OrderListBloc] is `registerFactory`, so it **does not share the
/// instance** with the order history — do not expect the selection to carry
/// over between the two screens.
/// ⚠️ No period picker (D8) — only the default window (14 days). `SelectPeriod`
/// is not called.
/// - Search follows **the same rules** as the order history (shared
///   [OrderSearchBar] + the existing `ChangeSearchField` · `ChangeSearchTerm`
///   events, no new event). The server window stays 14 days, and search is a
///   client filter inside it.
/// ❌ Do not make the channel filter a BLoC event — it is screen-local state
/// (D3).
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
        // 내부 발주·해제 전송 전용 BLoC(FEATURE_2609_75) — 발주처리 BLoC 과 섞지 않는다.
        BlocProvider<OrderInternalStageBloc>(
          create: (_) => getIt<OrderInternalStageBloc>(),
        ),
      ],
      child: const _ShipmentManagementView(),
    );
  }
}

/// Order-confirmation target (PLAN 2609_17 D2·D10 · FEATURE_2610_17 / D20).
///
/// Paid ([OrderStatus.paid]) · Coupang, 11st or LotteON (FEATURE_2611_23 /
/// D17) · has a box id (11st: the delivery number) · not an 11st reserved
/// sale still waiting for
/// [입고완료 처리] (FEATURE_2610_17 / D67) — all four. It is a **whitelist**,
/// the opposite of the shipment blacklist (2609_07 D1), because confirmation
/// cannot be undone: "unknown status → do not send" is right (for shipment,
/// not sending means a missed shipment, hence the opposite).
bool _isAcknowledgeTarget(OrderItem order) =>
    order.status == OrderStatus.paid &&
    (order.platform == 'COUPANG' ||
        order.platform == 'ELEVENST' ||
        order.platform == 'LOTTEON') &&
    (order.externalBoxId?.isNotEmpty ?? false) &&
    !order.reservedSale;

/// Whether to draw the checkbox = **a Coupang, 11st or LotteON order,
/// whatever its status** (FEATURE_2610_17 / D28 · FEATURE_2611_23 / D17 —
/// same rule as web `ShipmentContainer`).
///
/// 🔴 Do not use the confirmation whitelist ([_isAcknowledgeTarget]) for the
/// checkbox — then an order stuck in preparing has no checkbox and
/// [주문 상태 갱신] stays disabled forever. Unsticking those is why 2609_50
/// exists, so the decision is split per action. [주문 상태 갱신] stays
/// Coupang only (D12) and the internal stage covers Coupang · 11st · LotteON
/// (FEATURE_2611_23 / D51 · R50) — their id lists narrow the selection again in
/// `_LoadedBody`.
///
/// Confirmation is the narrow one (an irreversible write) — only the targets
/// are picked out of the wider selection (`_LoadedBody`'s `ackTargetIds`), so
/// no non-target gets into the request.
bool _isSelectable(OrderItem order) =>
    order.platform == 'COUPANG' ||
        order.platform == 'ELEVENST' ||
        order.platform == 'LOTTEON';

/// Internal-acknowledge target = a Coupang, LotteON or 11st (not visit
/// pickup, FEATURE_2611_23 / D53 · R50) confirmation target without an
/// internal stage yet
/// (FEATURE_2609_75 / D1 · FEATURE_2610_17 / D12). The server judges again.
bool _isInternalTarget(OrderItem order) =>
    _isAcknowledgeTarget(order) &&
    (order.platform == 'COUPANG' ||
        order.platform == 'LOTTEON' ||
        (order.platform == 'ELEVENST' && !order.visitPickup)) &&
    order.internalStage == null;

/// [주문 상태 갱신] target = a Coupang order (FEATURE_2610_17 / D12).
bool _isRefreshTarget(OrderItem order) => order.platform == 'COUPANG';

/// 내부 발주 해제 대상 = 「내부 상품준비중」만(D18 행1). 발송대기중은 먼저 [예약 취소] 한다.
bool _isReleaseTarget(OrderItem order) =>
    order.internalStage == InternalStage.internalPreparing;

/// 예약 취소 대상 = 「발송대기중」만(FEATURE_2609_75 / D18 행2). 서버가 다시 판정한다.
bool _isCancelReservationTarget(OrderItem order) =>
    order.internalStage == InternalStage.awaitingShipment;

/// 저장된 송장으로 발송 대상 = 내부 단계 주문(D18 🔁). 송장 유무·단계는 서버가 다시 판정한다.
bool _isStoredShipTarget(OrderItem order) => order.internalStage != null;

/// 한 번에 발주처리할 수 있는 최대 건수 — 서버 `@Size(max=500)` 과 같은 값(웹 `AcknowledgeBar` 와 동일).
/// 넘겨 보내면 400 이라 버튼에서 먼저 막는다(PLAN 2609_17 D12).
const int _kMaxAcknowledgeSelection = 500;

/// The picked channel when it is still a sync target, else null (= all
/// channels) — the targets can arrive after the pick or change.
int? _shipmentAccountValue(OrderListLoaded s, int? selectedAccountId) =>
    s.syncTargets.any((t) => t.accountId == selectedAccountId)
        ? selectedAccountId
        : null;

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

  /// 2nd-row chip under PAID (FEATURE_2610_07 / D10·D18). Page state, not
  /// [OrderListBloc] — the order history page uses the same bloc class.
  PaidStage _paidStage = PaidStage.all;

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
      appBarActions: [
        BlocBuilder<OrderListBloc, OrderListState>(
          builder: (context, state) => state is OrderListLoaded
              ? OrderSyncButton(
                  lastSyncedAt: state.lastSyncedFromServer,
                  hasIncompleteChannel: state.nonSuccessTargets.isNotEmpty,
                  syncing: state.isSyncing,
                  onPressed: _syncAction(state),
                )
              : const SizedBox.shrink(),
        ),
      ],
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
          child: BlocListener<OrderInternalStageBloc, OrderInternalStageState>(
            // 내부 발주·해제 결과(FEATURE_2609_75) — 발주처리와 같은 규칙(전이만 듣는다).
            listenWhen: (prev, curr) =>
                (curr.forbidden && !prev.forbidden) ||
                (curr.result != null && curr.result != prev.result) ||
                (curr.errorMessage != null &&
                    curr.errorMessage != prev.errorMessage),
            listener: _onInternalState,
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
                showErrorToast(context, message);
              },
              builder: (context, state) {
                if (state is OrderListInitial || state is OrderListLoading) {
                  return const AppPageBody(children: [AppLoading()]);
                }

                if (state is OrderListError) {
                  return AppPageBody(
                    children: [
                      AppErrorBox(
                        message: '출고 대상 조회에 실패했습니다.',
                        action: FilledButton(
                          onPressed: () => context.read<OrderListBloc>().add(LoadOrders()),
                          child: const Text('다시 시도'),
                        ),
                      ),
                    ],
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
                  paidStage: _paidStage,
                  onSelectPaidStage: (stage) => setState(() {
                    _paidStage = stage;
                    // The list changes — drop the selection so off-screen
                    // orders are not sent (FEATURE_2610_07 / D15).
                    _selectedIds.clear();
                  }),
                  selectedIds: _selectedIds,
                  onToggleSelect: _toggleSelect,
                  onClearSelection: _clearSelection,
                  onAcknowledge: _onAcknowledgePressed,
                  onInternal: _onInternalPressed,
                  onRelease: _onReleasePressed,
                  onCancelReservation: _onCancelReservationPressed,
                  onShipStored: _onShipStoredPressed,
                  onRefresh: _onRefreshPressed,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Sync action of the title-bar pill — the same job as the old [동기화]:
  /// no channel picked = every channel, a picked channel = that channel only;
  /// the selection is cleared first. The server decides the fetch range
  /// (FEATURE_2609_49).
  VoidCallback? _syncAction(OrderListLoaded s) {
    if (s.isSearching || s.isSyncing) {
      return null;
    }
    final accountValue = _shipmentAccountValue(s, _selectedAccountId);
    final bloc = context.read<OrderListBloc>();
    return () {
      _clearSelection();
      accountValue == null
          ? bloc.add(SyncOrders())
          : bloc.add(SyncSelectedChannels(
              targets: s.syncTargets
                  .where((t) => t.accountId == accountValue)
                  .toList(),
            ));
    };
  }

  /// 주문 상태 갱신 버튼 — 🔴 **확인 다이얼로그가 없다**(2609_50 D15 와 같은 판단).
  /// 마켓에 쓰지 않는 읽기라 되돌릴 것이 없다.
  ///
  /// 🔴 50건 상한은 서버가 판정한다(D3) — 앱에서 미리 막지 않고 400 의 서버 메시지를
  /// 그대로 보여준다.
  void _onRefreshPressed(List<int> ids) {
    if (ids.isEmpty) return;
    context.read<OrderRefreshBloc>().add(RefreshRequested(ids));
  }

  /// 주문 상태 갱신 결과 처리. 문구는 웹 `buildRefreshMessage` 와 같다 — `empty`(쿠팡 0박스 =
  /// 전량취소 추정)·`unsupported`(비-쿠팡)는 실패가 아니라 별도 건수로 적는다.
  ///
  /// ⚠️ 건수는 모두 **주문번호 단위**다(D1) — 같은 주문의 옵션 3줄을 체크해도 1건이다.
  void _onRefreshState(BuildContext context, OrderRefreshState state) {
    final result = state.result;
    if (result != null) {
      // Same wording as web `buildRefreshMessage` — "갱신", not "성공"
      // (0 refreshed is normal when the order is already current).
      var summary = '주문 상태 갱신 완료 — ${result.refreshed}건 갱신';
      if (result.empty.isNotEmpty) {
        summary += ' / 주문 없음 ${result.empty.length}건';
      }
      if (result.cancelled.isNotEmpty) {
        summary += ' / 마켓에서 취소·반품됨 ${result.cancelled.length}건';
      }
      if (result.failed.isNotEmpty) {
        summary += ' / 실패 ${result.failed.length}건';
      }
      if (result.unsupported.isNotEmpty) {
        summary += ' / 처리불가 ${result.unsupported.length}건';
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
    showErrorToast(context, message);
    context.read<OrderRefreshBloc>().add(const RefreshResultCleared());
  }

  /// The acknowledge button — **it cannot be undone, so it always goes
  /// through the confirm dialog** (PLAN 2609_17 remaining risk).
  /// [ids] = only the acknowledge targets among the selection (`_LoadedBody`
  /// narrows them). The checkbox ignores the status, so sending `_selectedIds`
  /// as is would mix in non-targets.
  /// [orderCount] = the order count written in the confirm text
  /// (FEATURE_2611_30 / D16 · R3).
  /// [includesInternal] = some of them are at an internal stage → ask once
  /// with the D14 notice (FEATURE_2609_75).
  Future<void> _onAcknowledgePressed(
      List<int> ids, int orderCount, bool includesInternal) async {
    if (ids.isEmpty) return;
    final ok = await showAppConfirmDialog(
      context,
      title: includesInternal ? '예약된 주문 포함' : '발주처리',
      message: includesInternal
          ? '예약된 주문입니다. 마켓에 지금 발주처리하면 해당 주문의 내부 발주·예약 발송이 해제됩니다. 계속할까요?'
          : '$orderCount건을 발주처리합니다. 되돌릴 수 없습니다.',
      confirmText: '발주처리',
    );
    if (!ok || !mounted) return;
    context.read<OrderAcknowledgeBloc>().add(AcknowledgeRequested(ids));
  }

  /// [내부 발주처리] — Sends nothing to the marketplace (FEATURE_2609_75 / D1). Undo is [내부 발주 해제], so it is sent without confirmation.
  void _onInternalPressed(List<int> ids) {
    if (ids.isEmpty) return;
    context
        .read<OrderInternalStageBloc>()
        .add(InternalStageRequested(InternalStageAction.mark, ids));
  }

  /// [내부 발주 해제] — D18 행1 경고를 거친다. 접수시트를 받았는지는 저장하지 않으므로(PLAN §7) 조건 문구를 항상 보인다.
  Future<void> _onReleasePressed(List<int> ids) async {
    if (ids.isEmpty) return;
    final ok = await showAppConfirmDialog(
      context,
      title: '내부 발주 해제',
      message: '내부 발주를 해제하고 결제완료로 되돌립니다. 이미 접수시트를 받은 주문이면 택배사에 택배 접수 취소가 필요합니다.',
      confirmText: '해제',
    );
    if (!ok || !mounted) return;
    context
        .read<OrderInternalStageBloc>()
        .add(InternalStageRequested(InternalStageAction.release, ids));
  }

  /// [예약 취소] — 발송대기중 → 「내부 상품준비중」, 송장은 주문에 남는다(D18 행2 · D18 🔁).
  /// 쿠팡 호출이 없고 다시 [예약 발송]으로 되돌릴 수 있어 확인 없이 보낸다(웹과 같다).
  void _onCancelReservationPressed(List<int> ids) {
    if (ids.isEmpty) return;
    context
        .read<OrderInternalStageBloc>()
        .add(InternalStageRequested(InternalStageAction.cancel, ids));
  }

  /// [저장된 송장으로 발송](D18 🔁) — 발송처리 다이얼로그를 저장된 송장 모드로 연다. 요청·결과는 다이얼로그가 한다.
  /// 보냈으면 선택을 비우고 판매자 필터를 유지한 채 다시 조회한다(발송처리 버튼과 같은 이벤트).
  Future<void> _onShipStoredPressed(List<int> ids) async {
    if (ids.isEmpty) return;
    final bloc = context.read<OrderListBloc>();
    final sent = await showShipmentConfirmDialog(context, storedOrderItemIds: ids);
    if (sent == true && !bloc.isClosed) {
      _clearSelection();
      bloc.add(SearchOrders());
    }
  }

  /// 내부 발주·해제 결과 처리 — 건수는 배송건(박스) 단위다(서버가 배송 묶음 단위로 바꾼다).
  void _onInternalState(BuildContext context, OrderInternalStageState state) {
    if (state.forbidden) {
      _showAckSnackBar(context, '권한이 없습니다.', const []);
      return;
    }
    final result = state.result;
    if (result != null) {
      final label = switch (state.lastAction) {
        InternalStageAction.release => '내부 발주 해제 완료',
        InternalStageAction.cancel => '예약 취소 완료',
        _ => '내부 발주처리 완료',
      };
      var summary = '$label — ${result.changedShipments}건';
      if (result.skippedOrderIds.isNotEmpty) {
        summary += ' / 제외 ${result.skippedOrderIds.length}건(대상 아님)';
      }
      if (result.unsupported.isNotEmpty) {
        summary += ' / 처리불가 ${result.unsupported.length}건';
      }
      _showAckSnackBar(context, summary, const []);
      _clearSelection();
      context.read<OrderListBloc>().add(SearchOrders());
      context
          .read<OrderInternalStageBloc>()
          .add(const InternalStageResultCleared());
      return;
    }
    final message = state.errorMessage;
    if (message == null) return;
    showErrorToast(context, message);
    context
        .read<OrderInternalStageBloc>()
        .add(const InternalStageResultCleared());
  }

  /// Send result (D8·D9 · FEATURE_2610_17 / D57). Same wording as web
  /// `buildMessage`: 「발주처리 완료」, one line per marketplace that was sent,
  /// then the skipped / unsupported line — even when only targets are sent, a
  /// stale list can make the server return `skipped` · `unsupported`.
  void _onAcknowledgeState(BuildContext context, OrderAcknowledgeState state) {
    if (state.forbidden) {
      _showAckSnackBar(context, '발주처리 권한이 없습니다.', const []);
      return;
    }

    final result = state.result;
    if (result != null) {
      final lines = <String>['발주처리 완료'];
      for (final part in result.byPlatform) {
        final name = platformName(part.platform);
        lines.add(part.failed.isEmpty
            ? '$name: 성공 ${part.succeeded}건'
            : '$name: 성공 ${part.succeeded}건 / 실패 ${part.failed.length}건');
      }
      final notSent = <String>[
        if (result.skipped.isNotEmpty)
          '제외 ${result.skipped.length}건(결제완료 아님)',
        if (result.unsupported.isNotEmpty)
          '처리불가 ${result.unsupported.length}건',
      ];
      if (notSent.isNotEmpty) lines.add(notSent.join(' / '));
      // Failure reasons as the marketplace gave them, named per marketplace,
      // deduped, at most 3 per marketplace (D8 · FEATURE_2610_17 / D57).
      final details = [
        for (final part in result.byPlatform)
          ...part.failed
              .map((f) =>
                  '${platformName(part.platform)} · '
                  '${f.resultCode}: ${f.message}')
              .toSet()
              .take(3),
      ];
      _showAckSnackBar(context, lines.join('\n'), details);
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
    showErrorToast(context, message);
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

  /// 2nd-row chip value and its setter — both are parent state
  /// (FEATURE_2610_07 / D18).
  final PaidStage paidStage;
  final void Function(PaidStage stage) onSelectPaidStage;

  /// 발주처리 선택 — 값·콜백 모두 부모 state 다(`_LoadedBody` 를 Stateful 로 승격하지 말 것:
  /// 선택을 초기화해야 하는 채널 필터 콜백이 부모에 있다).
  final Set<int> selectedIds;
  final void Function(int orderItemId) onToggleSelect;

  /// 목록이 바뀌는 이벤트(`bloc.add`) **직전**에 함께 부른다 — 선택이 무효가 된다.
  final VoidCallback onClearSelection;

  /// The parent shows the confirm dialog and dispatches `AcknowledgeRequested`.
  /// 🔴 Only the acknowledge targets are passed — the checkbox ignores the
  /// status, so they differ from the whole selection.
  /// `orderCount` = the order count for the confirm text (FEATURE_2611_30 /
  /// R3). [includesInternal] = some of them are at an internal stage (the
  /// D14 notice).
  final void Function(List<int> ids, int orderCount, bool includesInternal)
      onAcknowledge;

  /// [내부 발주처리] — 결제완료·내부 단계 없음만 추려 넘긴다(FEATURE_2609_75 / D1).
  final void Function(List<int> ids) onInternal;

  /// [내부 발주 해제] — 「내부 상품준비중」만 추려 넘긴다(D18 행1). 확인 다이얼로그는 부모가 띄운다.
  final void Function(List<int> ids) onRelease;

  /// [예약 취소] — 「발송대기중」만 추려 넘긴다(FEATURE_2609_75 / D18 행2).
  final void Function(List<int> ids) onCancelReservation;

  /// [저장된 송장으로 발송] — 내부 단계 주문만 추려 넘긴다(D18 🔁). 다이얼로그는 부모가 연다.
  final void Function(List<int> ids) onShipStored;

  /// The parent dispatches `RefreshRequested` (no confirm dialog — it is a
  /// read). Only the selected Coupang orders are passed (FEATURE_2610_17 / D12).
  final void Function(List<int> ids) onRefresh;

  const _LoadedBody({
    required this.state,
    required this.searchController,
    required this.selectedAccountId,
    required this.onSelectAccount,
    required this.paidStage,
    required this.onSelectPaidStage,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onClearSelection,
    required this.onAcknowledge,
    required this.onInternal,
    required this.onRelease,
    required this.onCancelReservation,
    required this.onShipStored,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    final bloc = context.read<OrderListBloc>();
    final busy = s.isSearching || s.isSyncing;

    // 출고관리는 미발송 주문만 다루므로 채널 옵션 = 동기화 대상 그대로다(주문내역과 다름, D7-a).
    final targets = s.syncTargets;
    // When the targets arrive late or change, the picked account can drop out
    // of the options — fall back to all channels.
    final accountValue = _shipmentAccountValue(s, selectedAccountId);

    // s.filteredOrders is not shipment-scoped. Narrow to the shipment scope
    // first and count the chips from this list — s.statusCounts would also
    // count cancelled and shipped orders, and the chips would drift from it.
    // Order: channel → search → status → paid stage (FEATURE_2610_07 / D16).
    // Chip counts also count the search result. The list and the chip counts
    // are per order (FEATURE_2611_30 / D17).
    final scoped = s.orders
        .where((o) => kShipmentStatuses.contains(o.status))
        .where((o) => !o.cancelled) // 전량취소는 발송 대상 아님 (서버 판정, D26)
        .where((o) =>
            accountValue == null || o.marketplaceAccountId == accountValue)
        .where((o) => matchesOrderSearch(o, s.searchField, s.searchTerm))
        .toList();
    final counts = <OrderStatus, int>{
      for (final status in kShipmentStatuses)
        status: countOrders(scoped.where((o) => o.status == status)),
    };
    // 2nd-row chip counts: the same list as the 1st-row counts, narrowed to
    // PAID (FEATURE_2610_07 / D13).
    final paidScoped =
        scoped.where((o) => o.status == OrderStatus.paid).toList();
    final visible = s.selectedStatus == null
        ? scoped
        : scoped
            .where((o) => o.status == s.selectedStatus)
            .where((o) =>
                s.selectedStatus != OrderStatus.paid ||
                matchesPaidStage(o, paidStage))
            .toList();
    final visibleOrderKeys = visible.map(orderKey).toSet();
    final visibleOrders = groupOrders(s.orders)
        .where((order) => visibleOrderKeys.contains(order.key))
        .toList();
    // 선택 중 실제로 발주처리되는 라인 id. 상태 탭은 선택을 비우지 않으므로 `visible` 이 아니라
    // 채널 필터까지만 적용한 `scoped` 에서 찾는다 — 탭에 가려진 선택도 세어야 한다.
    final ackTargetIds = scoped
        .where((o) => selectedIds.contains(o.id) && _isAcknowledgeTarget(o))
        .map((o) => o.id)
        .toList();
    final internalTargetIds = scoped
        .where((o) => selectedIds.contains(o.id) && _isInternalTarget(o))
        .map((o) => o.id)
        .toList();
    final releaseTargetIds = scoped
        .where((o) => selectedIds.contains(o.id) && _isReleaseTarget(o))
        .map((o) => o.id)
        .toList();
    final cancelTargetIds = scoped
        .where((o) =>
            selectedIds.contains(o.id) && _isCancelReservationTarget(o))
        .map((o) => o.id)
        .toList();
    final storedTargetIds = scoped
        .where((o) => selectedIds.contains(o.id) && _isStoredShipTarget(o))
        .map((o) => o.id)
        .toList();
    final refreshTargetIds = scoped
        .where((o) => selectedIds.contains(o.id) && _isRefreshTarget(o))
        .map((o) => o.id)
        .toList();
    // D14 — 발주처리로 보낼 주문 중 내부 단계가 있는 것이 하나라도 있는가.
    final includesInternal = scoped
        .any((o) => ackTargetIds.contains(o.id) && o.internalStage != null);
    final selectedOrderCount =
        countOrders(s.orders.where((o) => selectedIds.contains(o.id)));
    final ackOrderCount = countOrders(scoped.where(
        (o) => selectedIds.contains(o.id) && _isAcknowledgeTarget(o)));
    final isAckOverLimit = ackTargetIds.length > _kMaxAcknowledgeSelection;
    final colorScheme = Theme.of(context).colorScheme;
    final hintStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final selectableOrders =
        visibleOrders.where((o) => o.lines.any(_isSelectable)).toList();
    final allSelected = selectableOrders.isNotEmpty &&
        selectableOrders
            .every((o) => o.lines.every((l) => selectedIds.contains(l.id)));
    // Same loop as the card's onToggleSelect — select every visible
    // selectable order, or clear every visible order (FEATURE_2611_32 / D13).
    void toggleAll() {
      final target = !allSelected;
      final orders = allSelected ? visibleOrders : selectableOrders;
      for (final order in orders) {
        for (final line in order.lines) {
          if (selectedIds.contains(line.id) != target) {
            onToggleSelect(line.id);
          }
        }
      }
    }

    return Column(
      children: [
        Expanded(
          child: AppPageBody.slivers(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                                    : (value) {
                                        onClearSelection();
                                        bloc.add(SelectSeller(sellerId: value));
                                      },
                              ),
                              const SizedBox(width: 8),
                              // 채널(계정) 필터 — 목록과 동기화 범위를 함께 좁힌다(D7).
                              AppFilterChip<int?>(
                                label: accountValue == null
                                    ? '채널'
                                    : targets
                                            .firstWhere((t) =>
                                                t.accountId == accountValue)
                                            .accountAlias ??
                                        '채널 #$accountValue',
                                value: accountValue,
                                options: [
                                  const AppFilterOption(null, '전체'),
                                  for (final target in targets)
                                    AppFilterOption(
                                      target.accountId,
                                      target.accountAlias ??
                                          '채널 #${target.accountId}',
                                    ),
                                ],
                                highlighted: accountValue != null,
                                onSelected: busy ? null : onSelectAccount,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
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
                  // The list (client filter) and the label sheet (server, 30
                  // days) cover different ranges (FEATURE_2611_32 / D4-16).
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '목록은 최근 14일 기준입니다. 접수시트는 30일까지 포함합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // The server processes sheet/confirm by sellerId, so the channel
                  // filter does not narrow them (same notice as web).
                  if (accountValue != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '접수시트·발송처리는 선택한 판매자의 전 채널을 포함합니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // 검색 — 클라이언트 필터라 서버를 부르지 않는다(주문내역과 같은 규칙).
                  // 목록이 줄어들면 화면 밖 건이 전송되지 않게 선택을 버린다.
                  OrderSearchBar(
                    controller: searchController,
                    field: s.searchField,
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
                  // Four actions as a 4-column grid (FEATURE_2611_32 / D10);
                  // none is gated by OrderListBloc.busy.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 「발주 목록」: edit parcel counts on the preview page,
                      // then download.
                      Expanded(
                        child: _ShipmentActionTile(
                          icon: Icons.download,
                          label: '발주 목록',
                          onPressed: () =>
                              context.push(Routes.shippingLabelPreviewPath),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // The 「내부 상품준비중」 label sheet (FEATURE_2609_75 /
                      // D25·D26).
                      Expanded(
                        child: _ShipmentActionTile(
                          icon: Icons.download,
                          label: '내부 발주 목록',
                          onPressed: () => context
                              .push(Routes.shippingLabelPreviewInternalPath),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Shipment (label upload): carrier result xlsx → the
                      // marketplace invoice upload batch (Coupang · 11st ·
                      // LotteON, FEATURE_2610_17 / D2).
                      Expanded(
                        child: _ShipmentActionTile(
                          icon: Icons.upload_file,
                          label: '발송처리',
                          highlighted: true,
                          onPressed: () async {
                            final uploaded =
                                await showShipmentConfirmDialog(context);
                            // Guard isClosed: the page can be popped while
                            // the dialog is open.
                            if (uploaded == true && !bloc.isClosed) {
                              // Show the status the backend moved at once —
                              // SearchOrders keeps the seller filter.
                              onClearSelection();
                              bloc.add(SearchOrders());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 「예약 발송 현황」 (D15·D16·D21) — the badges and the
                      // list may have changed on return, so search again.
                      Expanded(
                        child: _ShipmentActionTile(
                          icon: Icons.schedule,
                          label: '예약 발송 현황',
                          onPressed: () async {
                            await context.push(Routes.reservedShipmentPath);
                            if (!bloc.isClosed) {
                              onClearSelection();
                              bloc.add(SearchOrders());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ),
          const SizedBox(height: 8),

          AppCard.flush(
            child: OrderStatusFilterBar(
              selectedStatus: s.selectedStatus,
              counts: counts,
              allCount: countOrders(scoped),
              onSelect: (status) {
                onClearSelection();
                // Every 1st-row tap puts the 2nd row back to 'all'
                // (FEATURE_2610_07 / D14).
                onSelectPaidStage(PaidStage.all);
                bloc.add(SelectStatus(status: status));
              },
              statuses: kShipmentStatuses,
              equalWidth: true,
            ),
          ),
          if (s.selectedStatus == OrderStatus.paid) ...[
            const SizedBox(height: 8),
            PaidStageFilterBar(
              orders: paidScoped,
              selected: paidStage,
              onSelect: onSelectPaidStage,
            ),
          ],
          const SizedBox(height: 8),

          Row(
            children: [
              OrderSelectBox(
                selected: allSelected,
                onTap: selectableOrders.isEmpty ? null : toggleAll,
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: selectableOrders.isEmpty ? null : toggleAll,
                child: const Text(
                  '전체 선택',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '총 ${visibleOrders.length}건',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
          ),
        ),
        if (visibleOrders.isEmpty)
          const SliverToBoxAdapter(child: AppEmpty('발송할 주문이 없습니다.'))
        else
          SliverList.separated(
            itemCount: visibleOrders.length,
            separatorBuilder: (_, __) => const AppRowGap(),
            itemBuilder: (context, index) {
              final o = visibleOrders[index];
              return OrderCard(
                order: o,
                collapsed: s.collapsedOrderKeys.contains(o.key),
                onToggleCollapsed: () =>
                    bloc.add(ToggleOrderCollapsed(orderKey: o.key)),
                selected:
                    o.lines.every((line) => selectedIds.contains(line.id)),
                selectable: o.lines.any(_isSelectable),
                onToggleSelect: (order) {
                  final target = !order.lines
                      .every((line) => selectedIds.contains(line.id));
                  for (final line in order.lines) {
                    if (selectedIds.contains(line.id) != target) {
                      onToggleSelect(line.id);
                    }
                  }
                },
                // 카드가 내부 단계 주문일 때만 버튼을 그린다(D18). 시트 안에서 저장·조회한다.
                onEditInvoice: () =>
                    showStoredInvoiceSheet(context,
                        o.lines.first.externalOrderId, o.lines.first.platform),
              );
            },
          ),
      ],
          ),
        ),
        if (visibleOrders.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + AppPageBody.navBarInset(context),
              ),
              // ⚠️ BlocBuilder wraps only this group — wrapping the Column or
              // SliverList would rebuild the whole list on every send (same
              // caution as in the order detail).
              child:
                  BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
                builder: (context, internalState) =>
                    BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
                  builder: (context, ackState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Only the over-limit warning stays — the guidance
                      // lines took half the screen (same as web docked bar).
                      if (isAckOverLimit)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '한 번에 $_kMaxAcknowledgeSelection건까지 '
                            '발주처리할 수 있습니다. 선택을 줄여주세요.',
                            style: hintStyle.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          // The only place that states the selected count —
                          // never in a button label.
                          Text(
                            selectedIds.isEmpty
                                ? '주문을 선택하세요'
                                : '$selectedOrderCount건 선택',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            // One row of equal cells: icon + short name below
                            // (icons alone were not recognizable); the full
                            // name is the tooltip (long press). [내부 발주처리] sits right next to
                            // [발주처리] and stays green — written here, not
                            // in the theme (FEATURE_2609_75 / D13 ·
                            // FEATURE_2610_02 / D101).
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // [주문 상태 갱신] — unlike [발주처리] there is
                                // no permission gate (2609_50 D18); with no
                                // selection it shows but is disabled.
                                BlocBuilder<OrderRefreshBloc,
                                    OrderRefreshState>(
                                  builder: (context, refreshState) =>
                                      _BarIconButton(
                                    icon: Icons.refresh,
                                    label: '주문 상태 갱신',
                                    shortLabel: '상태 갱신',
                                    busy: refreshState.submitting,
                                    onPressed: refreshTargetIds.isEmpty ||
                                            refreshState.submitting
                                        ? null
                                        : () => onRefresh(refreshTargetIds),
                                  ),
                                ),
                                if (ackTargetIds.isNotEmpty &&
                                    !ackState.forbidden)
                                  _BarIconButton(
                                    icon: Icons.assignment_turned_in_outlined,
                                    label: '발주처리',
                                    shortLabel: '발주처리',
                                    filled: true,
                                    busy: ackState.submitting,
                                    onPressed: ackState.submitting ||
                                            isAckOverLimit
                                        ? null
                                        : () => onAcknowledge(
                                            ackTargetIds,
                                            ackOrderCount,
                                            includesInternal),
                                  ),
                                if (internalTargetIds.isNotEmpty &&
                                    !internalState.forbidden)
                                  _BarIconButton(
                                    icon: Icons.inventory_2_outlined,
                                    label: '내부 발주처리',
                                    shortLabel: '내부 발주',
                                    filled: true,
                                    background: AppColors.brandGreen,
                                    foreground: colorScheme.onSecondary,
                                    busy: internalState.submitting ==
                                        InternalStageAction.mark,
                                    onPressed: internalState.submitting !=
                                            null
                                        ? null
                                        : () => onInternal(internalTargetIds),
                                  ),
                                if (releaseTargetIds.isNotEmpty &&
                                    !internalState.forbidden)
                                  _BarIconButton(
                                    icon: Icons.undo,
                                    label: '내부 발주 해제',
                                    shortLabel: '발주 해제',
                                    busy: internalState.submitting ==
                                        InternalStageAction.release,
                                    onPressed: internalState.submitting !=
                                            null
                                        ? null
                                        : () => onRelease(releaseTargetIds),
                                  ),
                                if (cancelTargetIds.isNotEmpty &&
                                    !internalState.forbidden)
                                  _BarIconButton(
                                    icon: Icons.event_busy_outlined,
                                    label: '예약 취소',
                                    shortLabel: '예약 취소',
                                    busy: internalState.submitting ==
                                        InternalStageAction.cancel,
                                    onPressed: internalState.submitting !=
                                            null
                                        ? null
                                        : () => onCancelReservation(
                                            cancelTargetIds),
                                  ),
                                // D18 🔁 — [예약 발송]/[지금 발송] with the
                                // stored invoice, no file (the stored-invoice
                                // mode of the [발송처리] dialog).
                                if (storedTargetIds.isNotEmpty &&
                                    !internalState.forbidden)
                                  _BarIconButton(
                                    icon: Icons.local_shipping_outlined,
                                    label: '저장된 송장으로 발송',
                                    shortLabel: '송장 발송',
                                    onPressed: internalState.submitting !=
                                            null
                                        ? null
                                        : () => onShipStored(storedTargetIds),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Cell of the 「출고관리」 bottom selection bar — a 36×36 icon box with a short
/// name below (44 wide, so six cells fit a 360dp screen). The full name is the
/// tooltip and semantics label. Outlined by default; `filled` for [발주처리]
/// (theme yellow) and [내부 발주처리] (`background` green).
class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.label,
    required this.shortLabel,
    required this.onPressed,
    this.filled = false,
    this.busy = false,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String label;

  /// Name under the icon — at most 4 Korean letters.
  final String shortLabel;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 20);
    const constraints = BoxConstraints.tightFor(width: 36, height: 36);
    final button = filled
        ? IconButton.filled(
            constraints: constraints,
            padding: EdgeInsets.zero,
            style: background == null
                ? null
                : IconButton.styleFrom(
                    backgroundColor: background,
                    foregroundColor: foreground,
                  ),
            onPressed: onPressed,
            icon: child,
          )
        : IconButton.outlined(
            constraints: constraints,
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: child,
          );
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                button,
                const SizedBox(height: 2),
                Text(
                  shortLabel,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: enabled
                        ? AppColors.textStrong
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 4-column grid cell for the 「출고관리」 action row: a 44 icon box (soft
/// yellow, [발송처리] yellow) with the label below, up to two lines
/// (FEATURE_2611_32 / D10 · D4-15).
class _ShipmentActionTile extends StatelessWidget {
  const _ShipmentActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: highlighted
                      ? AppColors.brandMain
                      : AppColors.brandMainSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.foregroundLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
      );
}
