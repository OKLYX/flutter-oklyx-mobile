import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';

/// One recognition-month reference row (FEATURE_2610_20 / D14 · D22) — the web
/// `MonthCheckRow`.
///
/// 🔴 A reference, never the warning color; it writes 「차이」, not 「차액」.
/// 🔴 `ourLineCount == 0` = that month's revenue lines are not loaded — our
/// total and the difference are not drawn.
class MonthCheckCard extends StatelessWidget {
  final MonthCheck monthCheck;
  final String typeLabel;
  final String? platform;

  const MonthCheckCard(
      {required this.monthCheck,
      required this.typeLabel,
      required this.platform,
      super.key});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
    final loaded = monthCheck.ourLineCount > 0;
    final pending = monthCheck.pendingPayoutCount > 0
        ? ' · 지급액 미수신 ${formatCount(monthCheck.pendingPayoutCount)}건'
        : '';
    final month = monthCheck.revenueRecognitionMonth;
    return SettlementMessageBox(
      tone: SettlementMessageTone.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${month == null ? '—' : monthLabel(month)} 전체 대조 · 참고',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (loaded)
            _row('이 달 우리 집계 (판매 ${formatCount(monthCheck.ourLineCount)}건)',
                formatMoney(monthCheck.ourLineTotal)),
          _row(
            '이 달 ${marketName(platform)} 지급 합계 (지급 '
            '${formatCount(monthCheck.payoutCount)}건$pending)',
            formatMoney(monthCheck.payoutTotal),
          ),
          if (loaded) _row('차이', formatSigned(monthCheck.diff)),
          const SizedBox(height: 4),
          Text(
            loaded
                ? '이 $typeLabel은 이 지급 합계에 이미 포함돼 있습니다.'
                : '이 달 매출내역을 아직 불러오지 않아 대조할 수 없습니다. 정산 내역 목록의 [과거 정산 불러오기]로 먼저 '
                    '적재하세요.',
            style: muted,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
