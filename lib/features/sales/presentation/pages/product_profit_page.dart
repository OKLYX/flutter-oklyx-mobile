import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/product_profit_bloc.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/product_profit_event.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/product_profit_state.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/product_profit_list.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_period_filter.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_tab_bar.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// 「매출」 > 「상품별 매출」 (FEATURE_2610_20 / D18 · D26) — the mobile twin of the web
/// `ProductProfitContainer`.
///
/// Chips: period · seller · 「보기 방식」 (「채널 합쳐 보기」 / 「채널별로 보기」) · 「정렬」 (「판매수량」 ·
/// 「매출액」 · 「순이익(추정)」; the same key again flips ▼/▲). Before the cost basis is
/// ready a profit sort sorts by sales (label kept).
class ProductProfitPage extends StatelessWidget {
  const ProductProfitPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            getIt<ProductProfitBloc>()..add(const ProductProfitStarted()),
        child: const _ProductProfitView(),
      );
}

class _ProductProfitView extends StatelessWidget {
  const _ProductProfitView();

  static const Map<ProductProfitSortKey, String> _sortLabels = {
    ProductProfitSortKey.netQty: '판매수량',
    ProductProfitSortKey.grossSales: '매출액',
    ProductProfitSortKey.estNetProfit: '순이익(추정)',
  };

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '매출',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocBuilder<ProductProfitBloc, ProductProfitState>(
          builder: (context, state) {
            final bloc = context.read<ProductProfitBloc>();
            if (state.forbidden) {
              return const AppPageBody(children: [AppEmpty('관리자만 볼 수 있습니다.')]);
            }
            final seller =
                state.sellers.where((s) => s.id == state.sellerId).firstOrNull;
            final savingsByMaster = state.savingsByMaster;
            final muted = TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant);
            return AppPageBody(
              children: [
                const SalesTabBar(current: 2),
                const SizedBox(height: 12),
                SalesPeriodFilter(
                  from: state.from,
                  to: state.to,
                  disabled: state.loading,
                  onChanged: (from, to) =>
                      bloc.add(ProductProfitPeriodChanged(from: from, to: to)),
                  extra: [
                    AppFilterChip<int?>(
                      label: seller == null ? '판매자' : seller.sellerName,
                      value: state.sellerId,
                      options: [
                        const AppFilterOption<int?>(null, '전체'),
                        for (final s in state.sellers)
                          AppFilterOption<int?>(s.id, s.sellerName),
                      ],
                      highlighted: state.sellerId != null,
                      onSelected: state.loading
                          ? null
                          : (id) => bloc.add(ProductProfitSellerChanged(id)),
                    ),
                    AppFilterChip<bool>(
                      label: state.crossChannel ? '채널 합쳐 보기' : '채널별로 보기',
                      value: state.crossChannel,
                      options: const [
                        AppFilterOption(true, '채널 합쳐 보기'),
                        AppFilterOption(false, '채널별로 보기'),
                      ],
                      highlighted: !state.crossChannel,
                      onSelected: state.loading
                          ? null
                          : (cross) => bloc.add(
                              ProductProfitCrossChannelChanged(
                                  crossChannel: cross)),
                    ),
                    AppFilterChip<ProductProfitSortKey>(
                      label: '정렬 ${_sortLabels[state.sortKey]} '
                          '${state.sortDescending ? '▼' : '▲'}',
                      value: state.sortKey,
                      options: [
                        for (final entry in _sortLabels.entries)
                          AppFilterOption(entry.key, entry.value),
                      ],
                      onSelected: (key) =>
                          bloc.add(ProductProfitSortChanged(key)),
                    ),
                  ],
                ),
                if (state.invalidRange) ...[
                  const SizedBox(height: 8),
                  const SettlementMessageBox(
                      tone: SettlementMessageTone.error,
                      message: '시작일이 종료일보다 뒤입니다.'),
                ],
                if (state.rows.any((row) => !row.costBasisReady)) ...[
                  const SizedBox(height: 8),
                  const SettlementMessageBox(
                      tone: SettlementMessageTone.info,
                      message: kProfitPendingHint),
                ],
                if (!state.crossChannel) ...[
                  const SizedBox(height: 8),
                  Text(kSavingsChannelNotice, style: muted),
                ] else if (savingsByMaster.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('포장 절약은 $kSavingsBasisNotice', style: muted),
                ],
                const SizedBox(height: 12),
                ProductProfitList(
                  rows: state.sortedRows,
                  showChannel: !state.crossChannel,
                  savingsByMaster: savingsByMaster,
                  expandedSavingsMasterId: state.expandedSavingsMasterId,
                  onToggleSavings: (id) =>
                      bloc.add(ProductProfitSavingsToggled(id)),
                  loading: state.loading,
                  error: state.error,
                  onRetry: () => bloc.add(const ProductProfitRetried()),
                ),
              ],
            );
          },
        ),
      );
}
