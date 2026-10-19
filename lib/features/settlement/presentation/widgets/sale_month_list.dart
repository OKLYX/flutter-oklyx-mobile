import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// 「판매월 기준」 — "when and for how much was that month's sale settled"
/// (FEATURE_2610_20 / D18), the mobile twin of the web `SaleMonthTable`.
///
/// ⚠️ A month subtotal is drawn only when the month was settled more than once;
/// it is the plain sum of the rows the server gave (no other number can come
/// out).
class SaleMonthList extends StatelessWidget {
  final List<SaleMonthSettlement> rows;
  final bool loading;
  final String error;
  final VoidCallback onRetry;

  const SaleMonthList({
    required this.rows,
    required this.loading,
    required this.error,
    required this.onRetry,
    super.key,
  });

  static num _settled(SaleMonthSettlement row) => row.settlementAmount;

  static num _sum(
    List<SaleMonthSettlement> rows,
    num Function(SaleMonthSettlement) pick,
  ) =>
      rows.fold<num>(0, (sum, row) => sum + pick(row));

  @override
  Widget build(BuildContext context) {
    if (error.isNotEmpty) {
      return AppErrorBox(
        message: error,
        action: FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
      );
    }
    if (loading && rows.isEmpty) {
      return const AppLoading();
    }
    if (rows.isEmpty) {
      return const AppEmpty('이 기간에 정산된 판매가 없습니다. 아직 정산되지 않은 판매는 여기 나오지 않습니다.');
    }
    final groups = <String, List<SaleMonthSettlement>>{};
    for (final row in rows) {
      groups.putIfAbsent(row.saleMonth, () => []).add(row);
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          for (final row in entry.value) ...[
            AppCard.row(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(monthLabel(row.saleMonth),
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Text(row.settlementDate ?? '—'),
                      const SizedBox(width: 8),
                      Text(
                        row.paid ? '완료' : '예정',
                        style: TextStyle(
                            color: row.paid
                                ? AppColors.successForeground
                                : scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Text(
                    '판매 ${formatCount(row.orders)}건 · 판매액 '
                    '${formatMoney(row.saleAmount)} · '
                    '정산액 ${formatMoney(row.settlementAmount)}',
                  ),
                ],
              ),
            ),
            const AppRowGap(),
          ],
          if (entry.value.length > 1) ...[
            AppCard.row(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${monthLabel(entry.key)} 합계 · ${entry.value.length}번에 나눠 '
                    '정산',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '판매 '
                    '${formatCount(_sum(entry.value, (r) => r.orders))}건 · '
                    '판매액 '
                    '${formatMoney(_sum(entry.value, (r) => r.saleAmount))} · '
                    '정산액 '
                    '${formatMoney(_sum(entry.value, _settled))}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const AppRowGap(),
          ],
        ],
      ],
    );
  }
}
