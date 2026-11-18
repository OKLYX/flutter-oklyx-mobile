import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/features/stock_ledger/domain/entities/stock_enums.dart'
    show unexpandedReasonLabel;
import '../../domain/entities/order_item.dart';
import 'elevenst_reserved_badge.dart';
import 'internal_stage_badge.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/name_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';

/// Card for one order — shared by the two screens, order history and shipment
/// management.
///
/// **Purpose**: one card = one order ([OrderGroup]: the lines of the same
/// account and the same order number). The shown items are the photo (first
/// option line) / order number + 「취소」 badge + [송장 수정] /
/// 「판매자 … 판매처 …」 / 「고객 …」 / ordered products (per option line: name ·
/// quantity tail · badges → component products) / 「결제일 …」
/// (FEATURE_2611_30 / D1 · D5 · D10). The 「판매처」 text comes from
/// `salesChannelLabel` only (FEATURE_2611_24 / D15 · D17).
/// Tapping the card opens the first line's detail; tapping an option text
/// opens that line's detail (D18). Collapsing is [collapsed] ·
/// [onToggleCollapsed], held by the screen BLoC (D26).
/// **Required rule**: a new screen that draws an order list uses this widget.
/// Do not build the card again per screen.
/// **File**: lib/features/order/presentation/widgets/order_card.dart
///
/// **Usage**:
/// ```dart
/// SliverList.separated(
///   itemCount: orders.length,
///   separatorBuilder: (_, __) => const AppRowGap(),
///   itemBuilder: (context, index) => OrderCard(
///     order: orders[index],
///     collapsed: s.collapsedOrderKeys.contains(orders[index].key),
///     onToggleCollapsed: () =>
///         bloc.add(ToggleOrderCollapsed(orderKey: orders[index].key)),
///   ),
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
/// ⚠️ The thumbnail (left) is the cover photo of the first option line's
/// master (`masterCoverImageUrl`, FEATURE_2611_31 / D1 · D6); without one it
/// is a grey box of the same size — never a product photo instead (D2).
/// Tapping an `http` photo opens the zoom viewer instead of the detail page.
/// ❌ Do not make a `_OrderCard` copy per screen (the cards of the two screens
/// silently drift apart).
class OrderCard extends StatelessWidget {
  final OrderGroup order;

  /// Components collapsed — the screen BLoC's `collapsedOrderKeys` (D24 · D26).
  final bool collapsed;

  /// Collapse / expand tap — the screen adds `ToggleOrderCollapsed`
  /// (D24 · D26).
  final VoidCallback onToggleCollapsed;

  /// Selection checkbox (acknowledgement only, PLAN 2609_17 D7). With all
  /// three at their defaults the card is the same as without selection.
  final bool? selected;

  /// Check toggle callback — passes the order ([OrderGroup]). null = no
  /// checkbox at all (the render tree must equal order history's).
  final ValueChanged<OrderGroup>? onToggleSelect;

  /// false = a disabled (grey) checkbox — a row the screen does not let you
  /// pick (shipment management: neither Coupang nor 11st, FEATURE_2610_17 /
  /// D28).
  final bool selectable;

  /// [송장 수정] of an order with any line at an internal stage
  /// (FEATURE_2609_75 / D18 · FEATURE_2611_30 / D16). null = no button —
  /// only shipment management passes it.
  final VoidCallback? onEditInvoice;

  const OrderCard({
    required this.order,
    required this.collapsed,
    required this.onToggleCollapsed,
    super.key,
    this.selected,
    this.onToggleSelect,
    this.selectable = true,
    this.onEditInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final first = order.lines.first;
    final salesChannel = salesChannelLabel(first.platform, first.accountAlias);
    return AppCard.row(
      // Card tap → order detail page, the first line passed as `extra`.
      onTap: () => context.push(Routes.orderHistoryDetailPath, extra: first),
      // Card items follow the column order of the web OrderTable.
      child: _withCheckbox(_withThumbnail(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      first.externalOrderId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOrderCancelled(order)) const _CancelledBadge(),
                    // [송장 수정](D18) — the button takes its own tap, so it
                    // does not leak to the card tap (order detail).
                    if (onEditInvoice != null &&
                        order.lines.any((line) => line.internalStage != null))
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
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '판매자 ${first.sellerName ?? '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '판매처 $salesChannel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                NameText(
                  name: '고객 ${getCustomerName(first)}',
                  kind: NameKind.customer,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                _OrderProducts(
                  order: order,
                  collapsed: collapsed,
                  onToggleCollapsed: onToggleCollapsed,
                  onOpenLine: (line) => context.push(
                      Routes.orderHistoryDetailPath,
                      extra: line),
                ),
                const SizedBox(height: 6),
                Text(
                  '결제일 ${formatOrderDateTime(first.paidAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )),
    );
  }

  static const double _thumbSize = 56;

  /// Thumbnail on the left, the text column on the right.
  Widget _withThumbnail(BuildContext context, Widget content) {
    final coverUrl = order.lines.first.masterCoverImageUrl;
    final Widget thumb;
    if (coverUrl == null) {
      thumb = ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: _thumbSize,
              height: _thumbSize,
              color: Theme.of(context).colorScheme.outlineVariant,
              child: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: _thumbSize * 0.5,
              ),
            ),
          );
    } else {
      final cover = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: MasterNetworkImage(
          url: coverUrl,
          width: _thumbSize,
          height: _thumbSize,
          fit: BoxFit.cover,
        ),
      );
      thumb = coverUrl.startsWith('http')
          ? ImageWithZoomButton(
              image: NetworkImage(coverUrl),
              iconSize: 14,
              child: cover,
            )
          : cover;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        thumb,
        const SizedBox(width: 12),
        Expanded(child: content),
      ],
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
          onChanged: selectable ? (_) => onToggle(order) : null,
        ),
        const SizedBox(width: 4),
        Expanded(child: content),
      ],
    );
  }
}

/// 「취소」 badge beside the order number when every option line of the order
/// is fully cancelled (FEATURE_2611_30 / D6 · R9) — same shape as
/// `InternalStageBadge` without border and icon.
class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        getOrderStatusLabel(OrderStatus.cancelled),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.onErrorContainer,
        ),
      ),
    );
  }
}

/// Ordered products of one order card (FEATURE_2611_30 / D5 · D18 · D21 ·
/// D23 ~ D25 · D27 · D28 · D32): per option line, the master label (or the
/// grey market name + broken reason), the quantity tail and the badges, then
/// 「→」 and the component products. One collapse button per order folds the
/// components into 「구성상품 N개」. Tapping an option text opens that line.
class _OrderProducts extends StatelessWidget {
  final OrderGroup order;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<OrderItem> onOpenLine;

  const _OrderProducts({
    required this.order,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onOpenLine,
  });

  @override
  Widget build(BuildContext context) {
    final grey = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasComponents =
        order.lines.any((line) => line.components.isNotEmpty);
    final lines = <Widget>[
      for (final line in order.lines) ...[
        if (line != order.lines.first) const SizedBox(height: 6),
        _line(line, grey),
      ],
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasComponents)
          IconButton(
            icon: Icon(collapsed ? Icons.chevron_right : Icons.expand_more),
            tooltip: collapsed ? '구성상품 펼치기' : '구성상품 접기',
            onPressed: onToggleCollapsed,
            visualDensity: VisualDensity.compact,
            iconSize: 20,
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
      ],
    );
  }

  Widget _line(OrderItem line, Color grey) {
    final masterLabel = orderLineMasterLabel(line);
    final reason = line.unexpandedReason;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: () => onOpenLine(line),
                child: NameText(
                  name: masterLabel ?? line.itemName,
                  kind: NameKind.product,
                  style: masterLabel == null
                      ? TextStyle(fontSize: 13, color: grey)
                      : const TextStyle(fontSize: 13),
                ),
              ),
              Text(
                orderLineQuantityLabel(line),
                style: const TextStyle(fontSize: 13),
              ),
              if (masterLabel == null && reason != null)
                Text(
                  unexpandedReasonLabel(reason),
                  style: TextStyle(fontSize: 12, color: grey),
                ),
              // Internal stage badge (FEATURE_2609_75 / D9) — draws nothing
              // when null.
              InternalStageBadge(stage: line.internalStage),
              // 11st reserved sale (FEATURE_2610_17 / D67) — the server's
              // flag.
              if (line.reservedSale) const ElevenstReservedBadge(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('→', style: TextStyle(fontSize: 12, color: grey)),
        ),
        Expanded(child: _components(line)),
      ],
    );
  }

  Widget _components(OrderItem line) {
    const style = TextStyle(fontSize: 12);
    if (line.components.isEmpty) {
      return const Text('-', style: style);
    }
    if (collapsed) {
      return Text('구성상품 ${line.components.length}개', style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final component in line.components)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: NameText(
                  name: component.productName,
                  kind: NameKind.product,
                  style: style,
                ),
              ),
              const SizedBox(width: 4),
              Text('× ${component.quantity}', style: style),
            ],
          ),
      ],
    );
  }
}
