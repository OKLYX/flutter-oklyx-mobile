import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_state.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_layout.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/widgets/dashboard_card_frame.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/usecases/sales_usecase.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';

/// Seller and channel rows of the period.
typedef PeriodSalesData = ({
  List<SellerSales> sellers,
  List<ChannelSales> channels,
});

/// One page of the card: a name and its two numbers (D25).
class _SalesPage {
  final String label;
  final num grossSales;

  /// null = 「아직 모른다」 (a row without cost basis) — `—`, not 0.
  final num? profit;

  const _SalesPage(this.label, this.grossSales, this.profit);
}

/// 「매출」 sum and 「예상 순이익」 sum; the profit is null as soon as one row
/// has none.
_SalesPage _sumPage(String label,
    List<({num grossSales, num? estNetProfit, bool costBasisReady})> rows) {
  final unknown =
      rows.any((row) => !row.costBasisReady || row.estNetProfit == null);
  return _SalesPage(
    label,
    rows.fold<num>(0, (sum, row) => sum + row.grossSales),
    unknown
        ? null
        : rows.fold<num>(0, (sum, row) => sum + (row.estNetProfit ?? 0)),
  );
}

/// C5 「기간 매출」 (FEATURE_2610_29 / D23 · D25 · D28) — the web
/// `PeriodSalesCard`.
///
/// Step 1 pages = 「전체」 → each seller (`/summary` order), swiped left and
/// right. On a seller page with two or more channels the title row shows
/// 「전체 | 채널」; 「채널」 switches to step 2 = that seller's channels
/// (`/by-channel` order). Changing the period goes back to the 「전체」 page.
/// The page and step are not saved.
class PeriodSalesCard extends StatefulWidget {
  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final bool editing;
  final VoidCallback onRemove;

  const PeriodSalesCard({
    required this.period,
    required this.onPeriodChanged,
    required this.editing,
    required this.onRemove,
    super.key,
  });

  @override
  State<PeriodSalesCard> createState() => _PeriodSalesCardState();
}

class _PeriodSalesCardState extends State<PeriodSalesCard> {
  int _sellerPage = 0;

  /// null = step 1; otherwise the channel page of step 2.
  int? _channelPage;

  /// Swipe position of the step on screen — replaced when the step changes.
  PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Shows step 1 at [sellerPage] (`channelPage` null) or step 2 at
  /// [channelPage].
  void _show({required int sellerPage, required int? channelPage}) {
    final previous = _controller;
    setState(() {
      _sellerPage = sellerPage;
      _channelPage = channelPage;
      _controller = PageController(initialPage: channelPage ?? sellerPage);
    });
    // The old controller is still attached until the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
        key: ValueKey(widget.period),
        create: (_) => DashboardCardDataBloc<PeriodSalesData>(
          loader: () async {
            final range = periodRange(widget.period);
            final sales = getIt<SalesUseCase>();
            final sellers =
                await sales.getSellerSummary(from: range.from, to: range.to);
            final channels =
                await sales.getChannelSales(from: range.from, to: range.to);
            return sellers.flatMap((sellerRows) => channels.map(
                (channelRows) => (sellers: sellerRows, channels: channelRows)));
          },
        )..add(const DashboardCardDataRequested()),
        child: Builder(builder: _buildCard),
      );

  Widget _buildCard(BuildContext context) => BlocBuilder<
          DashboardCardDataBloc<PeriodSalesData>,
          DashboardCardDataState<PeriodSalesData>>(
        builder: (context, state) {
          final data = state.data;
          final seller = data == null || _sellerPage == 0
              ? null
              : data.sellers[_sellerPage - 1];
          final sellerChannels = seller == null
              ? const <ChannelSales>[]
              : data!.channels
                  .where((row) => row.sellerId == seller.sellerId)
                  .toList();
          return DashboardCardFrame(
            type: DashboardCardType.periodSales,
            editing: widget.editing,
            onRemove: widget.onRemove,
            actions: [
              DashboardPeriodDropdown(
                type: DashboardCardType.periodSales,
                value: widget.period,
                onChanged: (period) {
                  _show(sellerPage: 0, channelPage: null);
                  widget.onPeriodChanged(period);
                },
              ),
              if (sellerChannels.length >= 2) _stepToggle(context),
            ],
            child: DashboardCardBody<PeriodSalesData>(
              builder: (context, loaded) =>
                  _pages(context, loaded, sellerChannels),
            ),
          );
        },
      );

  Widget _stepToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget segment(String label, {required bool selected, required int? to}) =>
        InkWell(
          onTap: () => _show(sellerPage: _sellerPage, channelPage: to),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: selected ? scheme.onSurface : scheme.surface,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? scheme.surface : scheme.onSurface,
              ),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment('전체', selected: _channelPage == null, to: null),
          segment('채널', selected: _channelPage != null, to: 0),
        ],
      ),
    );
  }

  Widget _pages(BuildContext context, PeriodSalesData data,
      List<ChannelSales> sellerChannels) {
    final firstStep = [
      _sumPage('전체', [
        for (final row in data.sellers)
          (
            grossSales: row.grossSales,
            estNetProfit: row.estNetProfit,
            costBasisReady: row.costBasisReady,
          ),
      ]),
      for (final row in data.sellers)
        _sumPage(row.sellerName, [
          (
            grossSales: row.grossSales,
            estNetProfit: row.estNetProfit,
            costBasisReady: row.costBasisReady,
          ),
        ]),
    ];
    final secondStep = [
      for (final row in sellerChannels)
        _sumPage(channelLabel(row.platform, row.accountAlias, row.accountId), [
          (
            grossSales: row.grossSales,
            estNetProfit: row.estNetProfit,
            costBasisReady: row.costBasisReady,
          ),
        ]),
    ];
    final channelStep = _channelPage != null;
    final pages = channelStep ? secondStep : firstStep;
    final index = channelStep ? _channelPage! : _sellerPage;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            physics: widget.editing
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: pages.length,
            onPageChanged: (page) => setState(() {
              if (channelStep) {
                _channelPage = page;
              } else {
                _sellerPage = page;
              }
            }),
            itemBuilder: (context, page) {
              final entry = pages[page];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardFigure(
                          label: '매출',
                          value: '${formatMoney(entry.grossSales)}원',
                        ),
                      ),
                      Expanded(
                        child: DashboardFigure(
                          label: '예상 순이익',
                          value: entry.profit == null
                              ? '—'
                              : '${formatMoney(entry.profit)}원',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var dot = 0; dot < pages.length; dot++)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dot == index ? scheme.onSurface : scheme.outline,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
