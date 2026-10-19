import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Amount-check badge of a payout — the words and colors of the web
/// `PayoutTable.reconBadge` (FEATURE_2610_20 / D22 · D29).
///
/// 🔴 AMOUNT_ONLY · NO_TOTAL · PENDING are normal states — gray, never the
/// warning color.
({String text, Color surface, Color foreground}) reconBadge(
    PayoutSummary row, ColorScheme scheme) {
  switch (row.reconStatus) {
    case 'RECONCILED':
      return (
        text: '✅ 금액 일치 (판매 ${formatCount(row.lineCount)}건)',
        surface: AppColors.successSurface,
        foreground: AppColors.successForeground,
      );
    case 'UNRECONCILED':
      return (
        text: '⚠ 금액 차이 — 상세에서 확인',
        surface: AppColors.warningSurface,
        foreground: AppColors.warningForeground
      );
    case 'AMOUNT_ONLY':
      return (
        text: 'ⓘ 금액만 기록 — 판매 내역 대조 불가',
        surface: scheme.surfaceContainerLow,
        foreground: scheme.onSurfaceVariant
      );
    case 'NO_TOTAL':
      return (
        text: 'ⓘ 맞춰 볼 총액 없음',
        surface: scheme.surfaceContainerLow,
        foreground: scheme.onSurfaceVariant
      );
    default:
      return (
        text: row.finalAmount == null ? '⏳ 지급내역 대기' : '⏳ 확인 대기 — 판매 내역 미적재',
        surface: scheme.surfaceContainerLow,
        foreground: scheme.onSurfaceVariant,
      );
  }
}

/// One payout row of 「정산 내역」 (FEATURE_2610_20 / D18 · D38 · D40) — the web
/// `PayoutTable` row as a card.
///
/// ⚠️ 「지급일」 = `finalSettlementDate ?? settlementDate` (D38); an overdue 11st
/// payout reads 「입금 확인 필요」 in yellow (D40).
class PayoutTile extends StatelessWidget {
  final PayoutSummary row;
  final VoidCallback onOpen;

  const PayoutTile({required this.row, required this.onOpen, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant, fontSize: 12);
    final badge = reconBadge(row, scheme);
    return AppCard.row(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  channelLabel(row.platform, row.accountAlias, row.accountId),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(formatMoney(row.finalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Text(row.sellerName ?? '—', style: muted),
          const SizedBox(height: 6),
          Text(
            '${settlementTypeLabel(row.settlementType)} · 판매기간 '
            '${formatDateRange(row.recognitionFrom, row.recognitionTo)} '
            '(${row.revenueRecognitionMonth ?? '—'})',
            style: const TextStyle(fontSize: 13),
          ),
          Row(
            children: [
              Text(
                  '지급일 ${row.finalSettlementDate ?? row.settlementDate ?? '—'} '
                  '· ',
                  style: const TextStyle(fontSize: 13)),
              Text(
                payoutStatusText(row),
                style: TextStyle(
                  fontSize: 13,
                  color: row.paymentCheckNeeded
                      ? AppColors.warningForeground
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: badge.surface, borderRadius: BorderRadius.circular(4)),
            child: Text(badge.text,
                style: TextStyle(fontSize: 12, color: badge.foreground)),
          ),
        ],
      ),
    );
  }
}
