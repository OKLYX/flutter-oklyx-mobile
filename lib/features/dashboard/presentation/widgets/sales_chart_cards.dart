import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_layout.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/widgets/dashboard_card_frame.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/usecases/sales_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// `yyyy-MM-dd` → `M/D`.
String _dayLabel(String date) {
  final parts = date.split('-');
  return parts.length == 3
      ? '${int.parse(parts[1])}/${int.parse(parts[2])}'
      : date;
}

/// Sales total of the period.
num _total(List<DailySales> rows) =>
    rows.fold<num>(0, (sum, row) => sum + row.grossSales);

/// Tooltip text style of both charts.
TextStyle _tooltipStyle(BuildContext context) => TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onInverseSurface,
    );

/// G1 「날짜별 매출 · 주문 수」 (FEATURE_2610_29 / D13 · D22) — a sales bar
/// (brand main) and an order-count line (brand teal) per sale date, and the
/// period total above the chart. A tap on a bar shows the date's numbers.
///
/// The line is drawn over the bar chart with the same x positions (bar
/// centers = −0.5 ~ n − 0.5 of the line chart).
///
/// The seller selector (FEATURE_2610_30 / D34 · D36 · D37) narrows the chart
/// and the total to one seller; it starts at 「전체」, is not saved, and stays
/// when the period changes.
class DailySalesChartCard extends StatelessWidget {
  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  /// Seller list of the dashboard and the picked seller (null = 「전체」).
  final List<Seller> sellers;
  final int? sellerId;
  final ValueChanged<int?> onSellerChanged;
  final bool editing;
  final VoidCallback onRemove;

  const DailySalesChartCard({
    required this.period,
    required this.onPeriodChanged,
    required this.sellers,
    required this.sellerId,
    required this.onSellerChanged,
    required this.editing,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
        key: ValueKey((period, sellerId)),
        create: (_) => DashboardCardDataBloc<List<DailySales>>(
          loader: () {
            final range = periodRange(period);
            return getIt<SalesUseCase>().getDailySales(
                from: range.from, to: range.to, sellerId: sellerId);
          },
        )..add(const DashboardCardDataRequested()),
        child: DashboardCardFrame(
          type: DashboardCardType.dailySalesChart,
          editing: editing,
          onRemove: onRemove,
          actions: [
            DashboardSellerDropdown(
              sellers: sellers,
              value: sellerId,
              onChanged: onSellerChanged,
            ),
            DashboardPeriodDropdown(
              type: DashboardCardType.dailySalesChart,
              value: period,
              onChanged: onPeriodChanged,
            ),
          ],
          child: DashboardCardBody<List<DailySales>>(
            builder: (context, rows) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '합계 ${formatMoney(_total(rows))}원',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Expanded(child: _chart(context, rows)),
              ],
            ),
          ),
        ),
      );

  Widget _chart(BuildContext context, List<DailySales> rows) => Stack(
        children: [
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: [
                for (var i = 0; i < rows.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rows[i].grossSales.toDouble(),
                        color: AppColors.brandMain,
                      ),
                    ],
                  ),
              ],
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    '${_dayLabel(rows[groupIndex].date)}\n'
                    '매출 ${formatMoney(rows[groupIndex].grossSales)}원\n'
                    '주문 수 ${formatCount(rows[groupIndex].orderCount)}건',
                    _tooltipStyle(context),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: LineChart(
              LineChartData(
                minX: -0.5,
                maxX: rows.length - 0.5,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < rows.length; i++)
                        FlSpot(i.toDouble(), rows[i].orderCount.toDouble()),
                    ],
                    color: AppColors.brandTeal,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

/// 「쿠팡 · 메인」 name of a channel row.
String _channelName(ChannelSales row) =>
    channelLabel(row.platform, row.accountAlias, row.accountId);

/// G2 「채널별 매출」 (FEATURE_2610_29 / D22) — one sales bar (brand main) per
/// channel, `/api/admin/sales/by-channel` as is. A tap on a bar shows the
/// channel and its sales.
///
/// The seller selector (FEATURE_2610_30 / D35 · D36 · D37) narrows the bars
/// to that seller's channels; it starts at 「전체」, is not saved, and stays
/// when the period changes.
class ChannelSalesChartCard extends StatelessWidget {
  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  /// Seller list of the dashboard and the picked seller (null = 「전체」).
  final List<Seller> sellers;
  final int? sellerId;
  final ValueChanged<int?> onSellerChanged;
  final bool editing;
  final VoidCallback onRemove;

  const ChannelSalesChartCard({
    required this.period,
    required this.onPeriodChanged,
    required this.sellers,
    required this.sellerId,
    required this.onSellerChanged,
    required this.editing,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
        key: ValueKey((period, sellerId)),
        create: (_) => DashboardCardDataBloc<List<ChannelSales>>(
          loader: () {
            final range = periodRange(period);
            return getIt<SalesUseCase>().getChannelSales(
                from: range.from, to: range.to, sellerId: sellerId);
          },
        )..add(const DashboardCardDataRequested()),
        child: DashboardCardFrame(
          type: DashboardCardType.channelSalesChart,
          editing: editing,
          onRemove: onRemove,
          actions: [
            DashboardSellerDropdown(
              sellers: sellers,
              value: sellerId,
              onChanged: onSellerChanged,
            ),
            DashboardPeriodDropdown(
              type: DashboardCardType.channelSalesChart,
              value: period,
              onChanged: onPeriodChanged,
            ),
          ],
          child: DashboardCardBody<List<ChannelSales>>(
            builder: (context, rows) => BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: [
                  for (var i = 0; i < rows.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rows[i].grossSales.toDouble(),
                          color: AppColors.brandMain,
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${_channelName(rows[groupIndex])}\n'
                      '매출 ${formatMoney(rows[groupIndex].grossSales)}원',
                      _tooltipStyle(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
