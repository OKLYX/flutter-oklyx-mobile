import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/channel_payout_list.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_value_row.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';

/// The channels of an open seller (FEATURE_2610_20 / D26) — the web
/// `SellerChannelRows`.
///
/// - Tapping a channel's title opens 「채널별 매출」 with the same period and that
///   channel.
/// - [정산 내역 →] opens the latest payout of the channel; it is not drawn while
///   loading or without payouts.
/// - Under each channel the payouts of the period's sales, grouped by
///   recognition month.
/// 🔴 The fixed cost is a normal cost — never the warning color; it is a number
/// even when the profit is `—`.
class SellerChannelRows extends StatelessWidget {
  final List<ChannelSales> channels;
  final bool loading;
  final String error;
  final List<PayoutSummary> payouts;
  final bool payoutsLoading;
  final String payoutsError;
  final ValueChanged<int> onOpenChannel;
  final ValueChanged<int> onOpenPayout;

  const SellerChannelRows({
    required this.channels,
    required this.loading,
    required this.error,
    required this.payouts,
    required this.payoutsLoading,
    required this.payoutsError,
    required this.onOpenChannel,
    required this.onOpenPayout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (loading) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator());
    }
    if (error.isNotEmpty) {
      return Text(error, style: TextStyle(fontSize: 13, color: scheme.error));
    }
    if (channels.isEmpty) {
      return Text(
        '이 판매자에게 연결된 판매채널이 없습니다.',
        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final channel in channels) ...[
          const Divider(height: 16),
          _channel(context, channel, scheme),
        ],
      ],
    );
  }

  Widget _channel(
      BuildContext context, ChannelSales channel, ColorScheme scheme) {
    final own = payouts.where((p) => p.accountId == channel.accountId).toList();
    final label = channelLabel(
      channel.platform,
      channel.accountAlias,
      channel.accountId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onOpenChannel(channel.accountId),
                child: Text(
                  '└ $label',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: scheme.primary),
                ),
              ),
            ),
            if (!payoutsLoading && own.isNotEmpty)
              TextButton(
                  onPressed: () => onOpenPayout(own.first.payoutId),
                  child: const Text('정산 내역 →')),
          ],
        ),
        SalesValueRow(
            label: '매출액', value: formatMoney(channel.grossSales), bold: true),
        SalesValueRow(label: '할인', value: formatMoney(channel.discount)),
        SalesValueRow(
          label: '고정비',
          value: formatFixedCost(channel.fixedCost),
          hint: channel.fixedCost > 0
              ? '${channel.fixedCostMonths}개월분 · '
                  '${fixedCostHintFor(channel.platform)}'
              : fixedCostHintFor(channel.platform),
        ),
        SalesValueRow(
          label: '순이익(추정)',
          value: formatProfit(channel.estNetProfit,
              costBasisReady: channel.costBasisReady),
          hint: channel.costBasisReady ? null : kProfitPendingHint,
        ),
        SalesValueRow(
            label: '정산 추정 금액',
            sub: '기간 무관 · 미지급 잔액',
            value: formatMoney(channel.pendingPayout)),
        SalesValueRow(
            label: '지급확정',
            sub: '기간 내 입금',
            value: formatMoney(channel.paidAmount)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ChannelPayoutList(
            payouts: own,
            loading: payoutsLoading,
            error: payoutsError,
            onOpen: onOpenPayout,
          ),
        ),
      ],
    );
  }
}
