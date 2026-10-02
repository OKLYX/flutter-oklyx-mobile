import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/purchase_list_bloc.dart';
import '../bloc/purchase_list_event.dart';
import '../bloc/purchase_list_state.dart';
import '../widgets/add_manual_item_dialog.dart';
import '../widgets/completed_purchase_filter.dart';
import '../widgets/purchase_product_card.dart';
import '../widgets/unmapped_orders_section.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// 구매목록 페이지 (하단 탭 3번째, `/list-to-shop`).
///
/// **용도**: 프론트 구매목록(dashboard/purchase/list)을 모바일로 이식.
/// **기능**:
/// - 툴바: [주문내역 동기화](동기화 + 재적재 한 번에) · [수동 추가]
///   🔴 판매자 드롭다운·[재적재] 는 없다(PLAN 2609_29 D11·D12)
/// - 탭: 구매목록 / 구매완료내역(지연 로드, 기간 필터만)
/// - 미매핑주문 섹션 (옵션 미등록 주문 안내)
/// - 상품 카드 펼침 → 입고 카드 + 최근 구매이력 + 채널 칩 + 주문 줄 (두 탭 동일, D21)
/// - 수동항목 추가 (상품 검색·선택 + 수량)
class PurchaseListPage extends StatelessWidget {
  const PurchaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PurchaseListBloc>()..add(LoadPurchaseList()),
      child: const _PurchaseListView(),
    );
  }
}

class _PurchaseListView extends StatelessWidget {
  const _PurchaseListView();

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '구매목록',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<PurchaseListBloc, PurchaseListState>(
        // Shows transient errors and the stock intake result notice
        // (stockRecorded) as a toast.
        listenWhen: (prev, curr) =>
            curr is PurchaseListLoaded &&
            (curr.actionError != null || curr.stockRecorded != null),
        listener: (context, state) {
          final loaded = state as PurchaseListLoaded;
          if (loaded.actionError != null) {
            showErrorToast(context, loaded.actionError!);
          }
          if (loaded.stockRecorded != null) {
            if (loaded.stockRecorded == false) {
              _snack(context,
                  '재고는 반영되지 않았습니다 — 실물이 줄었다면 재고 화면에서 조정하세요');
            }
            // ⚠️ 1회성 안내다 — 소비 즉시 지운다(안 지우면 다음 리빌드에 또 뜬다).
            context.read<PurchaseListBloc>().add(ClearStockNotice());
          }
        },
        builder: (context, state) {
          if (state is PurchaseListInitial || state is PurchaseListLoading) {
            return const AppPageBody(children: [AppLoading()]);
          }
          if (state is PurchaseListError) {
            return AppPageBody(
              children: [
                AppErrorBox(
                  message: state.message,
                  action: FilledButton(
                    onPressed: () =>
                        context.read<PurchaseListBloc>().add(LoadPurchaseList()),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            );
          }
          return _LoadedBody(state: state as PurchaseListLoaded);
        },
      ),
    );
  }

  /// Only the "stock not recorded" notice passes through here — kind =
  /// notice. Action errors call showErrorToast directly
  /// (FEATURE_2610_02 · N13).
  void _snack(BuildContext context, String message) {
    showNoticeToast(context, message);
  }
}

class _LoadedBody extends StatelessWidget {
  final PurchaseListLoaded state;

  const _LoadedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseListBloc>();
    final busy = state.isRefreshing || state.isSyncing;

    final tabs = _TabSwitcher(
      activeTab: state.activeTab,
      onChanged: (tab) => bloc.add(SwitchTab(tab: tab)),
    );
    // Each tab owns one scroll; the tab switcher is its first block (D100).
    return state.activeTab == PurchaseTab.active
        ? _ActiveTabBody(state: state, busy: busy, tabs: tabs)
        : _CompletedTabBody(state: state, busy: busy, tabs: tabs);
  }
}

/// 구매목록 / 구매완료내역 탭 스위처.
class _TabSwitcher extends StatelessWidget {
  final PurchaseTab activeTab;
  final ValueChanged<PurchaseTab> onChanged;

  const _TabSwitcher({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PurchaseTab>(
        segments: const [
          ButtonSegment(value: PurchaseTab.active, label: Text('구매목록')),
          ButtonSegment(
              value: PurchaseTab.completed, label: Text('구매완료내역')),
        ],
        selected: {activeTab},
        showSelectedIcon: false,
        onSelectionChanged: (set) => onChanged(set.first),
      ),
    );
  }
}

class _ActiveTabBody extends StatelessWidget {
  final PurchaseListLoaded state;
  final bool busy;
  final Widget tabs;

  const _ActiveTabBody({
    required this.state,
    required this.busy,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseListBloc>();

    return AppPageBody.slivers(
      extraBottom: MediaQuery.of(context).viewInsets.bottom,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tabs,
        const SizedBox(height: 8),
        // 툴바: 주문내역 동기화 + 수동 추가 (판매자 드롭다운·재적재 없음)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => bloc.add(SyncOrders()),
                icon: state.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: Text(state.isSyncing ? '동기화 중...' : '주문내역 동기화'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => showDialog<void>(
                          context: context,
                          builder: (_) => AddManualItemDialog(
                            onSubmit: (productId, quantity) => bloc.add(
                              AddManualItem(
                                productId: productId,
                                quantity: quantity,
                              ),
                            ),
                          ),
                        ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('수동 추가'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.syncResult != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              border: Border.all(color: AppColors.successBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '동기화 완료 — 신규 ${state.syncResult!.newOrders}건, '
              '수정 ${state.syncResult!.updatedOrders}건, '
              '취소 ${state.syncResult!.canceledUpdated}건',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.successForeground,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              state.unmappedOrders.isEmpty
                  ? '${state.items.length}건'
                  : '${state.items.length}건 (미등록 주문 ${state.unmappedOrders.length}건)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.isRefreshing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
          ),
        ),
              if (state.items.isEmpty && state.unmappedOrders.isEmpty)
                const SliverToBoxAdapter(
                  child: AppEmpty('구매할 항목이 없습니다.'),
                )
              else if (state.items.isNotEmpty)
                SliverList.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return PurchaseProductCard(
                      key: ValueKey(item.productId),
                      item: item,
                      sellers: state.sellers,
                      expanded: item.productId == state.expandedProductId,
                      busy: busy,
                      onToggle: () =>
                          bloc.add(ToggleExpand(productId: item.productId)),
                      onRecordPurchase: ({
                        required int productId,
                        required int sellerId,
                        required String purchasedOn,
                        required int quantity,
                        double? totalAmount,
                        double? unitPrice,
                        required bool reflectToBasePrice,
                      }) =>
                          bloc.add(RecordPurchase(
                        productId: productId,
                        sellerId: sellerId,
                        purchasedOn: purchasedOn,
                        quantity: quantity,
                        totalAmount: totalAmount,
                        unitPrice: unitPrice,
                        reflectToBasePrice: reflectToBasePrice,
                      )),
                    );
                  },
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: UnmappedOrdersSection(orders: state.unmappedOrders),
                ),
              ),
      ],
    );
  }
}

class _CompletedTabBody extends StatelessWidget {
  final PurchaseListLoaded state;
  final bool busy;
  final Widget tabs;

  const _CompletedTabBody({
    required this.state,
    required this.busy,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseListBloc>();

    return AppPageBody.slivers(
      extraBottom: MediaQuery.of(context).viewInsets.bottom,
      slivers: [
        SliverToBoxAdapter(child: tabs),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: CompletedPurchaseFilter(
            from: state.completedFrom,
            to: state.completedTo,
            isLoading: state.isLoadingCompleted,
            onApply: (from, to) => bloc.add(
              ApplyCompletedFilter(from: from, to: to),
            ),
            onReset: () => bloc.add(ResetCompletedFilter()),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        _buildList(context, bloc),
      ],
    );
  }

  Widget _buildList(BuildContext context, PurchaseListBloc bloc) {
    if (state.isLoadingCompleted) {
      return const SliverToBoxAdapter(child: AppLoading());
    }
    final items = state.completedItems ?? const [];
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmpty('구매완료 내역이 없습니다.'),
      );
    }
    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        // 완료 탭도 구매목록 탭과 **같은 카드**를 쓴다(D21) — 추가 입고·정정이 가능하다.
        return PurchaseProductCard(
          key: ValueKey(item.productId),
          item: item,
          sellers: state.sellers,
          expanded: item.productId == state.expandedCompletedProductId,
          busy: busy,
          onToggle: () =>
              bloc.add(ToggleExpandCompleted(productId: item.productId)),
          onRecordPurchase: ({
            required int productId,
            required int sellerId,
            required String purchasedOn,
            required int quantity,
            double? totalAmount,
            double? unitPrice,
            required bool reflectToBasePrice,
          }) =>
              bloc.add(RecordPurchase(
            productId: productId,
            sellerId: sellerId,
            purchasedOn: purchasedOn,
            quantity: quantity,
            totalAmount: totalAmount,
            unitPrice: unitPrice,
            reflectToBasePrice: reflectToBasePrice,
          )),
        );
      },
    );
  }
}
