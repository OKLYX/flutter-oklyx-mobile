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
///
/// 예외: 수동 줄(`isManual`, manualQty > 0)은 [onRemove] 가 있으면 끝에 [제거] 를 단다.
/// 수동 수량을 0 으로 되돌릴 뿐 구매수량 입력이 아니다. 다시 수동 추가하면 되므로
/// 확인창 없이 바로 실행한다(mobile D23 — 확인창은 마켓 반영·되돌릴 수 없는 지우기만).
class PurchaseLineTile extends StatelessWidget {
  final PurchaseLine line;

  /// Removes this manual line (manualQty → 0). Null hides the button.
  final VoidCallback? onRemove;

  /// Disables [제거] while another action is running.
  final bool busy;

  const PurchaseLineTile({
    required this.line,
    this.onRemove,
    this.busy = false,
    super.key,
  });

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
          if (onRemove != null && line.isManual && line.manualQty > 0) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: busy ? null : onRemove,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('제거', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
