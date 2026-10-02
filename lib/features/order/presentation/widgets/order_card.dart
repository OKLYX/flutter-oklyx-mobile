import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import '../../domain/entities/order_item.dart';
import 'internal_stage_badge.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Card for one order — shared by the two screens, order history and shipment
/// management.
///
/// **Purpose**: one row of the order list. The shown items are the same as the
/// columns of the front-end `OrderTable`
/// (order number / customer name / product name / ordered quantity /
/// cancelled / paid date).
/// **Required rule**: a new screen that draws an order list uses this widget.
/// Do not build the card again per screen.
/// **File**: lib/features/order/presentation/widgets/order_card.dart
///
/// **Usage**:
/// ```dart
/// SliverList.separated(
///   itemCount: orders.length,
///   separatorBuilder: (_, __) => const SizedBox(height: 8),
///   itemBuilder: (context, index) => OrderCard(order: orders[index]),
/// )
/// ```
///
/// ⚠️ Tap → navigation to the order detail lives inside the widget
/// (`context.push` + `extra`). The screen does not decide it — pulling `onTap`
/// out as a parameter or switching to `context.go` changes the back navigation.
/// ⚠️ The widget does not build the status label or the date format itself —
/// it uses `getOrderStatusLabel` · `formatOrderDateTime`.
/// ⚠️ The selection checkbox is **optional** ([onToggleSelect] not passed =
/// exactly the card as it is now). Only order acknowledgement (shipment
/// management) passes it — order history does not.
/// ❌ Do not make a `_OrderCard` copy per screen (the cards of the two screens
/// silently drift apart).
class OrderCard extends StatelessWidget {
  final OrderItem order;

  /// 선택 체크박스(발주처리 전용, PLAN 2609_17 D7). 셋 다 기본값이면 지금과 같은 카드다.
  final bool? selected;

  /// 체크 토글 콜백 — `order.id` 를 넘긴다. null 이면 체크박스를 아예 그리지 않는다
  /// (렌더 트리까지 주문내역과 동일해야 한다).
  final ValueChanged<int>? onToggleSelect;

  /// false 면 비활성 체크박스(회색) — 결제완료가 아니거나 비-쿠팡인 행(D2·D10).
  final bool selectable;

  /// 내부 단계 주문의 [송장 수정](FEATURE_2609_75 / D18). null 이면 버튼을 그리지 않는다 — 출고관리만 넘긴다.
  final VoidCallback? onEditInvoice;

  const OrderCard({
    super.key,
    required this.order,
    this.selected,
    this.onToggleSelect,
    this.selectable = true,
    this.onEditInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.row(
      // 항목 탭 → 주문 상세 페이지로 이동 (선택한 OrderItem 을 extra 로 전달).
      onTap: () => context.push(Routes.orderHistoryDetailPath, extra: order),
      // 카드 항목은 프론트 OrderTable 컬럼과 동일:
      // 주문번호 / 고객명 / 상품명 / 주문수량 / 취소 / 결제일.
      child: _withCheckbox(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      order.externalOrderId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 내부 단계 배지(FEATURE_2609_75 / D9) — null 이면 아무것도 그리지 않는다.
                    InternalStageBadge(stage: order.internalStage),
                    // [송장 수정](D18) — 버튼 탭은 카드 탭(주문 상세)으로 새지 않는다(버튼이 먼저 받는다).
                    if (onEditInvoice != null && order.internalStage != null)
                      TextButton(
                        onPressed: onEditInvoice,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child:
                            const Text('송장 수정', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '고객 ${getCustomerName(order)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(order.itemName ?? '-',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _metric(context, '주문수량', order.orderCount),
                    _metric(context, '취소', order.cancelCount),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '결제일 ${formatOrderDateTime(order.paidAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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

  Widget _metric(BuildContext context, String label, int value) => Text(
        '$label $value',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}
