import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// 「포장 절약」 card of 「통합 매출 조회」 (FEATURE_2610_20 / D26) — the web
/// `PackingSavingsCard`.
///
/// 🔴 「no record」 and 「saved 0」 are different — with no box at all the card
/// says so instead of 「0원」.
/// 🔴 The recycled and consolidated lines are never added together (some boxes
/// count in both).
class PackingSavingsCard extends StatelessWidget {
  final SavingsSummary? summary;
  final bool loading;
  final String error;

  const PackingSavingsCard(
      {required this.summary,
      required this.loading,
      required this.error,
      super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final summary = this.summary;
    Widget card(List<Widget> children) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('포장 절약',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        );
    if (error.isNotEmpty) {
      return card(
          [Text(error, style: TextStyle(fontSize: 13, color: scheme.error))]);
    }
    if (summary == null) {
      return card(
          [Text(loading ? '불러오는 중...' : '포장 절약을 불러오지 못했습니다.', style: muted)]);
    }
    if (summary.parcelCount == 0 && summary.missingBasisCount == 0) {
      return card([
        Text('이 기간에는 포장 기록이 없습니다.', style: muted),
        const SizedBox(height: 4),
        Text(kSavingsBasisNotice, style: muted),
      ]);
    }
    const warn = TextStyle(fontSize: 12, color: AppColors.warningForeground);
    return card([
      if (loading) Text('조회 중...', style: muted),
      Text('이 기간 아낀 금액', style: muted),
      Text(
        formatSaving(summary.totalSaving),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: savingColor(summary.totalSaving, scheme),
        ),
      ),
      Text('박스 ${formatCount(summary.parcelCount)}건 기준', style: muted),
      const SizedBox(height: 8),
      _line('상자', null, summary.boxSaving, scheme),
      Tooltip(
        message: '무료배송 박스에서만 납니다. 유료배송은 받는 배송비와 상쇄돼 절약이 0입니다',
        child: _line('택배비', null, summary.deliverySaving, scheme),
      ),
      const Divider(height: 16),
      _line('재활용 상자 사용', '${formatCount(summary.recycledParcelCount)}박스',
          summary.recycledSaving, scheme),
      _line('합포장', '${formatCount(summary.consolidatedParcelCount)}박스',
          summary.consolidatedSaving, scheme),
      const SizedBox(height: 8),
      Text(kSavingsOverlapNotice, style: muted),
      Text('⚠ $kSavingsBasisNotice', style: muted),
      Text(kSavingsProfitNotice, style: muted),
      if (summary.missingBasisCount > 0)
        Text(
            '⚠ 계산 근거가 없는 박스 ${formatCount(summary.missingBasisCount)}건은 합계에서 '
            '빠져 있습니다.',
            style: warn),
      if (summary.missingShippingFeeCount > 0)
        Text(
          '⚠ 배송비 기록이 없어 택배비 절약을 못 센 박스 '
          '${formatCount(summary.missingShippingFeeCount)}건이 있습니다. '
          '그 박스의 상자 절약은 합계에 들어가 있습니다.',
          style: warn,
        ),
      if (summary.negativeParcelCount > 0)
        Text(
            '상자를 계산보다 비싸게 쓴 박스 ${formatCount(summary.negativeParcelCount)}건이 '
            '합계에 포함돼 있습니다.',
            style: muted),
    ]);
  }

  Widget _line(String label, String? sub, num value, ColorScheme scheme) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            if (sub != null) ...[
              const SizedBox(width: 8),
              Text(sub,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
            const Spacer(),
            Text(
              formatSaving(value),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: savingColor(value, scheme)),
            ),
          ],
        ),
      );
}
