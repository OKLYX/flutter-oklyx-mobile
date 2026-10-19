import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/recon_line_list.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// 「이 정산에 포함된 주문」 — every sale line of the payout (FEATURE_2610_20 / D22), the
/// web `PayoutOrderList`.
///
/// 🔴 When empty it says why: lines come only from the revenue lookup, so a
/// channel with payouts only has none.
/// ⚠️ The search filters on screen only (the whole list is already loaded).
class PayoutOrderList extends StatefulWidget {
  final List<ReconLineView> lines;
  final bool loading;
  final String error;
  final ValueChanged<ReconLineView> onCopy;

  const PayoutOrderList({
    required this.lines,
    required this.loading,
    required this.error,
    required this.onCopy,
    super.key,
  });

  @override
  State<PayoutOrderList> createState() => _PayoutOrderListState();
}

class _PayoutOrderListState extends State<PayoutOrderList> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
    final needle = _normalize(_query.text);
    final visible = needle.isEmpty
        ? widget.lines
        : widget.lines
            .where((l) => _normalize([
                  l.externalOrderId,
                  l.platformOptionId,
                  l.productName
                ].whereType<String>().join(' '))
                    .contains(needle))
            .toList();
    final shown = needle.isEmpty ? '' : '${formatCount(visible.length)} / ';
    final isEmpty =
        !widget.loading && widget.error.isEmpty && widget.lines.isEmpty;
    return AppCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이 정산에 포함된 주문',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                if (!widget.loading &&
                    widget.error.isEmpty &&
                    widget.lines.isNotEmpty)
                  Text(
                    '$shown'
                    '${formatCount(widget.lines.length)}건 · 판매일 기준',
                    style: muted,
                  ),
                if (!isEmpty && widget.error.isEmpty) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _query,
                    decoration: const InputDecoration(
                      hintText: '주문번호 · 옵션ID · 상품명',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '판매 내역이 아직 적재되지 않았습니다. 정산 화면의 [갱신]으로 매출내역을 불러오면 이 정산에 포함된 주문이 '
                '여기 나옵니다.',
                style: muted,
              ),
            )
          else if (needle.isNotEmpty && visible.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('검색 결과가 없습니다.', style: muted),
            )
          else ...[
            const Divider(height: 1),
            ReconLineList(
                lines: visible,
                loading: widget.loading,
                error: widget.error,
                onCopy: widget.onCopy),
          ],
        ],
      ),
    );
  }
}
