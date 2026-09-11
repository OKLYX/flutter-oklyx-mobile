import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/stock_balance.dart';
import '../bloc/stock_ledger_bloc.dart';
import '../bloc/stock_ledger_event.dart';
import '../bloc/stock_ledger_state.dart';
import '../widgets/movement_tile.dart';
import '../widgets/stock_error_retry.dart';

/// 재고 조회 페이지 (`/stock/search`, PLAN 2609_28 D14 / 2609_29 D5).
///
/// 잔량은 **(물품 × 판매자)** 행이고 서버 집계를 그대로 표시한다 — 앱에서 다시 더하지 않는다.
/// ❌ 음수를 숨기지 않는다: 음수는 입고 기록이 빠졌다는 신호다.
class StockBalancePage extends StatelessWidget {
  const StockBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StockLedgerBloc>()..add(LoadBalances()),
      child: const _StockBalanceView(),
    );
  }
}

class _StockBalanceView extends StatefulWidget {
  const _StockBalanceView();

  @override
  State<_StockBalanceView> createState() => _StockBalanceViewState();
}

class _StockBalanceViewState extends State<_StockBalanceView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String value, int? sellerId) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context
          .read<StockLedgerBloc>()
          .add(LoadBalances(keyword: value, sellerId: sellerId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return ScaffoldWithNavBar(
      title: '재고 조회',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<StockLedgerBloc, StockLedgerState>(
        listenWhen: (prev, curr) =>
            curr is StockLedgerLoaded && curr.actionError != null,
        listener: (context, state) {
          _snack(context, (state as StockLedgerLoaded).actionError!);
          context.read<StockLedgerBloc>().add(ClearStockLedgerNotice());
        },
        builder: (context, state) {
          if (state is StockLedgerInitial || state is StockLedgerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StockLedgerError) {
            return StockErrorRetry(
              message: state.message,
              onRetry: () =>
                  context.read<StockLedgerBloc>().add(LoadBalances()),
            );
          }
          final loaded = state as StockLedgerLoaded;
          final bloc = context.read<StockLedgerBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '상품명 검색',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          _onSearchChanged(context, value, loaded.sellerId),
                    ),
                    const SizedBox(height: 8),
                    SellerFilterDropdown(
                      sellers: loaded.sellers,
                      selectedSellerId: loaded.sellerId,
                      onChanged: (value) => bloc.add(LoadBalances(
                        keyword: _searchController.text,
                        sellerId: value,
                      )),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: loaded.balances.isEmpty
                    ? Center(
                        child: Text(
                          '재고 데이터가 없습니다.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding:
                            EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
                        itemCount: loaded.balances.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) => _BalanceRow(
                          balance: loaded.balances[index],
                          onTap: () => _showHistory(context, bloc,
                              loaded.balances[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 행 탭 → 그 물품의 이력 시트. 판매자 필터는 그 행의 판매자로 좁힌다.
  void _showHistory(
    BuildContext context,
    StockLedgerBloc bloc,
    StockBalance balance,
  ) {
    bloc.add(LoadMovements(
      productId: balance.productId,
      sellerId: balance.sellerId,
    ));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _HistorySheet(balance: balance),
      ),
    );
  }

  /// 하단 내비가 오버레이라 floating + bottom:70 이 필수다.
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

/// 잔량 1행 — 음수는 빨강으로 드러낸다.
class _BalanceRow extends StatelessWidget {
  final StockBalance balance;
  final VoidCallback onTap;

  const _BalanceRow({required this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final negative = balance.onHand < 0;
    return ListTile(
      dense: true,
      title: Text(
        balance.productName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        balance.sellerName,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${balance.onHand}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: negative
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (negative)
            Text(
              '입고 기록이 빠졌을 수 있습니다',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 물품 이력 시트.
class _HistorySheet extends StatelessWidget {
  final StockBalance balance;

  const _HistorySheet({required this.balance});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return BlocBuilder<StockLedgerBloc, StockLedgerState>(
          builder: (context, state) {
            final loaded = state is StockLedgerLoaded ? state : null;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${balance.productName} · ${balance.sellerName}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (loaded?.isLoadingMovements ?? true)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (loaded!.movements.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        '이력이 없습니다.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: loaded.movements
                          .map((m) => MovementTile(movement: m))
                          .toList(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
