import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Order lines of the chosen channel (FEATURE_2610_20 / D26) — the web
/// `ChannelSaleRecords`.
///
/// - Two checkboxes hide cancel-confirmed / cancel-pending lines on screen only
///   (the totals above stay).
/// - The hidden count is shown, so the list total can be told apart from the
///   card.
/// - A line with a cancel is tinted red.
class ChannelSaleRecords extends StatelessWidget {
  final List<SalesLine> rows;
  final List<SalesLine> visible;
  final bool loading;
  final String error;
  final bool hideCanceled;
  final bool hidePending;
  final ValueChanged<bool> onHideCanceledChanged;
  final ValueChanged<bool> onHidePendingChanged;

  const ChannelSaleRecords({
    required this.rows,
    required this.visible,
    required this.loading,
    required this.error,
    required this.hideCanceled,
    required this.hidePending,
    required this.onHideCanceledChanged,
    required this.onHidePendingChanged,
    super.key,
  });

  static String _soldAt(String? value) {
    if (value == null || value.length < 16) {
      return value ?? '—';
    }
    return '${value.substring(5, 10)} ${value.substring(11, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    if (loading) {
      return const AppLoading();
    }
    if (error.isNotEmpty) {
      return AppErrorBox(message: error);
    }
    if (rows.isEmpty) {
      return const AppEmpty('이 기간에 이 채널에서 판매된 주문이 없습니다.');
    }
    final hidden = rows.length - visible.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: hideCanceled,
          onChanged: (value) => onHideCanceledChanged(value ?? false),
          title: const Text('취소확정(환불완료) 제거', style: TextStyle(fontSize: 13)),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: hidePending,
          onChanged: (value) => onHidePendingChanged(value ?? false),
          title: const Text('취소처리중(환불대기) 제거', style: TextStyle(fontSize: 13)),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (hidden > 0) Text('${formatCount(hidden)}건 숨김', style: muted),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          const AppEmpty('걸러낸 조건에 맞는 주문이 없습니다.')
        else
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const AppRowGap(),
            _row(visible[i], scheme, muted),
          ],
      ],
    );
  }

  Widget _row(SalesLine row, ColorScheme scheme, TextStyle muted) {
    final cancelled = row.cancelQty > 0 || row.holdQty > 0;
    return AppCard.row(
      child: Container(
        color: cancelled ? scheme.errorContainer.withValues(alpha: 0.3) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_soldAt(row.orderedAt)} · ${row.externalOrderId}',
                style: muted),
            Text.rich(
              TextSpan(
                text: row.itemName ?? '—',
                children: [
                  if (row.masterProductName == null)
                    TextSpan(
                        text: ' (상품 미연결)',
                        style: TextStyle(color: scheme.outline)),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  const TextSpan(text: '취소 '),
                  TextSpan(
                    text: formatCount(row.cancelQty),
                    style: row.cancelQty > 0
                        ? TextStyle(
                            fontWeight: FontWeight.w600, color: scheme.error)
                        : TextStyle(color: scheme.outline),
                  ),
                  TextSpan(text: ' | 판매 ${formatCount(row.netQty)}'),
                  if (row.holdQty > 0)
                    TextSpan(
                        text: ' (대기 ${formatCount(row.holdQty)})',
                        style: TextStyle(color: scheme.error)),
                  TextSpan(text: ' · 단가 ${formatMoney(row.unitPrice)}'),
                ],
              ),
            ),
            Text(
              '매출 ${formatMoney(row.grossSales)} · 할인 '
              '${formatMoney(row.discount)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
