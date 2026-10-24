import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_bloc.dart';
import 'package:flutter_oklyn_mobile/features/alert/presentation/bloc/alert_summary_state.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/widgets/dashboard_card_frame.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/get_purchase_list_usecase.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/usecases/settlement_usecase.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/domain/usecases/shipping_label_usecase.dart';

/// C1 ~ C4 — one number of the alert summary (FEATURE_2610_29 / D4 · D20).
///
/// 🔴 Reads [AlertSummaryBloc] — the dashboard page refreshes it on entry like
///    the pages built on `ScaffoldWithNavBar` (its `initState`). This card does
///    not call the server itself (D20).
class AlertCountCard extends StatelessWidget {
  final DashboardCardType type;
  final bool editing;
  final VoidCallback onRemove;

  const AlertCountCard({
    required this.type,
    required this.editing,
    required this.onRemove,
    super.key,
  });

  int _value(AlertSummaryState state) {
    switch (type) {
      case DashboardCardType.paidOrders:
        return state.paidOrders;
      case DashboardCardType.newOrders:
        return state.newOrders;
      case DashboardCardType.openClaims:
        return state.openClaims;
      case DashboardCardType.unansweredInquiries:
        return state.unansweredInquiries;
      case DashboardCardType.periodSales:
      case DashboardCardType.settlementPayouts:
      case DashboardCardType.purchaseList:
      case DashboardCardType.reservedShipments:
      case DashboardCardType.dailySalesChart:
      case DashboardCardType.channelSalesChart:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) => DashboardCardFrame(
        type: type,
        editing: editing,
        onRemove: onRemove,
        child: BlocBuilder<AlertSummaryBloc, AlertSummaryState>(
          builder: (context, state) =>
              DashboardCount(value: formatCount(_value(state)), unit: '건'),
        ),
      );
}

/// C6 「정산 지급」 (FEATURE_2610_29 / D26 · D30) — this month's payouts summed
/// across sellers and channels, from `GET /api/admin/settlement/month-summary`.
/// The server picks this month in KST and dates a payout by its confirmed
/// payout date, else its scheduled payout date. The three amounts are shown as
/// the server sends them: the total on top, paid (left) and remaining (right)
/// under it — the card is `tall` (1.5 rows) to fit both lines.
class PayoutCard extends StatelessWidget {
  final bool editing;
  final VoidCallback onRemove;

  const PayoutCard({required this.editing, required this.onRemove, super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => DashboardCardDataBloc<SettlementMonthSummary>(
          loader: () => getIt<SettlementUseCase>().getMonthSummary(),
        )..add(const DashboardCardDataRequested()),
        child: DashboardCardFrame(
          type: DashboardCardType.settlementPayouts,
          editing: editing,
          onRemove: onRemove,
          child: DashboardCardBody<SettlementMonthSummary>(
            builder: (context, sums) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardFigure(
                  label: '이번 달 지급 예정 총액',
                  value: '${formatMoney(sums.total)}원',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DashboardFigure(
                        label: '지금까지 지급된 금액',
                        value: '${formatMoney(sums.paid)}원',
                      ),
                    ),
                    Expanded(
                      child: DashboardFigure(
                        label: '남은 지급 예정 금액',
                        value: '${formatMoney(sums.remaining)}원',
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// C7 「구매목록 남은 품목」 (FEATURE_2610_29 / D27) — the number of products
/// still to buy: the `items` of the purchase list without a seller filter.
class PurchaseListCard extends StatelessWidget {
  final bool editing;
  final VoidCallback onRemove;

  const PurchaseListCard({
    required this.editing,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => DashboardCardDataBloc<int>(
          loader: () async => (await getIt<GetPurchaseListUseCase>()())
              .map((list) => list.items.length),
        )..add(const DashboardCardDataRequested()),
        child: DashboardCardFrame(
          type: DashboardCardType.purchaseList,
          editing: editing,
          onRemove: onRemove,
          child: DashboardCardBody<int>(
            builder: (context, count) =>
                DashboardCount(value: formatCount(count), unit: '종'),
          ),
        ),
      );
}

/// The four counts of C8 and the row results each one adds up (D29).
const List<({String label, List<String> results})> _reservedBuckets = [
  (label: '예약됨', results: ['PENDING']),
  (label: '실행완료', results: ['SUCCEEDED', 'EXTERNAL']),
  (label: '실패', results: ['FAILED']),
  (label: '중지/취소', results: ['CANCELLED', 'RELEASED']),
];

/// C8 「예약 발송」 (FEATURE_2610_29 / D27 · D29) — the rows of the reserved
/// shipment list (one row = one order box, open rows + rows finished in the
/// last 7 days), counted by result. A failure count above 0 is drawn in the
/// error colour.
class ReservedShipmentCard extends StatelessWidget {
  final bool editing;
  final VoidCallback onRemove;

  const ReservedShipmentCard({
    required this.editing,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => DashboardCardDataBloc<List<int>>(
          loader: () async => (await getIt<ShippingLabelUseCase>()
                  .getReservedShipments())
              .map((rows) => [
                    for (final bucket in _reservedBuckets)
                      rows
                          .where((row) => bucket.results.contains(row.result))
                          .length,
                  ]),
        )..add(const DashboardCardDataRequested()),
        child: DashboardCardFrame(
          type: DashboardCardType.reservedShipments,
          editing: editing,
          onRemove: onRemove,
          child: DashboardCardBody<List<int>>(
            builder: (context, counts) => Row(
              children: [
                for (var i = 0; i < _reservedBuckets.length; i++)
                  Expanded(
                    child: DashboardFigure(
                      label: _reservedBuckets[i].label,
                      value: formatCount(counts[i]),
                      color: _reservedBuckets[i].label == '실패' && counts[i] > 0
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
