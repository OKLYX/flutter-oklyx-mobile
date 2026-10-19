import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Sale lines of a payout (FEATURE_2610_20 / D22) — the web `ReconLineTable` as
/// rows.
///
/// 🔴 [식별자 복사] stays on every row — the screen exists to ask the market about a
/// line.
/// ⚠️ Display only; the page owns the lookup and the clipboard.
/// ⚠️ An unmatched line is not a failure — it has no expected value, so its
/// diff is `—`.
class ReconLineList extends StatelessWidget {
  final List<ReconLineView> lines;
  final bool loading;
  final String error;
  final ValueChanged<ReconLineView> onCopy;

  const ReconLineList({
    required this.lines,
    required this.loading,
    required this.error,
    required this.onCopy,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(padding: EdgeInsets.all(16), child: AppLoading());
    }
    if (error.isNotEmpty) {
      return Padding(
          padding: const EdgeInsets.all(16),
          child: AppErrorBox(message: error));
    }
    if (lines.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(16), child: AppEmpty('해당하는 판매 건이 없습니다.'));
    }
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _LineRow(line: lines[i], onCopy: onCopy),
        ],
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final ReconLineView line;
  final ValueChanged<ReconLineView> onCopy;

  const _LineRow({required this.line, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final tag = line.unmatched
        ? '미분류 · 합계 포함'
        : (line.label == 'NONE' ? '' : causeLabel(line.label));
    return Container(
      color: line.unmatched ? scheme.surfaceContainerLow : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(line.productName ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              TextButton.icon(
                onPressed: () => onCopy(line),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('식별자 복사'),
              ),
            ],
          ),
          if (tag.isNotEmpty) Text(tag, style: muted),
          Text(
              '주문번호 ${line.externalOrderId ?? '—'} · 옵션ID '
              '${line.platformOptionId ?? '—'}',
              style: muted),
          Text(
            '인식일 ${line.recognitionDate ?? '—'} · 지급일 '
            '${line.settlementDate ?? '—'} · '
            '${settlementTypeLabel(line.settlementType)}',
            style: muted,
          ),
          const SizedBox(height: 4),
          Text(
            '판매 ${formatMoney(line.saleAmount)} · 수수료 '
            '${formatMoney(line.serviceFee)} '
            '(${formatRatio(line.serviceFeeRatio)}) · 정산 '
            '${formatMoney(line.settlementAmount)} · '
            '차액 ${formatSigned(line.diff)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
