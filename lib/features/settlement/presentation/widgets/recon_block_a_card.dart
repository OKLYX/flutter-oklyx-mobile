import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Block A — the settlement detail of one payout (FEATURE_2610_20 / D14 · D22 ·
/// D29), the web `ReconBlockA`.
///
/// 🔴 Display only — every total, difference and tolerance comes from the
/// server.
/// 🔴 `ourTotal == null` = no comparison was made (additional · reserve
/// payouts, every 11st payout): the 「OCLYX 집계」 row, the diff badge and the
/// tolerance are not drawn. The market words name the payout channel's market
/// ([marketName]).
class ReconBlockACard extends StatelessWidget {
  final ReconBlockA blockA;
  final String? platform;
  final VoidCallback onShowUnmatched;

  const ReconBlockACard({
    required this.blockA,
    required this.platform,
    required this.onShowUnmatched,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final notReconciled = blockA.ourTotal == null;
    final pending = blockA.finalAmount == null;
    final matched =
        !pending && (blockA.diff ?? 0).abs() <= (blockA.tolerance ?? 0).abs();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('정산 상세 내역',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('${withSubjectParticle(marketName(platform))} 알려준 금액 구성입니다.',
              style: muted),
          const SizedBox(height: 8),
          _row('판매 건별 정산액 합계', formatMoney(blockA.lineTotal)),
          for (final adjustment in blockA.adjustments)
            ..._adjustment(adjustment, muted),
          if (!notReconciled)
            _row('OCLYX 집계', formatMoney(blockA.ourTotal), bold: true),
          _row('${marketName(platform)} 지급액', formatMoney(blockA.finalAmount),
              bold: true),
          if (!notReconciled) ...[
            const SizedBox(height: 4),
            _badge(
              pending
                  ? (
                      '⏳ 지급내역 미수신',
                      scheme.surfaceContainerLow,
                      scheme.onSurfaceVariant
                    )
                  : matched
                      ? (
                          '✅ 일치',
                          AppColors.successSurface,
                          AppColors.successForeground
                        )
                      : (
                          '⚠ 차액 ${formatSigned(blockA.diff)}',
                          AppColors.warningSurface,
                          AppColors.warningForeground
                        ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: Text(
                      '미분류 판매 건 ${formatCount(blockA.unmatchedCount)}건 '
                      '(합계에 포함)',
                      style: muted)),
              if (blockA.unmatchedCount > 0)
                OutlinedButton(
                    onPressed: onShowUnmatched, child: const Text('보기')),
            ],
          ),
          if (!pending && !notReconciled)
            Text('허용오차 ${formatMoney(blockA.tolerance)}원', style: muted),
        ],
      ),
    );
  }

  List<Widget> _adjustment(AdjustmentView adjustment, TextStyle muted) {
    final informational = isInformationalAdjustment(adjustment.type);
    final amount = adjustment.amount;
    final signed = amount == null
        ? null
        : amount * (adjustmentSign(adjustment.type) == -1 ? -1 : 1);
    final guidance = adjustment.guidance;
    final note = adjustment.note;
    return [
      _row(
        informational
            ? '${adjustmentLabel(adjustment.type)} · 정보성 · 합계 제외'
            : adjustmentLabel(adjustment.type),
        informational ? formatMoney(amount) : formatSigned(signed),
      ),
      if (note != null && note.isNotEmpty) Text(note, style: muted),
      if (guidance != null && guidance.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppColors.warningSurface,
          child: Text('ⓘ $guidance',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.warningForeground)),
        ),
    ];
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style =
        TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? style : null)),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _badge((String, Color, Color) badge) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: badge.$2, borderRadius: BorderRadius.circular(4)),
        child: Text(badge.$1, style: TextStyle(fontSize: 12, color: badge.$3)),
      );
}
