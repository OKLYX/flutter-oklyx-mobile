import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/purchase_list_bloc.dart';
import '../bloc/purchase_list_event.dart';
import '../bloc/purchase_list_state.dart';
import '../widgets/purchase_product_card.dart';
import '../widgets/seller_filter_dropdown.dart';

/// 구매목록 페이지 (하단 탭 3번째, `/list-to-shop`).
///
/// **용도**: 프론트 구매목록(dashboard/purchase/list)을 모바일로 이식.
/// **기능(핵심)**:
/// - 판매자 필터 드롭다운 (기존 seller 기능 재사용) — 선택 시 즉시 재조회
/// - 재적재: POST /api/admin/purchase-list/extract
/// - 상품 카드 펼침 → 라인별 구매기록 + 수동수량 교체 (인라인 폼, 웹과 동일)
/// 미구현(2단계): 수동항목 추가 / 미매핑주문 / 완료내역 탭 / 주문동기화.
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
        // 조회/재적재/액션 중 발생한 일시적 오류는 SnackBar로 표시한다.
        listenWhen: (prev, curr) =>
            curr is PurchaseListLoaded && curr.actionError != null,
        listener: (context, state) {
          final message = (state as PurchaseListLoaded).actionError;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message ?? '요청에 실패했습니다.'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
              ),
            );
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
}

class _LoadedBody extends StatelessWidget {
  final PurchaseListLoaded state;

  const _LoadedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PurchaseListBloc>();
    final busy = state.isRefreshing || state.isExtracting;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 판매자 필터 + 재적재 컨트롤
          Row(
            children: [
              Expanded(
                child: SellerFilterDropdown(
                  sellers: state.sellers,
                  selectedSellerId: state.selectedSellerId,
                  enabled: !busy,
                  onChanged: (value) =>
                      bloc.add(SelectSeller(sellerId: value)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: busy ? null : () => bloc.add(ExtractPurchaseList()),
                child: Text(state.isExtracting ? '재적재 중...' : '재적재'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${state.items.length}건',
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
          Expanded(
            child: state.items.isEmpty
                ? const Center(child: Text('구매할 항목이 없습니다.'))
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight + 24,
                    ),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return PurchaseProductCard(
                        item: item,
                        expanded: item.productId == state.expandedProductId,
                        busy: busy,
                        onToggle: () =>
                            bloc.add(ToggleExpand(productId: item.productId)),
                        onRecordPurchase: (itemId, purchasedOn, quantity) =>
                            bloc.add(RecordPurchase(
                          itemId: itemId,
                          purchasedOn: purchasedOn,
                          quantity: quantity,
                        )),
                        onAdjustManual: (itemId, manualQty) => bloc.add(
                          AdjustManualQty(itemId: itemId, manualQty: manualQty),
                        ),
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
