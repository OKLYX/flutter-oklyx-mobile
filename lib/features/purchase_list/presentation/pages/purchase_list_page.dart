import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/purchase_list_item.dart';
import '../bloc/purchase_list_bloc.dart';
import '../bloc/purchase_list_event.dart';
import '../bloc/purchase_list_state.dart';
import '../bloc/purchase_setting_bloc.dart';
import '../bloc/purchase_setting_event.dart';
import '../widgets/add_manual_item_dialog.dart';
import 'purchase_product_detail_page.dart';
import '../widgets/completed_purchase_filter.dart';
import '../widgets/purchase_product_card.dart';
import '../widgets/purchase_share_actions.dart';
import '../widgets/receipt_intake_sheet.dart';
import '../widgets/seller_filter_dropdown.dart';
import '../widgets/unmapped_orders_section.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Purchase list page (third bottom tab, `/list-to-shop`).
///
/// **Purpose**: the web purchase list (dashboard/purchase/list) on mobile.
/// **Parts**:
/// - Toolbar: [주문내역 동기화] (sync + re-extract at once) · [수동 추가];
///   a full-width [영수증 입고] under it (receipt popup, FEATURE_2610_18 D46)
///   🔴 no [재적재] (PLAN 2609_29 D12)
/// - Tabs: 「구매목록」 / 「구매완료내역」 (lazy, processing-day filter)
/// - Seller filter under the tabs on both tabs (FEATURE_2610_09 D5), hidden
///   with one seller (D53). A chosen seller puts the share buttons under each
///   card (D83)
/// - 「오늘 넘김」 group under the list (D67)
/// - Unmapped orders section (orders whose option is unregistered)
/// - Product card → detail page (intake + recent purchases + seller shares +
///   channel chips + lines, the same for both tabs, D21)
/// - Manual add (product search + seller + quantity, D11)
class PurchaseListPage extends StatelessWidget {
  const PurchaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (providerContext) {
        // D71 ③: the intake notice follows the stock link setting — refreshed
        // once per visit.
        providerContext.read<PurchaseSettingBloc>().add(LoadPurchaseSetting());
        return getIt<PurchaseListBloc>()..add(LoadPurchaseList());
      },
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
            // D65: with the stock link off, no check-in writes stock — no notice.
            final stockLinked =
                context.read<PurchaseSettingBloc>().state.stockLinked == true;
            if (loaded.stockRecorded == false && stockLinked) {
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

    final tabs = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TabSwitcher(
          activeTab: state.activeTab,
          onChanged: (tab) => bloc.add(SwitchTab(tab: tab)),
        ),
        // D1 · D5 · D53: one seller filter for both tabs, right under them.
        if (state.sellers.length != 1) ...[
          const SizedBox(height: 8),
          SellerFilterDropdown(
            sellers: state.sellers,
            selectedSellerId: state.filterSellerId,
            enabled: !busy,
            onChanged: (sellerId) =>
                bloc.add(ChangeSellerFilter(sellerId: sellerId)),
          ),
        ],
      ],
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
                            sellers: state.sellers,
                            onSubmit: (productId, sellerId, quantity) =>
                                bloc.add(
                              AddManualItem(
                                productId: productId,
                                sellerId: sellerId,
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
        // FEATURE_2610_18 D46: receipt check-in popup above the list.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : () => _openReceiptSheet(context, bloc, state),
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('영수증 입고'),
          ),
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
                  separatorBuilder: (_, __) => const AppRowGap(),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return PurchaseProductCard(
                      key: ValueKey(item.productId),
                      item: item,
                      onTap: () => _openDetail(context, bloc, item.productId),
                      footer: _shareFooter(state, bloc, item, busy),
                    );
                  },
                ),
              // D67: 「오늘 넘김」 under the list, only when something was put off today.
              if (state.skippedToday.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘 넘김',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '내일 매입으로 넘긴 구성품입니다. 다음 날 구매목록에 다시 나타납니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: state.skippedToday.length,
                  separatorBuilder: (_, __) => const AppRowGap(),
                  itemBuilder: (context, index) {
                    final item = state.skippedToday[index];
                    return PurchaseProductCard(
                      key: ValueKey('skipped-${item.productId}'),
                      item: item,
                      onTap: () => _openDetail(context, bloc, item.productId),
                      footer: _shareFooter(state, bloc, item, busy),
                    );
                  },
                ),
              ],
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
      separatorBuilder: (_, __) => const AppRowGap(),
      itemBuilder: (context, index) {
        final item = items[index];
        // 완료 탭도 구매목록 탭과 **같은 카드**를 쓴다(D21) — 추가 입고·정정이 가능하다.
        return PurchaseProductCard(
          key: ValueKey(item.productId),
          item: item,
          onTap: () => _openDetail(context, bloc, item.productId),
          footer: _shareFooter(state, bloc, item, busy),
        );
      },
    );
  }
}

/// Seller view only: the share's tag and buttons under the card
/// (FEATURE_2610_09 D83). 「전체」 puts them on the detail's share rows instead.
Widget? _shareFooter(
  PurchaseListLoaded state,
  PurchaseListBloc bloc,
  PurchaseListItem item,
  bool busy,
) {
  if (state.filterSellerId == null || item.shares.isEmpty) return null;
  final share = item.shares.first;
  return Wrap(
    spacing: 6,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      TargetMetTag(share: share),
      PurchaseShareActions(
        share: share,
        busy: busy,
        onCheck: (status) => bloc.add(CheckShare(
          productId: item.productId,
          sellerId: share.sellerId,
          status: status,
        )),
        onCancel: (checkId) => bloc.add(CancelShareCheck(checkId: checkId)),
      ),
    ],
  );
}

/// Opens the receipt popup; a saved receipt shows the success toast and
/// reloads the current tab (FEATURE_2610_18 D46).
Future<void> _openReceiptSheet(
  BuildContext context,
  PurchaseListBloc bloc,
  PurchaseListLoaded state,
) async {
  final saved = await showAppSheet<bool>(
    context,
    builder: (_) => ReceiptIntakeSheet(sellers: state.sellers),
  );
  if (saved == true && context.mounted) {
    showSuccessToast(context, '영수증 입고를 저장했습니다.');
    bloc.add(ReceiptSaved());
  }
}

/// Opens the product detail on top of the list, sharing the list's bloc so
/// intake/removal there refreshes the list underneath.
void _openDetail(BuildContext context, PurchaseListBloc bloc, int productId) {
  context.push(
    Routes.purchaseProductDetailPath,
    extra: PurchaseProductDetailArgs(bloc: bloc, productId: productId),
  );
}
