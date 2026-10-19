import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Nine numbers of the chosen channel (FEATURE_2610_20 / D26) — the web
/// `ChannelSummaryCard`, two per row. A cell hint (web `title`) shows on long
/// press.
class ChannelSummaryCard extends StatelessWidget {
  final ChannelSales channel;

  const ChannelSummaryCard({required this.channel, super.key});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
    final cells = <({String label, String value, String? hint})>[
      (label: '판매수량', value: formatCount(channel.netQty), hint: null),
      (label: '매출액', value: formatMoney(channel.grossSales), hint: null),
      (label: '할인', value: formatMoney(channel.discount), hint: null),
      (label: '수수료(추정)', value: formatMoney(channel.estFee), hint: null),
      (
        label: '고정비',
        value: formatFixedCost(channel.fixedCost),
        hint: fixedCostHintFor(channel.platform)
      ),
      (
        label: '순이익(추정)',
        value: formatProfit(channel.estNetProfit,
            costBasisReady: channel.costBasisReady),
        hint: channel.costBasisReady ? null : kProfitPendingHint,
      ),
      (
        label: '취소수량',
        value: formatCount(channel.cancelQty),
        hint: '취소가 확정된 수량입니다. 매출액에서는 이미 빠져 있습니다'
      ),
      (
        label: '환불완료 금액',
        value: formatMoney(channel.refundedAmount),
        hint: '취소 확정으로 매출에서 빠진 금액입니다'
      ),
      (
        label: '환불대기 금액',
        value: formatMoney(channel.pendingRefundAmount),
        hint: '아직 매출에 남아 있지만, 취소가 확정되면 빠질 금액입니다',
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            children: [
              for (final cell in cells)
                Tooltip(
                  message: cell.hint ?? cell.label,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cell.label, style: muted),
                      Text(cell.value,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          if (channel.holdQty > 0)
            Text(
                '환불대기 ${formatCount(channel.holdQty)}개는 아직 확정이 아니라 매출액에 남아 '
                '있습니다.',
                style: muted),
        ],
      ),
    );
  }
}
