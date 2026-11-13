import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/stock_amount_summary.dart';
import '../../domain/entities/stock_balance.dart';
import '../bloc/stock_ledger_bloc.dart';
import '../bloc/stock_ledger_event.dart';
import '../bloc/stock_ledger_state.dart';
import '../widgets/movement_tile.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';

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
            return const AppPageBody(children: [AppLoading()]);
          }
          if (state is StockLedgerError) {
            return AppPageBody(
              children: [
                AppErrorBox(
                  message: state.message,
                  action: FilledButton(
                    onPressed: () =>
                        context.read<StockLedgerBloc>().add(LoadBalances()),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            );
          }
          final loaded = state as StockLedgerLoaded;
          final bloc = context.read<StockLedgerBloc>();
          // FEATURE_2611_02 D35 · D37: a lit 「미기입 N줄」 shows only that
          // line's rows without an amount.
          final filterKey = loaded.amountFilterKey;
          final rows = filterKey == null
              ? loaded.balances
              : loaded.balances
                  .where((b) =>
                      b.amount == null &&
                      StockAmountLine.contains(filterKey, b))
                  .toList();

          return AppPageBody.slivers(
            slivers: [
              SliverToBoxAdapter(
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSearchField(
                          controller: _searchController,
                          hintText: '상품명 검색',
                          onChanged: (value) =>
                              _onSearchChanged(context, value, loaded.sellerId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppFilterChip<int?>(
                        label: loaded.sellers
                                .where((s) => s.id == loaded.sellerId)
                                .firstOrNull
                                ?.sellerName ??
                            '판매자',
                        value: loaded.sellerId,
                        options: [
                          const AppFilterOption(null, '전체'),
                          for (final s in loaded.sellers)
                            AppFilterOption(s.id, s.sellerName),
                        ],
                        highlighted: loaded.sellerId != null,
                        onSelected: (value) => bloc.add(LoadBalances(
                          keyword: _searchController.text,
                          sellerId: value,
                        )),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (loaded.balances.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _AmountSummary(
                    lines: StockAmountLine.of(loaded.balances),
                    activeKey: filterKey,
                    onToggle: (key) => bloc.add(ToggleStockAmountFilter(key)),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
              if (rows.isEmpty)
                const SliverToBoxAdapter(child: AppEmpty('재고 데이터가 없습니다.'))
              else
                SliverList.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const AppRowGap(),
                  itemBuilder: (context, index) => _BalanceRow(
                    balance: rows[index],
                    onTap: () => _showHistory(context, bloc, rows[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Row tap → that product's history sheet, narrowed to the row's seller.
  /// The 「판매자 미정」 row (sellerId 0 from the model) is not narrowed — it
  /// shows every seller's rows, as on the web (FEATURE_2610_19 R14).
  void _showHistory(
    BuildContext context,
    StockLedgerBloc bloc,
    StockBalance balance,
  ) {
    bloc.add(LoadMovements(
      productId: balance.productId,
      sellerId: balance.sellerId == 0 ? null : balance.sellerId,
    ));
    showAppSheet<void>(
      context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _HistorySheet(balance: balance),
      ),
    );
  }

  /// Only action errors pass through here — kind = error
  /// (FEATURE_2610_02 · N13).
  void _snack(BuildContext context, String message) {
    showErrorToast(context, message);
  }
}

/// FEATURE_2611_02 D29: the 「일별 입출고 내역」 amount text — 「₩#,##0」,
/// null = 「미기입」.
String _wonOrUnknown(double? amount) => amount == null
    ? '미기입'
    : '₩${NumberFormat('#,##0', 'ko_KR').format(amount)}';

/// The amount box above the list (FEATURE_2611_02 D26 · D34 ~ D38):
/// 「전체」 and one line per seller (「판매자 미정」 last) with the total of
/// the rows received. 「미기입 N줄」 = that line's rows left out of its
/// total; a tap shows only those rows, a second tap turns it off. The
/// totals stay as received while the list is filtered (D35).
class _AmountSummary extends StatelessWidget {
  final List<StockAmountLine> lines;
  final String? activeKey;
  final ValueChanged<String> onToggle;

  const _AmountSummary({
    required this.lines,
    required this.activeKey,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.label,
                        style: TextStyle(
                          fontWeight: line.key == StockAmountLine.allKey
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (line.unknownCount > 0) ...[
                      FilterChip(
                        label: Text('미기입 ${line.unknownCount}줄'),
                        selected: activeKey == line.key,
                        onSelected: (_) => onToggle(line.key),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _wonOrUnknown(line.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// 잔량 1행 — 음수는 빨강으로 드러낸다.
class _BalanceRow extends StatelessWidget {
  final StockBalance balance;
  final VoidCallback onTap;

  const _BalanceRow({required this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final negative = balance.onHand < 0;
    return AppCard.row(
      onTap: onTap,
      child: ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ProductThumbnail(productId: balance.productId, size: 40),
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
          Text(
            _wonOrUnknown(balance.amount),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}

/// 물품 이력 시트.
class _HistorySheet extends StatelessWidget {
  final StockBalance balance;

  const _HistorySheet({required this.balance});

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: loaded.movements
                          .map((m) => MovementTile(
                                movement: m,
                                truncateNames: false,
                              ))
                          .toList(),
                    ),
                  ),
              ],
            );
          },
        );
  }
}
