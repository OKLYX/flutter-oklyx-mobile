import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/channel_sales_bloc.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/channel_sales_event.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/channel_sales_state.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/channel_product_list.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/channel_sale_records.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/channel_summary_card.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_period_filter.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_tab_bar.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// 「매출」 > 「채널별 매출」 (FEATURE_2610_20 / D18 · D26) — the mobile twin of the web
/// `ChannelSalesContainer`.
///
/// [from] · [to] · [accountId] = the route query from 「통합 매출 조회」 (read once at
/// entry); a bad or missing value = this month / the first channel.
class ChannelSalesPage extends StatelessWidget {
  final String? from;
  final String? to;
  final int? accountId;

  const ChannelSalesPage({super.key, this.from, this.to, this.accountId});

  static String? _date(String? value) =>
      value != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
          ? value
          : null;

  @override
  Widget build(BuildContext context) {
    final range = currentMonthRange();
    return BlocProvider(
      create: (_) => getIt<ChannelSalesBloc>(
        param1: ChannelSalesState(
          from: _date(from) ?? range.from,
          to: _date(to) ?? range.to,
          accountId: accountId,
        ),
      )..add(const ChannelSalesStarted()),
      child: const _ChannelSalesView(),
    );
  }
}

class _ChannelSalesView extends StatelessWidget {
  const _ChannelSalesView();

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '매출',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocBuilder<ChannelSalesBloc, ChannelSalesState>(
          builder: (context, state) {
            final bloc = context.read<ChannelSalesBloc>();
            if (state.forbidden) {
              return const AppPageBody(children: [AppEmpty('관리자만 볼 수 있습니다.')]);
            }
            final selected = state.selected;
            final muted = TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant);
            return AppPageBody(
              children: [
                const SalesTabBar(current: 1),
                const SizedBox(height: 12),
                SalesPeriodFilter(
                  from: state.from,
                  to: state.to,
                  disabled: state.loading,
                  onChanged: (from, to) =>
                      bloc.add(ChannelSalesPeriodChanged(from: from, to: to)),
                  extra: [
                    AppFilterChip<int?>(
                      label:
                          selected == null ? '채널 없음' : _optionLabel(selected),
                      value: state.accountId,
                      options: [
                        for (final c in state.channels)
                          AppFilterOption<int?>(c.accountId, _optionLabel(c)),
                      ],
                      onSelected: state.loading || state.channels.isEmpty
                          ? null
                          : (id) {
                              if (id != null) {
                                bloc.add(ChannelSalesChannelChanged(id));
                              }
                            },
                    ),
                  ],
                ),
                if (state.invalidRange) ...[
                  const SizedBox(height: 8),
                  const SettlementMessageBox(
                      tone: SettlementMessageTone.error,
                      message: '시작일이 종료일보다 뒤입니다.'),
                ],
                const SizedBox(height: 12),
                if (state.error.isNotEmpty)
                  AppErrorBox(
                    message: state.error,
                    action: TextButton(
                      onPressed: () => bloc.add(const ChannelSalesRetried()),
                      child: const Text('다시 시도'),
                    ),
                  )
                else if (selected == null && state.loading)
                  const AppLoading()
                else if (selected == null)
                  const AppEmpty('조회할 판매채널이 없습니다.')
                else ...[
                  ChannelSummaryCard(channel: selected),
                  if (!selected.costBasisReady) ...[
                    const SizedBox(height: 8),
                    const SettlementMessageBox(
                        tone: SettlementMessageTone.info,
                        message: kProfitPendingHint),
                  ],
                  const SizedBox(height: 16),
                  const Text('상품별 매출',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppCard(
                    child: ChannelProductList(
                      rows: state.products
                          .where((p) => p.accountId == selected.accountId)
                          .toList(),
                      loading: state.productsLoading,
                      error: state.productsError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('판매 내역',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('${formatCount(state.records.length)}건 · 판매일 최근순',
                          style: muted),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ChannelSaleRecords(
                    rows: state.records,
                    visible: state.visibleRecords,
                    loading: state.recordsLoading,
                    error: state.recordsError,
                    hideCanceled: state.hideCanceled,
                    hidePending: state.hidePending,
                    onHideCanceledChanged: (hide) =>
                        bloc.add(ChannelSalesHideCanceledChanged(hide: hide)),
                    onHidePendingChanged: (hide) =>
                        bloc.add(ChannelSalesHidePendingChanged(hide: hide)),
                  ),
                ],
              ],
            );
          },
        ),
      );

  /// 「판매자 · 채널」, or the channel only when the seller name is empty (web
  /// `optionLabel`).
  static String _optionLabel(ChannelSales channel) {
    final label =
        channelLabel(channel.platform, channel.accountAlias, channel.accountId);
    final seller = channel.sellerName?.trim() ?? '';
    return seller.isEmpty ? label : '$seller · $label';
  }
}
