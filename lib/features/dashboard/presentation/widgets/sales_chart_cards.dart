import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_grid_spec.dart';
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

/// Row shape of the channel lines (DASHBOARD_CARDS D42) — fixed, never
/// shrunk by the channel count.
const double _rowHeight = 22;
const double _foldHeight = 16;
const double _barHeight = 10;
const double _nameWidth = 96;
const TextStyle _lineStyle = TextStyle(fontSize: 12);

/// G2 「채널별 매출」 (FEATURE_2610_29 / D22) — `/api/admin/sales/by-channel`
/// as is (rows come sorted by sales). The top [MobileGrid.channelChartRows]
/// channels are drawn as name · bar (brand main) · amount lines with a fixed
/// 12px font; the rest fold into one 「외 K개」 line (DASHBOARD_CARDS D41 ·
/// D42).
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
            builder: (context, rows) => _ChannelLines(rows: rows),
          ),
        ),
      );
}

/// The top channels as lines and the rest folded into one line.
class _ChannelLines extends StatelessWidget {
  final List<ChannelSales> rows;

  const _ChannelLines({required this.rows});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (rows.isEmpty) {
      return Center(
        child: Text('이 기간 매출이 없습니다.', style: _lineStyle.copyWith(color: muted)),
      );
    }
    final shown = rows.take(MobileGrid.channelChartRows).toList();
    final hidden = rows.skip(MobileGrid.channelChartRows).toList();
    final top = shown.first.grossSales;
    final hiddenSales = hidden.fold<num>(0, (sum, row) => sum + row.grossSales);
    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in shown) _ChannelLine(row: row, top: top),
          if (hidden.isNotEmpty)
            SizedBox(
              height: _foldHeight,
              child: Text(
                '외 ${hidden.length}개 채널 · ${formatMoney(hiddenSales)}원',
                style: _lineStyle.copyWith(color: muted, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// One channel line: name · bar (sales ÷ the top channel's sales) · amount.
class _ChannelLine extends StatelessWidget {
  final ChannelSales row;
  final num top;

  const _ChannelLine({required this.row, required this.top});

  @override
  Widget build(BuildContext context) {
    final ratio = top > 0
        ? (row.grossSales < 0 ? 0 : row.grossSales / top).toDouble()
        : 0.0;
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _nameWidth,
            child: Text(
              _channelName(row),
              style: _lineStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.brandMain,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${formatMoney(row.grossSales)}원',
            style: _lineStyle
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}
