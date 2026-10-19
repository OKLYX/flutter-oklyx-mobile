import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';

/// Products sold in the chosen channel (FEATURE_2610_20 / D26) — the web
/// `ChannelSalesLines`. An unlinked order shows 「(상품 미연결)」 and is never hidden.
class ChannelProductList extends StatelessWidget {
  final List<ProductProfit> rows;
  final bool loading;
  final String error;

  const ChannelProductList(
      {required this.rows,
      required this.loading,
      required this.error,
      super.key});

  static String _profit(ProductProfit row) =>
      formatProfit(row.estNetProfit, costBasisReady: row.costBasisReady);

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
    if (rows.isEmpty) {
      return Text('이 기간에 이 채널에서 판매된 상품이 없습니다.', style: muted);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 12),
          Text.rich(
            TextSpan(
              text: rows[i].masterProductName,
              children: [
                if (rows[i].uncategorized)
                  TextSpan(
                      text: ' (상품 미연결)',
                      style: TextStyle(color: scheme.outline)),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          Tooltip(
            message: rows[i].costBasisReady ? '순이익(추정)' : kProfitPendingHint,
            child: Text(
              '판매 ${formatCount(rows[i].netQty)} · 매출 '
              '${formatMoney(rows[i].grossSales)} · '
              '할인 ${formatMoney(rows[i].discount)} · 수수료 '
              '${formatMoney(rows[i].estFee)} · '
              '순이익 '
              '${_profit(rows[i])}',
              style: muted,
            ),
          ),
        ],
      ],
    );
  }
}
