import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import '../../domain/entities/order_item.dart';

/// 주문 1건 카드 — 주문내역·출고관리 두 화면이 공유한다.
///
/// **용도**: 주문 목록의 행 하나. 표시 항목은 프론트 `OrderTable` 컬럼과 동일하다
/// (주문번호 / 고객명 / 상품명 / 주문수량 / 취소 / 결제일).
/// **필수 규칙**: 주문 목록을 그리는 새 화면은 이 위젯을 쓴다. 화면별로 카드를 다시 만들지 말 것.
/// **파일**: lib/features/order/presentation/widgets/order_card.dart
///
/// **사용 예제**:
/// ```dart
/// ListView.separated(
///   itemCount: orders.length,
///   separatorBuilder: (_, __) => const SizedBox(height: 8),
///   itemBuilder: (context, index) => OrderCard(order: orders[index]),
/// )
/// ```
///
/// ⚠️ 탭 → 주문 상세 이동은 위젯 내부에 있다(`context.push` + `extra`). 화면이 정하지 않는다 —
/// `onTap` 을 파라미터로 빼거나 `context.go` 로 바꾸면 뒤로가기 동선이 달라진다.
/// ⚠️ 상태 라벨·날짜 포맷은 위젯이 직접 만들지 않는다 — `getOrderStatusLabel` ·
/// `formatOrderDateTime` 를 쓴다.
/// ⚠️ 선택 체크박스는 **옵션**이다([onToggleSelect] 미전달 = 지금과 완전히 같은 카드).
/// 발주처리(출고관리)만 넘긴다 — 주문내역은 넘기지 않는다.
/// ❌ 화면마다 `_OrderCard` 사본을 만들지 말 것(두 화면의 카드가 조용히 갈라진다).
class OrderCard extends StatelessWidget {
  final OrderItem order;

  /// 선택 체크박스(발주처리 전용, PLAN 2609_17 D7). 셋 다 기본값이면 지금과 같은 카드다.
  final bool? selected;

  /// 체크 토글 콜백 — `order.id` 를 넘긴다. null 이면 체크박스를 아예 그리지 않는다
  /// (렌더 트리까지 주문내역과 동일해야 한다).
  final ValueChanged<int>? onToggleSelect;

  /// false 면 비활성 체크박스(회색) — 결제완료가 아니거나 비-쿠팡인 행(D2·D10).
  final bool selectable;

  const OrderCard({
    super.key,
    required this.order,
    this.selected,
    this.onToggleSelect,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 항목 탭 → 주문 상세 페이지로 이동 (선택한 OrderItem 을 extra 로 전달).
        onTap: () => context.push(Routes.orderHistoryDetailPath, extra: order),
        child: Padding(
          padding: const EdgeInsets.all(12),
          // 카드 항목은 프론트 OrderTable 컬럼과 동일:
          // 주문번호 / 고객명 / 상품명 / 주문수량 / 취소 / 결제일.
          child: _withCheckbox(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.externalOrderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '고객 ${getCustomerName(order)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                ),
                const SizedBox(height: 6),
                Text(order.itemName ?? '-',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _metric('주문수량', order.orderCount),
                    _metric('취소', order.cancelCount),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '결제일 ${formatOrderDateTime(order.paidAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [onToggleSelect] 가 없으면 **Row 로 감싸지도 않는다** — 주문내역의 렌더 결과가
  /// 지금과 완전히 같아야 한다.
  ///
  /// ⚠️ `Checkbox.onChanged` 는 카드 `onTap`(상세 이동)과 독립이다 — 체크박스는 자체
  /// 히트영역이 있으므로 별도 `GestureDetector` 로 감싸지 말 것(탭이 상세로 새어 나간다).
  Widget _withCheckbox(Widget content) {
    final onToggle = onToggleSelect;
    if (onToggle == null) return content;
    return Row(
      children: [
        Checkbox(
          value: selected ?? false,
          onChanged: selectable ? (_) => onToggle(order.id) : null,
        ),
        const SizedBox(width: 4),
        Expanded(child: content),
      ],
    );
  }

  Widget _metric(String label, int value) => Text(
        '$label $value',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      );
}
