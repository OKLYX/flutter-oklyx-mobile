import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_value_row.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/seller_channel_rows.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Seller rows of 「통합 매출 조회」 + the total row (FEATURE_2610_20 / D26) — the web
/// `SellerSummaryTable`.
///
/// 🔴 「정산 추정 금액」 always carries 「기간 무관 · 미지급 잔액」 — it does not follow the
/// period.
/// 🔴 The total profit is `—` when any row has no cost basis (a partial sum
/// would read as the total).
/// ⚠️ The first load shows the spinner; a reload keeps the old rows under a
/// 「조회 중...」 line.
class SellerSalesList extends StatelessWidget {
  final List<SellerSales> rows;
  final bool loading;
  final String error;
  final int? expandedSellerId;
  final List<ChannelSales> channels;
  final bool channelsLoading;
  final String channelsError;
  final List<PayoutSummary> payouts;
  final bool payoutsLoading;
  final String payoutsError;
  final ValueChanged<int> onToggle;
  final VoidCallback onRetry;
  final ValueChanged<int> onOpenChannel;
  final ValueChanged<int> onOpenPayout;

  const SellerSalesList({
    required this.rows,
    required this.loading,
    required this.error,
    required this.expandedSellerId,
    required this.channels,
    required this.channelsLoading,
    required this.channelsError,
    required this.payouts,
    required this.payoutsLoading,
    required this.payoutsError,
    required this.onToggle,
    required this.onRetry,
    required this.onOpenChannel,
    required this.onOpenPayout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (error.isNotEmpty) {
      return AppErrorBox(
          message: error,
          action: TextButton(onPressed: onRetry, child: const Text('다시 시도')));
    }
    if (loading && rows.isEmpty) {
      return const AppLoading();
    }
    if (rows.isEmpty) {
      return const AppEmpty('해당 기간에 판매된 주문이 없습니다.');
    }
    final muted = TextStyle(
        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
    num sum(num Function(SellerSales) pick) =>
        rows.fold<num>(0, (total, row) => total + pick(row));
    final totalProfitReady = rows.every((row) => row.costBasisReady);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('조회 중...', style: muted)),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const AppRowGap(),
          _seller(rows[i]),
        ],
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('합계', style: TextStyle(fontWeight: FontWeight.w600)),
              SalesValueRow(
                  label: '판매수량',
                  value: formatCount(sum((r) => r.netQty)),
                  bold: true),
              SalesValueRow(
                  label: '매출액',
                  value: formatMoney(sum((r) => r.grossSales)),
                  bold: true),
              SalesValueRow(
                  label: '할인',
                  value: formatMoney(sum((r) => r.discount)),
                  bold: true),
              SalesValueRow(
                  label: '고정비',
                  value: formatFixedCost(sum((r) => r.fixedCost)),
                  bold: true),
              SalesValueRow(
                label: '순이익(추정)',
                value: totalProfitReady
                    ? formatMoney(sum((r) => r.estNetProfit ?? 0))
                    : '—',
                hint: totalProfitReady ? null : kProfitPendingHint,
                bold: true,
              ),
              SalesValueRow(
                label: '정산 추정 금액',
                sub: '기간 무관 · 미지급 잔액',
                value: formatMoney(sum((r) => r.pendingPayout)),
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seller(SellerSales row) {
    final expanded = expandedSellerId == row.sellerId;
    return AppCard.row(
      onTap: () => onToggle(row.sellerId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${expanded ? '▾' : '▸'} ${row.sellerName}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          SalesValueRow(
            label: '판매수량',
            value: row.holdQty > 0
                ? '${formatCount(row.netQty)} (대기 ${formatCount(row.holdQty)})'
                : formatCount(row.netQty),
            hint:
                row.holdQty > 0 ? '환불대기 수량입니다. 아직 확정이 아니라 매출에서 빼지 않았습니다' : null,
          ),
          SalesValueRow(
              label: '매출액', value: formatMoney(row.grossSales), bold: true),
          SalesValueRow(label: '할인', value: formatMoney(row.discount)),
          SalesValueRow(
              label: '고정비',
              value: formatFixedCost(row.fixedCost),
              hint: kFixedCostHintMixed),
          SalesValueRow(
            label: '순이익(추정)',
            value: formatProfit(row.estNetProfit,
                costBasisReady: row.costBasisReady),
            hint: row.costBasisReady ? null : kProfitPendingHint,
          ),
          SalesValueRow(
              label: '정산 추정 금액',
              sub: '기간 무관 · 미지급 잔액',
              value: formatMoney(row.pendingPayout)),
          if (expanded)
            SellerChannelRows(
              channels: channels,
              loading: channelsLoading,
              error: channelsError,
              payouts: payouts,
              payoutsLoading: payoutsLoading,
              payoutsError: payoutsError,
              onOpenChannel: onOpenChannel,
              onOpenPayout: onOpenPayout,
            ),
        ],
      ),
    );
  }
}
