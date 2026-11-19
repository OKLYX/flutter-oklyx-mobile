import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../../domain/entities/order_item.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Underlined status tabs with count badges — shared by order history (all
/// statuses) and shipment management (the two unshipped statuses).
///
/// **Purpose**: the first tab is 「전체」 (= `onSelect(null)`), then one tab per
/// status; only the picked status stays in the list. Re-tapping the picked
/// tab does nothing (FEATURE_2611_32 / D7 · D4-14; 🔁 PLAN 2609_15 D9).
/// Order history = the tab row scrolls sideways and follows the picked tab
/// into view. Shipment management = `equalWidth: true` (tabs share the width).
/// **Required rule**: always pass the candidate statuses through [statuses].
/// Do not build the tabs again on a screen.
/// **File**:
/// lib/features/order/presentation/widgets/order_status_filter_bar.dart
///
/// **Usage**:
/// ```dart
/// // Order history — all statuses (default)
/// OrderStatusFilterBar(
///   selectedStatus: s.selectedStatus,
///   counts: counts,
///   allCount: scopedOrders.length,
///   onSelect: (status) => bloc.add(SelectStatus(status: status)),
/// )
///
/// // Shipment management — the two unshipped statuses
/// OrderStatusFilterBar(
///   selectedStatus: s.selectedStatus,
///   counts: counts,
///   allCount: countOrders(scoped),
///   onSelect: (status) => bloc.add(SelectStatus(status: status)),
///   statuses: kShipmentStatuses,
///   equalWidth: true,
/// )
/// ```
///
/// ⚠️ The keys of [statuses] · [counts] are the neutral status [OrderStatus]
/// — not the platform's raw code strings (FEATURE_2609_26 D4).
/// ⚠️ [counts] and [allCount] must come from **the same source as the list**
/// — when the badges and the list count different sets the screen drifts.
/// ❌ No copy of the label table — the Korean labels come from
/// `getOrderStatusLabel` only.
class OrderStatusFilterBar extends StatefulWidget {
  final OrderStatus? selectedStatus;
  final Map<OrderStatus, int> counts;

  /// Count of the 「전체」 tab.
  final int allCount;
  final void Function(OrderStatus? status) onSelect;

  /// Candidate statuses. The default is all statuses (order history).
  final List<OrderStatus> statuses;

  /// true = the tabs share the width equally (shipment management).
  final bool equalWidth;

  const OrderStatusFilterBar({
    super.key,
    required this.selectedStatus,
    required this.counts,
    required this.allCount,
    required this.onSelect,
    this.statuses = kOrderStatuses,
    this.equalWidth = false,
  });

  @override
  State<OrderStatusFilterBar> createState() => _OrderStatusFilterBarState();
}

class _OrderStatusFilterBarState extends State<OrderStatusFilterBar> {
  final ScrollController _controller = ScrollController();
  final GlobalKey _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(OrderStatusFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Scrolls only the tab row (not the outer vertical list) so the picked
  /// tab comes toward the middle.
  void _revealSelected() {
    if (widget.equalWidth || !mounted || !_controller.hasClients) {
      return;
    }
    final tabContext = _selectedKey.currentContext;
    if (tabContext == null) {
      return;
    }
    final object = tabContext.findRenderObject();
    if (object == null) {
      return;
    }
    final target = RenderAbstractViewport.of(object)
        .getOffsetToReveal(object, 0.5)
        .offset;
    final position = _controller.position;
    final clamped = target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _controller.animateTo(
      clamped,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <(OrderStatus?, String, int)>[
      (null, '전체', widget.allCount),
      for (final status in widget.statuses)
        (
          status,
          getOrderStatusLabel(status),
          widget.counts[status] ?? 0,
        ),
    ];
    final children = tabs.map((tab) {
      final (value, label, count) = tab;
      final isActive = widget.selectedStatus == value;
      Widget child = _StatusTab(
        label: label,
        count: count,
        isActive: isActive,
        onTap: isActive ? null : () => widget.onSelect(value),
        fill: widget.equalWidth,
      );
      if (isActive) {
        child = KeyedSubtree(key: _selectedKey, child: child);
      }
      return widget.equalWidth ? Expanded(child: child) : child;
    }).toList();
    if (widget.equalWidth) {
      return Row(children: children);
    }
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;
  final bool fill;

  const _StatusTab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: fill
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? AppColors.textStrong
                  : colorScheme.outlineVariant,
              width: isActive ? 3 : 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? AppColors.textStrong
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.brandMain
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? AppColors.foregroundLight
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
