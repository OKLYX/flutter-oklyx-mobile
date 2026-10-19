import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/recon_line_list.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Block B — why the payout differs from what was expected, per sale line
/// (FEATURE_2610_20 / D22), the web `ReconBlockB`.
///
/// 🔴 Every label the server sends is drawn, 0 won included — the label amounts
/// add up to the total diff.
/// ⚠️ Sign = actual − expected: positive = received more than expected.
/// ⚠️ With no label, this card is only opened by 「미분류만 보기」 and reads as the
/// unmatched list.
class ReconBlockBCard extends StatelessWidget {
  final ReconBlockB blockB;
  final String expandedLabel;
  final bool unmatchedOnly;
  final List<ReconLineView> lines;
  final bool linesLoading;
  final String linesError;
  final ValueChanged<String> onExpand;
  final VoidCallback onToggleUnmatched;
  final ValueChanged<ReconLineView> onCopy;

  const ReconBlockBCard({
    required this.blockB,
    required this.expandedLabel,
    required this.unmatchedOnly,
    required this.lines,
    required this.linesLoading,
    required this.linesError,
    required this.onExpand,
    required this.onToggleUnmatched,
    required this.onCopy,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final unmatchedView = unmatchedOnly && blockB.labels.isEmpty;
    final list = ReconLineList(
        lines: lines, loading: linesLoading, error: linesError, onCopy: onCopy);
    return AppCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        unmatchedView ? '미분류 판매 건' : '차액 원인 분석',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (unmatchedOnly)
                      FilledButton(
                          onPressed: onToggleUnmatched,
                          child: const Text('미분류만 보기'))
                    else
                      OutlinedButton(
                          onPressed: onToggleUnmatched,
                          child: const Text('미분류만 보기')),
                  ],
                ),
                Text(
                  unmatchedView
                      ? '예상이 없어 원인 분해 대상이 아닌 판매 건입니다.'
                      : '판매 건별 원인 분해입니다. 차액은 실정산 − 예상이라 양수면 예상보다 더 받은 금액입니다.',
                  style: muted,
                ),
                if (!unmatchedView) ...[
                  const SizedBox(height: 8),
                  Text(
                    '예상 ${formatMoney(blockB.expected)} → 실정산 '
                    '${formatMoney(blockB.actual)} · '
                    '차액 ${formatSigned(blockB.totalDiff)}',
                  ),
                ],
              ],
            ),
          ),
          if (!unmatchedOnly)
            for (final label in blockB.labels) ...[
              const Divider(height: 1),
              _labelRow(label, scheme, muted),
              if (expandedLabel == label.label) list,
            ],
          if (unmatchedOnly) ...[const Divider(height: 1), list],
        ],
      ),
    );
  }

  Widget _labelRow(LabelView label, ColorScheme scheme, TextStyle muted) {
    final warn = label.label == 'ROUNDING' && (label.detail ?? '').isNotEmpty;
    final color = warn ? AppColors.warningForeground : scheme.onSurface;
    final detail = label.detail;
    return InkWell(
      onTap: () => onExpand(label.label),
      child: Container(
        color: warn ? AppColors.warningSurface : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    expandedLabel == label.label
                        ? Icons.expand_more
                        : Icons.chevron_right,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(causeLabel(label.label),
                        style: TextStyle(color: color))),
                Text(formatSigned(label.amount),
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text('${formatCount(label.count)}건', style: muted),
              ],
            ),
            if (detail != null && detail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(detail,
                    style:
                        warn ? TextStyle(fontSize: 12, color: color) : muted),
              ),
          ],
        ),
      ),
    );
  }
}
