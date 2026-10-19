import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Payouts for the period's sales of one channel (FEATURE_2610_20 / D26 · D38 ·
/// D40) — the web `ChannelPayoutList`.
///
/// 🔴 Grouped by recognition month with a month header — sales are on the sale
/// date, payouts on the recognition month.
/// 🔴 No total — a month of payouts and the period's sales are on different
/// axes.
/// ⚠️ The date = `finalSettlementDate ?? settlementDate`; an overdue 11st
/// payout reads 「입금 확인 필요」 in yellow. The words match `reconBadge` of the
/// 「정산 내역」 list.
class ChannelPayoutList extends StatelessWidget {
  final List<PayoutSummary> payouts;
  final bool loading;
  final String error;
  final ValueChanged<int> onOpen;

  const ChannelPayoutList({
    required this.payouts,
    required this.loading,
    required this.error,
    required this.onOpen,
    super.key,
  });

  static ({String text, Color? color}) _recon(
      PayoutSummary payout, ColorScheme scheme) {
    switch (payout.reconStatus) {
      case 'RECONCILED':
        return (text: '금액 일치', color: AppColors.successForeground);
      case 'UNRECONCILED':
        return (text: '금액 차이', color: AppColors.warningForeground);
      case 'AMOUNT_ONLY':
        return (text: '금액만 기록', color: scheme.onSurfaceVariant);
      case 'NO_TOTAL':
        return (text: '맞춰 볼 총액 없음', color: scheme.onSurfaceVariant);
      default:
        return (
          text: payout.finalAmount == null ? '지급내역 대기' : '확인 대기',
          color: scheme.onSurfaceVariant
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    if (loading) {
      return const LinearProgressIndicator();
    }
    if (error.isNotEmpty) {
      return Text(error, style: TextStyle(fontSize: 12, color: scheme.error));
    }
    if (payouts.isEmpty) {
      return Text('이 기간 매출에 대한 정산이 아직 없습니다.', style: muted);
    }
    final groups = <({String month, List<PayoutSummary> rows})>[];
    for (final payout in payouts) {
      final month = payout.revenueRecognitionMonth ?? '—';
      if (groups.isNotEmpty && groups.last.month == month) {
        groups.last.rows.add(payout);
      } else {
        groups.add((month: month, rows: [payout]));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Text('${monthLabel(group.month)} 매출분',
              style: muted.copyWith(fontWeight: FontWeight.w600)),
          for (final payout in group.rows) _row(payout, scheme, muted),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _row(PayoutSummary payout, ColorScheme scheme, TextStyle muted) {
    final recon = _recon(payout, scheme);
    final paidDate = payout.finalSettlementDate ?? payout.settlementDate;
    final day = paidDate == null || paidDate.length < 5
        ? ''
        : ' ${paidDate.substring(5)}';
    return InkWell(
      onTap: () => onOpen(payout.payoutId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(settlementTypeLabel(payout.settlementType),
                style: const TextStyle(fontSize: 12)),
            Text('${formatMoney(payout.finalAmount)}원',
                style: const TextStyle(fontSize: 12)),
            if (payout.paymentCheckNeeded)
              Text('입금 확인 필요$day',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.warningForeground))
            else
              Text('지급 ${payoutStatusLabel(payout.status)}$day', style: muted),
            Text(recon.text,
                style: TextStyle(fontSize: 12, color: recon.color)),
            Text('상세 →', style: TextStyle(fontSize: 12, color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}
