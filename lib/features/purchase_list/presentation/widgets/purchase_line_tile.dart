import 'package:flutter/material.dart';

import '../../domain/entities/purchase_line.dart';

/// 구매목록 주문 줄 1개 (펼쳐진 상품 카드 내부).
///
/// **표시 전용이다** — 입력 컨트롤이 없다(PLAN 2609_29 D7). 구매 입력은 그룹 상단
/// 입고 카드(`PurchaseIntakeCard`) 하나로 모였고, 구매기록은 주문을 모른다(D3).
///
/// 좁은 화면이라 표가 아니라 줄 단위로 나열한다:
/// ```
/// A상사/쿠팡    #20260909-1   필요 3
/// 수동          —             필요 2
/// ```
/// 채널 라벨은 `channelLabel(line)` 하나만 쓴다 — ❌ 라벨표 사본 금지.
class PurchaseLineTile extends StatelessWidget {
  final PurchaseLine line;

  const PurchaseLineTile({required this.line, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              channelLabel(line),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: Text(
              // 수동 라인은 주문번호가 없다.
              line.externalOrderId ?? '—',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '필요 ${line.neededQty}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
