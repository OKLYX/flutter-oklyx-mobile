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
        // 일시적 오류와 입고 결과 안내(stockRecorded)를 SnackBar로 표시한다.
        listenWhen: (prev, curr) =>
            curr is PurchaseListLoaded &&
            (curr.actionError != null || curr.stockRecorded != null),
        listener: (context, state) {
          final loaded = state as PurchaseListLoaded;
          if (loaded.actionError != null) {
            _snack(context, loaded.actionError!);
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
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PurchaseListError) {
            return _ErrorRetry(
              message: state.message,
              onRetry: () =>
                  context.read<PurchaseListBloc>().add(LoadPurchaseList()),
            );
          }
          return _LoadedBody(state: state as PurchaseListLoaded);
        },
      ),
    );
  }

  /// 하단 네비게이션이 오버레이라 floating + bottom:70 이 필수다.
  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
        ),
      );
  }
}

class _LoadedBody extends StatelessWidget {
  final PurchaseListLoaded state;

  const _LoadedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseListBloc>();
    final busy = state.isRefreshing || state.isSyncing;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 탭 스위처 (최상단)
          _TabSwitcher(
            activeTab: state.activeTab,
            onChanged: (tab) => bloc.add(SwitchTab(tab: tab)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.activeTab == PurchaseTab.active
                ? _ActiveTabBody(state: state, busy: busy)
                : _CompletedTabBody(state: state, busy: busy),
          ),
        ],
      ),
    );
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

  const _ActiveTabBody({required this.state, required this.busy});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseListBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              color: Colors.green[50],
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '동기화 완료 — 신규 ${state.syncResult!.newOrders}건, '
              '수정 ${state.syncResult!.updatedOrders}건, '
              '취소 ${state.syncResult!.canceledUpdated}건',
              style: TextStyle(fontSize: 13, color: Colors.green[800]),
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        // 항목 리스트 + 미매핑 섹션을 하나의 스크롤 영역으로 합쳐
        // 마지막 항목/섹션이 플로팅 하단바에 가리지 않도록 bottom 패딩을 둔다.
        // 키보드가 올라와도 입력칸이 가리지 않도록 viewInsets 만큼 더 띄운다.
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (state.items.isEmpty && state.unmappedOrders.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('구매할 항목이 없습니다.')),
                  ),
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
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: kBottomNavigationBarHeight +
                        24 +
                        MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: UnmappedOrdersSection(orders: state.unmappedOrders),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletedTabBody extends StatelessWidget {
  final PurchaseListLoaded state;
  final bool busy;

  const _CompletedTabBody({required this.state, required this.busy});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseListBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompletedPurchaseFilter(
          from: state.completedFrom,
          to: state.completedTo,
          isLoading: state.isLoadingCompleted,
          onApply: (from, to) => bloc.add(
            ApplyCompletedFilter(from: from, to: to),
          ),
          onReset: () => bloc.add(ResetCompletedFilter()),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildList(context, bloc)),
      ],
    );
  }

  Widget _buildList(BuildContext context, PurchaseListBloc bloc) {
    if (state.isLoadingCompleted) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = state.completedItems ?? const [];
    if (items.isEmpty) {
      return const Center(child: Text('구매완료 내역이 없습니다.'));
    }
    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: kBottomNavigationBarHeight +
            24 +
            MediaQuery.of(context).viewInsets.bottom,
      ),
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
