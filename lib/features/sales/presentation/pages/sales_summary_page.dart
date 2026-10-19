import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/sales_summary_bloc.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/sales_summary_event.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/sales_summary_state.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/box_savings_list.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/packing_savings_card.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_period_filter.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_tab_bar.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/seller_sales_list.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// 「매출」 > 「통합 매출 조회」 (FEATURE_2610_20 / D18 · D26) — the mobile twin of the web
/// `SalesSummaryContainer`.
///
/// Seller rows (tap = channels + payouts of the period), then 「포장 절약」 and
/// 「상자별 절약」.
/// 🔴 The fixed-cost note keeps 「상품별 순이익에는 포함되지 않습니다.」 — it explains why the
/// product tab total differs from the channel totals.
class SalesSummaryPage extends StatelessWidget {
  const SalesSummaryPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            getIt<SalesSummaryBloc>()..add(const SalesSummaryStarted()),
        child: const _SalesSummaryView(),
      );
}

class _SalesSummaryView extends StatelessWidget {
  const _SalesSummaryView();

  static const String _shortPeriodNote =
      ' 기간이 한 달보다 짧아도 그 달 고정비 전액이 빠집니다(일할 계산 없음).';

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '매출',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocBuilder<SalesSummaryBloc, SalesSummaryState>(
          builder: (context, state) {
            final bloc = context.read<SalesSummaryBloc>();
            if (state.forbidden) {
              return const AppPageBody(children: [AppEmpty('관리자만 볼 수 있습니다.')]);
            }
            final showFixedCost = state.rows.any((row) => row.fixedCost > 0);
            final shortPeriod = isShorterThanMonth(state.from, state.to);
            return AppPageBody(
              children: [
                const SalesTabBar(current: 0),
                const SizedBox(height: 12),
                SalesPeriodFilter(
                  from: state.from,
                  to: state.to,
                  disabled: state.loading,
                  onChanged: (from, to) =>
                      bloc.add(SalesSummaryPeriodChanged(from: from, to: to)),
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
                if (showFixedCost) ...[
                  const SizedBox(height: 8),
                  Text(
                    '채널 고정비는 순이익에서 이미 빠져 있습니다. 그 달 매출이 기준 미만이면 부과되지 않습니다. '
                    '상품별 순이익에는 포함되지 않습니다.'
                    '${shortPeriod ? _shortPeriodNote : ''}',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 12),
                SellerSalesList(
                  rows: state.rows,
                  loading: state.loading,
                  error: state.error,
                  expandedSellerId: state.expandedSellerId,
                  channels: state.channels,
                  channelsLoading: state.channelsLoading,
                  channelsError: state.channelsError,
                  payouts: state.payouts,
                  payoutsLoading: state.payoutsLoading,
                  payoutsError: state.payoutsError,
                  onToggle: (sellerId) =>
                      bloc.add(SalesSellerToggled(sellerId)),
                  onRetry: () => bloc.add(const SalesSummaryRetried()),
                  onOpenChannel: (accountId) => context.goNamed(
                    Routes.salesByChannel,
                    queryParameters: {
                      'from': state.from,
                      'to': state.to,
                      'accountId': '$accountId'
                    },
                  ),
                  onOpenPayout: (payoutId) => context.goNamed(
                    Routes.settlementPayoutDetail,
                    pathParameters: {'id': '$payoutId'},
                  ),
                ),
                const SizedBox(height: 16),
                PackingSavingsCard(
                    summary: state.savings,
                    loading: state.savingsLoading,
                    error: state.savingsError),
                const SizedBox(height: 16),
                const Text('상자별 절약 · 포장한 날 기준 · 합계 높은 순',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                BoxSavingsList(
                    rows: state.boxSavings,
                    loading: state.savingsLoading,
                    error: state.savingsError),
              ],
            );
          },
        ),
      );
}
