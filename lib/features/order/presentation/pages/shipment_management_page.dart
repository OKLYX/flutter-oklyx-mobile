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
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_filter_bar.dart';
import '../widgets/sync_progress_dialog.dart';

/// 주문관리 > 출고관리 페이지 (미발송 주문 작업대)
///
/// **용도**: 아직 내보내지 않은 주문(결제완료·상품준비중)만 모아, 송장 접수시트를 뽑고
/// 택배사 결과 파일로 발송처리하는 **작업 화면**. 지난 주문 조회는 주문내역이 담당한다
/// (PLAN 2609_15 D1·D4).
///
/// **필수 규칙**:
/// - 목록·배지는 [kShipmentStatuses] 로 좁히고 전량취소([isFullyCanceled])는 제외한다.
///   화면에서 리터럴 상태 배열이나 자체 취소 판정을 만들지 말 것.
/// - 동기화 오케스트레이션은 기존 [OrderListBloc] 이벤트를 그대로 쓴다(신규 이벤트 금지, D6).
/// - 목록 카드·상태 칩은 공유 위젯([OrderCard]·[OrderStatusFilterBar])을 쓴다.
///
/// ⚠️ [OrderListBloc] 은 `registerFactory` 라 주문내역과 **인스턴스를 공유하지 않는다** —
/// 두 화면의 선택 상태가 이어질 거라 기대하지 말 것.
/// ⚠️ 기간 선택 UI 없음(D8) — 기본 창(14일)만 쓴다. `SelectPeriod` 를 호출하지 않는다.
/// ❌ 채널 필터를 BLoC 이벤트로 만들지 말 것 — 화면 로컬 state 다(D3).
class ShipmentManagementPage extends StatelessWidget {
  const ShipmentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderListBloc>()..add(LoadOrders()),
      child: const _ShipmentManagementView(),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '출고관리',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<OrderListBloc, OrderListState>(
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
              message: '출고 대상 조회에 실패했습니다.',
              onRetry: () => context.read<OrderListBloc>().add(LoadOrders()),
            );
          }

          return _LoadedBody(
            state: state as OrderListLoaded,
            selectedAccountId: _selectedAccountId,
            onSelectAccount: (accountId) =>
                setState(() => _selectedAccountId = accountId),
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
  final OrderListLoaded state;
  final int? selectedAccountId;
  final void Function(int? accountId) onSelectAccount;

  const _LoadedBody({
    required this.state,
    required this.selectedAccountId,
    required this.onSelectAccount,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    final bloc = context.read<OrderListBloc>();
    final busy = s.isSearching || s.isSyncing;

    // 출고관리는 미발송 주문만 다루므로 채널 옵션 = 동기화 대상 그대로다(주문내역과 다름, D7-a).
    final targets = s.syncTargets;
    // 대상 목록이 늦게 오거나 바뀌면 고른 값이 items 에서 사라져 드롭다운이 assert 로 죽는다.
    final accountValue =
        targets.any((t) => t.accountId == selectedAccountId)
            ? selectedAccountId
            : null;

    // s.filteredOrders 는 전 상태 기준이다. 출고관리 범위를 먼저 좁히고, 배지도 이 목록으로 센다
    // — s.statusCounts 를 쓰면 취소·배송 건까지 세어 목록과 배지가 어긋난다.
    final scoped = s.orders
        .where((o) => kShipmentStatuses.contains(o.status))
        .where((o) => !isFullyCanceled(o)) // 전량취소는 발송 대상 아님
        .where((o) => accountValue == null || o.marketplaceAccountId == accountValue)
        .toList();
    final counts = <String, int>{
      for (final status in kShipmentStatuses)
        status: scoped.where((o) => o.status == status).length,
    };
    final visible = s.selectedStatus == null
        ? scoped
        : scoped.where((o) => o.status == s.selectedStatus).toList();

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
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '목록은 최근 14일 기준입니다. 접수시트는 30일까지 포함합니다.',
              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          // 채널 미선택이면 전 채널, 선택돼 있으면 그 채널만(D7).
                          onPressed: busy
                              ? null
                              : () {
                                  if (accountValue == null) {
                                    bloc.add(SyncOrders());
                                    return;
                                  }
                                  bloc.add(SyncSelectedChannels(
                                    targets: targets
                                        .where((t) =>
                                            t.accountId == accountValue)
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
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
            statuses: kShipmentStatuses,
          ),
          const SizedBox(height: 8),

          Text(
            '총 ${visible.length}건',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    itemBuilder: (context, index) =>
                        OrderCard(order: visible[index]),
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
