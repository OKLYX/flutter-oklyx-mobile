import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/widgets/sales_value_row.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Box-count hint (web `PARCEL_COUNT_HINT`).
const String kParcelCountHint = '이 상품이 담긴 박스 수입니다. 한 박스에 옵션이 여러 개 담기면 중복해 셉니다';

/// Product rows of 「상품별 매출」 (FEATURE_2610_20 / D26) — the web
/// `ProductProfitTable`.
///
/// - [showChannel] (「채널별로 보기」) adds the channel line and drops the packing
///   savings (S13).
/// - A row with option savings opens to its options; a row without savings does
///   not open.
/// - No savings record = `—`, not 「0원」 (S1).
class ProductProfitList extends StatelessWidget {
  final List<ProductProfit> rows;
  final bool showChannel;
  final Map<int, MasterSaving> savingsByMaster;
  final int? expandedSavingsMasterId;
  final ValueChanged<int> onToggleSavings;
  final bool loading;
  final String error;
  final VoidCallback onRetry;

  const ProductProfitList({
    required this.rows,
    required this.showChannel,
    required this.savingsByMaster,
    required this.expandedSavingsMasterId,
    required this.onToggleSavings,
    required this.loading,
    required this.error,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    if (error.isNotEmpty) {
      return AppErrorBox(
          message: error,
          action: TextButton(onPressed: onRetry, child: const Text('다시 시도')));
    }
    if (loading && rows.isEmpty) {
      return const AppLoading();
    }
    if (rows.isEmpty) {
      return const AppEmpty('해당 기간에 판매된 주문이 없습니다.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading) Text('조회 중...', style: muted),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const AppRowGap(),
          _row(rows[i], scheme, muted),
        ],
      ],
    );
  }

  Widget _row(ProductProfit row, ColorScheme scheme, TextStyle muted) {
    final masterId = row.masterProductId;
    final saving =
        showChannel || masterId == null ? null : savingsByMaster[masterId];
    final expandable = saving != null && saving.options.isNotEmpty;
    final expanded =
        expandable && expandedSavingsMasterId == saving.masterProductId;
    final marker = expandable ? (expanded ? '▾ ' : '▸ ') : '';
    final alias = row.accountAlias?.trim() ?? '';
    final channel = alias.isNotEmpty
        ? alias
        : (row.accountId == null ? '-' : '채널 #${row.accountId}');
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$marker${row.masterProductName}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: row.uncategorized ? scheme.onSurfaceVariant : null,
          ),
        ),
        if (row.uncategorized) Text('채널 옵션 연결이 없는 주문', style: muted),
        if (showChannel) Text('채널 $channel', style: muted),
        const SizedBox(height: 4),
        SalesValueRow(label: '판매수량', value: formatCount(row.netQty)),
        SalesValueRow(
            label: '매출액', value: formatMoney(row.grossSales), bold: true),
        SalesValueRow(label: '할인', value: formatMoney(row.discount)),
        SalesValueRow(label: '수수료(추정)', value: formatMoney(row.estFee)),
        SalesValueRow(
          label: '순이익(추정)',
          value: formatProfit(row.estNetProfit,
              costBasisReady: row.costBasisReady),
          hint: row.costBasisReady ? null : kProfitPendingHint,
        ),
        if (!showChannel) ...[
          SalesValueRow(
            label: '포장 절약',
            sub: '포장한 날 기준',
            value: formatSaving(saving?.totalSaving),
            valueColor: savingColor(saving?.totalSaving, scheme),
            hint: saving == null
                ? kSavingsNoRecordHint
                : '포장한 날 기준입니다. 왼쪽 손익은 주문일 기준이라 기간이 덮는 주문이 다릅니다',
          ),
          SalesValueRow(
            label: '박스 수',
            value: formatParcelCount(saving?.parcelCount),
            hint: saving == null ? kSavingsNoRecordHint : kParcelCountHint,
          ),
        ],
        if (expanded) ...[
          const Divider(height: 16),
          for (final option in saving.options)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                      child: Text('└ ${option.masterOptionName ?? '(옵션명 없음)'}',
                          style: const TextStyle(fontSize: 13))),
                  Text(
                    formatSaving(option.totalSaving),
                    style: TextStyle(
                        fontSize: 13,
                        color: savingColor(option.totalSaving, scheme)),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: kParcelCountHint,
                    child: Text('${formatParcelCount(option.parcelCount)}박스',
                        style: muted),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
    return expandable
        ? AppCard.row(
            onTap: () => onToggleSavings(saving.masterProductId), child: body)
        : AppCard.row(child: body);
  }
}
