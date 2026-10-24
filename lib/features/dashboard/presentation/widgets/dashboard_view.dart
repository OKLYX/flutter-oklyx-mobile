import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_grid_spec.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_layout.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/widgets/dashboard_number_cards.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/widgets/period_sales_card.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/widgets/sales_chart_cards.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// Dashboard body (FEATURE_2610_29 / D1 · D2 · D3 · D16 · D24) — the web
/// `DashboardHome`.
///
/// - Cards fill the 2-column grid of `MobileGrid` in order, a card is one
///   row high.
/// - [편집] turns on edit mode: hold a card and drop it on another card to
///   take its place, drag the corner handle sideways to make it 1 or 2 cells
///   wide (not under its minimum), ✕ removes it, [카드 넣기] adds one at the
///   end. [편집 완료] saves to the server; until then nothing is saved.
/// - Outside edit mode a tap on a card opens its screen; a period change is
///   saved at once.
///
/// ⚠️ Flutter's own drag widgets — no grid or reorder package (D24).
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DashboardBloc, DashboardState>(
        listenWhen: (previous, current) =>
            previous.saveVersion != current.saveVersion,
        listener: (context, state) {
          if (state.saveResult == DashboardSaveResult.failed) {
            showErrorToast(context, state.saveMessage);
          } else if (state.saveResult == DashboardSaveResult.saved) {
            showSuccessToast(context, '대시보드를 저장했습니다.');
          }
        },
        builder: (context, state) => SingleChildScrollView(
          padding: AppPageBody.insets(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.status == DashboardStatus.ready)
                _toolbar(context, state),
              if (state.status == DashboardStatus.loading) const AppLoading(),
              if (state.status == DashboardStatus.error)
                AppErrorBox(
                  message: '대시보드를 불러오지 못했습니다.',
                  action: FilledButton(
                    onPressed: () => context
                        .read<DashboardBloc>()
                        .add(const DashboardStarted()),
                    child: const Text('다시 시도'),
                  ),
                ),
              if (state.status == DashboardStatus.ready && state.cards.isEmpty)
                const AppEmpty('보일 카드가 없습니다. [편집]에서 카드를 넣으세요.'),
              if (state.status == DashboardStatus.ready)
                _DashboardGrid(
                  cards: state.cards,
                  editing: state.editing,
                  sellers: state.sellers,
                  chartSellers: state.chartSellers,
                ),
            ],
          ),
        ),
      );

  Widget _toolbar(BuildContext context, DashboardState state) {
    final bloc = context.read<DashboardBloc>();
    if (!state.editing) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => bloc.add(const DashboardEditStarted()),
          child: const Text('편집'),
        ),
      );
    }
    final addable = visibleTypes(admin: state.admin)
        .where((type) => !state.cards.any((card) => card.type == type))
        .toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: addable.isEmpty || state.saving
              ? null
              : () => _pick(context, addable),
          child: Text(addable.isEmpty ? '넣을 카드가 없습니다' : '카드 넣기'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: state.saving
              ? null
              : () => bloc.add(const DashboardEditFinished()),
          child:
              state.saving ? const AppBusyLabel('편집 완료') : const Text('편집 완료'),
        ),
      ],
    );
  }

  Future<void> _pick(
      BuildContext context, List<DashboardCardType> addable) async {
    final bloc = context.read<DashboardBloc>();
    final picked = await showAppSheet<DashboardCardType>(
      context,
      builder: (sheetContext) => ListView(
        children: [
          const ListTile(title: Text('카드 넣기')),
          for (final type in addable)
            ListTile(
              title: Text(specOf(type).title),
              onTap: () => Navigator.of(sheetContext).pop(type),
            ),
        ],
      ),
    );
    if (picked != null) {
      bloc.add(DashboardCardAdded(picked));
    }
  }
}

/// The grid: rows of [MobileGrid.columns] cells (`toRows`), one card row
/// high.
class _DashboardGrid extends StatelessWidget {
  final List<MobileCard> cards;
  final bool editing;
  final List<Seller> sellers;
  final Map<DashboardCardType, int> chartSellers;

  const _DashboardGrid({
    required this.cards,
    required this.editing,
    required this.sellers,
    required this.chartSellers,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final cell = (constraints.maxWidth -
                  MobileGrid.gap * (MobileGrid.columns - 1)) /
              MobileGrid.columns;
          final rows = toRows(cards);
          return Column(
            children: [
              for (var r = 0; r < rows.length; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : MobileGrid.gap),
                  child: Row(
                    children: [
                      for (var c = 0; c < rows[r].length; c++) ...[
                        if (c > 0) const SizedBox(width: MobileGrid.gap),
                        SizedBox(
                          width: _cardWidth(rows[r][c], cell),
                          height: cardHeight(rows[r][c].type),
                          child: _DashboardCell(
                            card: rows[r][c],
                            editing: editing,
                            cell: cell,
                            sellers: sellers,
                            sellerId: chartSellers[rows[r][c].type],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      );
}

/// Width in px of a card `card.width` cells wide.
double _cardWidth(MobileCard card, double cell) =>
    card.width * cell + (card.width - 1) * MobileGrid.gap;

/// One card on the grid; in edit mode a drag source, a drop target and a
/// corner handle.
class _DashboardCell extends StatelessWidget {
  final MobileCard card;
  final bool editing;
  final double cell;

  /// Seller list and this card's picked seller — the chart cards read them
  /// (FEATURE_2610_30 / D34 · D35).
  final List<Seller> sellers;
  final int? sellerId;

  const _DashboardCell({
    required this.card,
    required this.editing,
    required this.cell,
    required this.sellers,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final body = _cardFor(context);
    if (!editing) {
      return body;
    }
    final bloc = context.read<DashboardBloc>();
    final width = _cardWidth(card, cell);
    return DragTarget<DashboardCardType>(
      onWillAcceptWithDetails: (details) => details.data != card.type,
      onAcceptWithDetails: (details) => bloc
          .add(DashboardCardMoved(dragged: details.data, target: card.type)),
      builder: (context, candidates, rejected) =>
          LongPressDraggable<DashboardCardType>(
        data: card.type,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: width,
            height: cardHeight(card.type),
            child: Center(child: Text(specOf(card.type).title)),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: body),
        child: Stack(
          children: [
            Positioned.fill(
              child: candidates.isEmpty
                  ? body
                  : Opacity(opacity: 0.6, child: body),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: _ResizeHandle(
                cell: cell,
                onResize: (direction) {
                  final next = card.width + direction;
                  bloc.add(DashboardCardResized(type: card.type, width: next));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardFor(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    void remove() => bloc.add(DashboardCardRemoved(card.type));
    void changePeriod(DashboardPeriod period) =>
        bloc.add(DashboardPeriodChanged(type: card.type, period: period));
    void changeSeller(int? sellerId) => bloc
        .add(DashboardChartSellerChanged(type: card.type, sellerId: sellerId));
    final period = card.period ?? specOf(card.type).defaultPeriod;
    switch (card.type) {
      case DashboardCardType.paidOrders:
      case DashboardCardType.newOrders:
      case DashboardCardType.openClaims:
      case DashboardCardType.unansweredInquiries:
        return AlertCountCard(
            type: card.type, editing: editing, onRemove: remove);
      case DashboardCardType.periodSales:
        return PeriodSalesCard(
          period: period ?? DashboardPeriod.thisMonth,
          onPeriodChanged: changePeriod,
          editing: editing,
          onRemove: remove,
        );
      case DashboardCardType.settlementPayouts:
        return PayoutCard(editing: editing, onRemove: remove);
      case DashboardCardType.purchaseList:
        return PurchaseListCard(editing: editing, onRemove: remove);
      case DashboardCardType.reservedShipments:
        return ReservedShipmentCard(editing: editing, onRemove: remove);
      case DashboardCardType.dailySalesChart:
        return DailySalesChartCard(
          period: period ?? DashboardPeriod.days7,
          onPeriodChanged: changePeriod,
          sellers: sellers,
          sellerId: sellerId,
          onSellerChanged: changeSeller,
          editing: editing,
          onRemove: remove,
        );
      case DashboardCardType.channelSalesChart:
        return ChannelSalesChartCard(
          period: period ?? DashboardPeriod.days7,
          onPeriodChanged: changePeriod,
          sellers: sellers,
          sellerId: sellerId,
          onSellerChanged: changeSeller,
          editing: editing,
          onRemove: remove,
        );
    }
  }
}

/// Corner handle of a card in edit mode — a sideways drag of more than half a
/// cell asks for one cell wider (right) or narrower (left) (D16).
class _ResizeHandle extends StatefulWidget {
  final double cell;
  final ValueChanged<int> onResize;

  const _ResizeHandle({required this.cell, required this.onResize});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onHorizontalDragStart: (_) => _dx = 0,
        onHorizontalDragUpdate: (details) => _dx += details.delta.dx,
        onHorizontalDragEnd: (_) {
          if (_dx > widget.cell / 2) {
            widget.onResize(1);
          } else if (_dx < -widget.cell / 2) {
            widget.onResize(-1);
          }
          _dx = 0;
        },
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.open_in_full,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
