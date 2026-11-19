import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/features/stock_ledger/domain/entities/stock_enums.dart'
    show unexpandedReasonLabel;
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import '../../domain/entities/order_item.dart';
import 'elevenst_reserved_badge.dart';
import 'internal_stage_badge.dart';
import 'order_select_box.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/name_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';

/// Card for one order — shared by the two screens, order history and shipment
/// management.
///
/// **Purpose**: one card = one order ([OrderGroup]: the lines of the same
/// account and the same order number). Next to the photo (first option
/// line): row ① channel badge (+ 「취소」 · [송장 수정]) · seller name ···
/// order number / ② option lines with the components below / ③ customer ···
/// paid time (FEATURE_2611_32 / D8 · D9 · D21). The 「판매처」 text comes from
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
/// ⚠️ The selection box is **optional** ([onToggleSelect] not passed =
/// exactly the card as it is now). Only order acknowledgement (shipment
/// management) passes it — order history does not. It is the 22
/// [OrderSelectBox] (D11); a selected row is `AppColors.warningSurface`.
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
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard.flush(
      child: Ink(
        color: (selected ?? false) ? AppColors.warningSurface : null,
        child: InkWell(
          // Card tap → order detail page, the first line passed as `extra`.
          onTap: () =>
              context.push(Routes.orderHistoryDetailPath, extra: first),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            // Row layout = FEATURE_2611_32 / D9; the web narrow card draws
            // the same (D19).
            child: _withCheckbox(_withThumbnail(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _SalesChannelBadge(label: salesChannel)),
                      if (isOrderCancelled(order)) ...[
                        const SizedBox(width: 6),
                        const _CancelledBadge(),
                      ],
                      // [송장 수정](D18) — the button takes its own tap, so it
                      // does not leak to the card tap (order detail).
                      if (onEditInvoice != null &&
                          order.lines
                              .any((line) => line.internalStage != null)) ...[
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: onEditInvoice,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '송장 수정',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          first.sellerName ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        first.externalOrderId,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _OrderProducts(
                    order: order,
                    collapsed: collapsed,
                    onToggleCollapsed: onToggleCollapsed,
                    onOpenLine: (line) => context.push(
                        Routes.orderHistoryDetailPath,
                        extra: line),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: NameText(
                          name: getCustomerName(first),
                          kind: NameKind.customer,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatOrderDateTime(first.paidAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  static const double _thumbSize = 64;

  /// Thumbnail on the left, the text column on the right.
  Widget _withThumbnail(BuildContext context, Widget content) {
    final colorScheme = Theme.of(context).colorScheme;
    final coverUrl = order.lines.first.masterCoverImageUrl;
    Widget framed(Widget clipped) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: clipped,
        );
    final Widget thumb;
    if (coverUrl == null) {
      thumb = framed(ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: _thumbSize,
          height: _thumbSize,
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.inventory_2_outlined,
            size: 26,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ));
    } else {
      final cover = framed(ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MasterNetworkImage(
          url: coverUrl,
          width: _thumbSize,
          height: _thumbSize,
          fit: BoxFit.cover,
        ),
      ));
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

  /// No Row at all without [onToggleSelect] — order history renders exactly
  /// as before.
  ///
  /// ⚠️ [OrderSelectBox] takes its own tap — do not wrap it in another
  /// GestureDetector (the tap would leak to the detail).
  Widget _withCheckbox(Widget content) {
    final onToggle = onToggleSelect;
    if (onToggle == null) return content;
    return Row(
      children: [
        OrderSelectBox(
          selected: selected ?? false,
          onTap: selectable ? () => onToggle(order) : null,
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// Sales channel badge at the start of row ① (FEATURE_2611_32 / D9 ①).
class _SalesChannelBadge extends StatelessWidget {
  final String label;

  const _SalesChannelBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.channelBadgeSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.channelBadgeForeground,
        ),
      ),
    );
}

/// 「취소」 badge beside the order number when every option line of the order
/// is fully cancelled (FEATURE_2611_30 / D6 · R9) — same shape as
/// `InternalStageBadge` without border and icon.
class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge();

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cancelBadgeSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        getOrderStatusLabel(OrderStatus.cancelled),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.cancelBadgeForeground,
        ),
      ),
    );
}

/// Ordered products of one order card (FEATURE_2611_30 / D5 · D18 · D21 ·
/// D23 ~ D25 · D27 · D28 · D32): per option line, the master label (or the
/// grey market name + broken reason), the quantity tail and the badges, then
/// the component products below it (left rule). One collapse button per
/// order folds the components into 「구성상품 N개」. Tapping an option text
/// opens that line.
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
    final rule = Theme.of(context).colorScheme.outlineVariant;
    final hasComponents =
        order.lines.any((line) => line.components.isNotEmpty);
    final lines = <Widget>[
      for (final line in order.lines) ...[
        if (line != order.lines.first) const SizedBox(height: 6),
        _line(line, grey, rule),
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

  Widget _line(OrderItem line, Color grey, Color rule) {
    final masterLabel = orderLineMasterLabel(line);
    final reason = line.unexpandedReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
                    ? TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: grey,
                      )
                    : const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
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
        const SizedBox(height: 2),
        _components(line, rule),
      ],
    );
  }

  Widget _components(OrderItem line, Color rule) {
    const style = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    if (line.components.isEmpty) {
      return const Text('-', style: style);
    }
    if (collapsed) {
      return Text('구성상품 ${line.components.length}개', style: style);
    }
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: rule, width: 2)),
      ),
      child: Column(
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
                Text(
                  '× ${component.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
