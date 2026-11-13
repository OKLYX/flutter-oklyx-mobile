import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/manual_shipment_result.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/shipping_label_preview_row.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_bloc.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_event.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_state.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/order_sheet_bloc.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/order_sheet_event.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/order_sheet_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/order_item.dart';
import '../../data/models/cancel_reason_option.dart';
import '../../data/models/order_cancel_result.dart';
import '../bloc/elevenst_order_action_bloc.dart';
import '../bloc/elevenst_order_action_event.dart';
import '../bloc/elevenst_order_action_state.dart';
import '../bloc/lotteon_order_action_bloc.dart';
import '../bloc/lotteon_order_action_event.dart';
import '../bloc/lotteon_order_action_state.dart';
import '../bloc/order_acknowledge_bloc.dart';
import '../bloc/order_acknowledge_event.dart';
import '../bloc/order_acknowledge_state.dart';
import '../bloc/order_cancel_bloc.dart';
import '../bloc/order_cancel_event.dart';
import '../bloc/order_cancel_state.dart';
import '../bloc/order_internal_stage_bloc.dart';
import '../bloc/order_internal_stage_event.dart';
import '../bloc/order_internal_stage_state.dart';
import '../widgets/elevenst_order_sections.dart';
import '../widgets/elevenst_seller_action_sections.dart';
import '../widgets/lotteon_invoice_edit_sheet.dart';
import '../widgets/lotteon_order_sections.dart';
import '../widgets/internal_stage_badge.dart';
import '../widgets/order_next_step_card.dart';
import '../bloc/order_refresh_bloc.dart';
import '../bloc/order_refresh_event.dart';
import '../bloc/order_refresh_state.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/reserved_shipment_bloc.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/reserved_shipment_event.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/widgets/reserved_shipment_history_section.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/widgets/stored_invoice_section.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/features/packing/domain/entities/packing.dart';
import 'package:flutter_oklyn_mobile/features/packing/presentation/widgets/box_change_sheet.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import '../../../master_product/presentation/widgets/copy_id_button.dart';
import 'package:flutter_oklyn_mobile/features/stock_ledger/domain/entities/stock_enums.dart'
    show unexpandedReasonLabel;
import '../../domain/entities/order_detail.dart';
import '../bloc/order_detail_cubit.dart';

/// Shared order detail page (FEATURE_2611_07).
///
/// **Entries** (one screen, two constructors — D21 · D30):
/// - [OrderDetailPage.new] = order history card → `/orders/history/detail`
///   with the tapped [OrderItem] as go_router `extra`.
/// - [OrderDetailPage.packing] = a 「오늘 완료」 row of 「포장 작업」 →
///   `/stock/packing/order-detail` with the parcel id as `extra`.
///
/// **Data**: the order is read from the server on open (`OrderDetailCubit`,
/// D18 — replaces the old "no detail API, draw the list row as is"). A
/// missing `extra` (deep link / restart) shows a way back.
///
/// **Content** (FEATURE_2611_29 / D2 · D10 · D16): header → progress steps →
/// the next-step card → marketplace requests → tabs → 「상품 N건」 ·
/// 「결제 금액」 (with the four quantity cells) · 「주문자 · 수취인」 ·
/// 「주문 정보」 · 「송장」 (parcel chips, D29). The packing entry draws only
/// the header (no status) and the body cards, and adds [상자 변경] to packed
/// parcels (D19 ① · R17 · 2611_07 D27).
/// Each 「상품 목록」 line also shows, under its quantity, the master product ·
/// master option and the component products (photo · name · count), or only
/// the broken link's reason; the master name links to the master detail for
/// an ADMIN only (server `admin`), every component name to the product detail
/// — both pushed so their back button returns here (FEATURE_2611_15 / D1 ·
/// D3 · D5 · D7 · D8 · D19 · D20).
///
/// **UI**: the same `_InfoCard` / `_InfoRow` card layout as other detail
/// pages.
class OrderDetailPage extends StatelessWidget {
  final OrderItem? order;

  /// Parcel id of the packing entry — null when `extra` was missing.
  final int? parcelId;

  final bool _packing;

  const OrderDetailPage({super.key, this.order})
      : parcelId = null,
        _packing = false;

  const OrderDetailPage.packing({required this.parcelId, super.key})
      : order = null,
        _packing = true;

  @override
  Widget build(BuildContext context) {
    if (_packing) {
      final id = parcelId;
      return ScaffoldWithNavBar(
        title: '주문 상세',
        navBarIndex: 2,
        showBottomNavBar: false,
        // Back to the packing screen (D19).
        onBackPressed: () => context.canPop()
            ? context.pop()
            : context.go(Routes.stockPackingPath),
        body: id == null
            ? _buildMissing(context,
                label: '포장 작업으로',
                onPressed: () => context.go(Routes.stockPackingPath))
            : _PackingOrderDetail(parcelId: id),
      );
    }
    if (order == null) {
      return ScaffoldWithNavBar(
        title: '주문 상세',
        navBarIndex: 2,
        showDrawer: true,
        showBottomNavBar: false,
        onBackPressed: () => context.go(Routes.orderHistoryPath),
        body: _buildMissing(context,
            label: '주문내역으로',
            onPressed: () => context.go(Routes.orderHistoryPath)),
      );
    }
    return _buildContent(context, order!);
  }

  // No order passed as extra (deep link / restart) — offer the way back.
  Widget _buildMissing(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('주문 정보를 찾을 수 없습니다.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onPressed,
              child: Text(label),
            ),
          ],
        ),
      );

  // 송장 접수시트/발송처리 섹션이 BLoC 을 필요로 하므로 BuildContext 를 받는다.
  // order == null 분기는 조회할 order.id 가 없어 BlocProvider 자체를 만들지 않는다.
  Widget _buildContent(BuildContext context, OrderItem o) {
    final isCoupang = o.platform == 'COUPANG';
    // FEATURE_2610_17 / D28: order confirmation, single invoice and the sheet
    // are open to 11st as well, and the seller cancel opens as 11st sale
    // refusal (D61); refresh stays Coupang only (D12) while the internal
    // stage · reservation cover 11st and LotteON too (FEATURE_2611_23 / D51 ·
    // R50).
    final isElevenst = o.platform == 'ELEVENST';
    final isLotteon = o.platform == 'LOTTEON';
    final isMarketOrder = isCoupang || isElevenst || isLotteon;
    return MultiBlocProvider(
      providers: [
        // The order read on open (FEATURE_2611_07 / D18).
        BlocProvider<OrderDetailCubit>(
          create: (_) => getIt<OrderDetailCubit>()..loadByLine(o.id),
        ),
        BlocProvider<OrderSheetBloc>(create: (_) => getIt<OrderSheetBloc>()),
        // ⚠️ Made only for Coupang · 11st · LotteON orders — gating only the
        // render would call the ADMIN-only carrier API for nothing on every
        // other order.
        if (isMarketOrder)
          BlocProvider<ManualShipmentBloc>(
            create: (_) => getIt<ManualShipmentBloc>()
              ..add(LoadCarrierOptions(o.platform)),
          ),
        // Order confirmation sits in the same guard (Coupang · 11st · LotteON,
        // D20 · FEATURE_2611_23 / D16) — no idle instance for other orders.
        // ⚠️ No automatic send on entry (D4) — the event is dispatched only
        // from the button handler.
        if (isMarketOrder)
          BlocProvider<OrderAcknowledgeBloc>(
            create: (_) => getIt<OrderAcknowledgeBloc>(),
          ),
        // 11st cancel requests + seller return + the seller actions
        // (FEATURE_2610_17 / D19 · D35 · D61 ~ D67) — reads the open requests
        // and the reason lists once on entry; every write is a button.
        if (isElevenst)
          BlocProvider<ElevenstOrderActionBloc>(
            create: (_) => getIt<ElevenstOrderActionBloc>()
              ..add(ElevenstCancelRequestsRequested(o.id))
              ..add(const ElevenstChoicesRequested()),
          ),
        // LotteON cancel requests + seller cancel + delivery appointment
        // (FEATURE_2611_23 / D24 ~ D26 · D57) — reads the open requests and
        // the reason lists once on entry; every write is a button.
        if (isLotteon)
          BlocProvider<LotteonOrderActionBloc>(
            create: (_) => getIt<LotteonOrderActionBloc>()
              ..add(LotteonCancelRequestsRequested(o.id))
              ..add(const LotteonChoicesRequested()),
          ),
        // The internal acknowledge is Coupang · 11st · LotteON only
        // (FEATURE_2609_75 / D1 · FEATURE_2611_23 / D51 · R50) — same guard.
        // No automatic send on entry.
        if (isCoupang || isElevenst || isLotteon)
          BlocProvider<OrderInternalStageBloc>(
            create: (_) => getIt<OrderInternalStageBloc>(),
          ),
        // The status refresh is Coupang only — kept inside a guard
        // (2609_50 D24).
        // Outside a guard non-Coupang orders would show the button too, and it
        // always comes back unsupported.
        // ⚠️ No automatic read on entry — the event is dispatched only from the
        // button handler.
        if (isCoupang)
          BlocProvider<OrderRefreshBloc>(
            create: (_) => getIt<OrderRefreshBloc>(),
          ),
        // The Coupang order cancel is in the same guard too (the 11st cancel tab
        // is the sale refusal on `ElevenstOrderActionBloc`, FEATURE_2610_17 /
        // D61). Only the reason list is read once on creation (ADMIN only, so a
        // 403 comes here first); the send is dispatched only from the button
        // handler (D12).
        if (isCoupang)
          BlocProvider<OrderCancelBloc>(
            create: (_) =>
                getIt<OrderCancelBloc>()..add(const CancelReasonsRequested()),
          ),
        // Reserved shipment history (D30) + 「송장」(D18) — Coupang · 11st ·
        // LotteON only (FEATURE_2611_23 / D51 · R50); reads that order's
        // history · invoices once on entry, with that order's marketplace
        // carriers (D64 ④).
        if (isCoupang || isElevenst || isLotteon)
          BlocProvider<ReservedShipmentBloc>(
            create: (_) => getIt<ReservedShipmentBloc>()
              ..add(ReservedShipmentsRequested(
                  externalOrderId: o.externalOrderId, platform: o.platform)),
          ),
      ],
      child: ScaffoldWithNavBar(
        title: '주문 상세',
        navBarIndex: 2,
        showDrawer: true,
        showBottomNavBar: false,
        onBackPressed: () => context.go(Routes.orderHistoryPath),
        // Refresh = top bar icon, whatever the detail read state is
        // (FEATURE_2611_29 / D11 · D4).
        appBarActions: isCoupang ? [_RefreshAction(order: o)] : null,
        body: AppPageBody.scroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ⚠️ The detail BlocBuilders wrap only the header and the body
              // cards — wrapping the Column would rebuild even the sheet
              // section on every send and the edited parcel count would
              // jump. While reading / failed, one text takes the header's
              // place (D18).
              BlocBuilder<OrderDetailCubit, OrderDetailState>(
                builder: (context, detailState) {
                  final detail = detailState.detail;
                  if (detail == null) {
                    return _DetailStatusText(state: detailState);
                  }
                  // The tapped line as the server returned it (fallback =
                  // the list row).
                  final line = _lineOf(detail, o);
                  return _LiveOrderStatus(
                    order: line,
                    isCoupang: isCoupang,
                    isMarketOrder: isMarketOrder,
                    builder: (context, status, stage, qty) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DetailHeader(
                          detail: detail,
                          line: line,
                          status: status,
                          stage: stage,
                        ),
                        const SizedBox(height: 12),
                        _OrderProgress(status: status),
                      ],
                    ),
                  );
                },
              ),
              // Next step (FEATURE_2611_29 / D7 · D15 · R8) — drawn from the
              // list row outside the detail read, so the confirmation
              // buttons stay even when the read fails.
              _LiveOrderStatus(
                order: o,
                isCoupang: isCoupang,
                isMarketOrder: isMarketOrder,
                builder: (context, status, stage, qty) {
                  final Widget? card;
                  if (status == OrderStatus.cancelled) {
                    card = OrderNextStepCard(
                      title: '주문이 취소되었습니다',
                      body: _cancelQtyText(qty.cancel, qty.hold),
                    );
                  } else if (isMarketOrder && o.status == OrderStatus.paid) {
                    // The full-cancel gate reads the Coupang-only cancel
                    // BLoC. An 11st reserved sale takes [입고완료 처리]
                    // instead (FEATURE_2610_17 / D67).
                    card = isCoupang
                        ? _HideWhenFullyCancelled(
                            child: _AcknowledgeSection(order: o))
                        : o.reservedSale && !o.cancelled
                            ? ElevenstStockConfirmSection(order: o)
                            : _AcknowledgeSection(order: o);
                  } else {
                    final next = _kNextStepByStatus[status];
                    card = next == null
                        ? null
                        : OrderNextStepCard(title: next.$1, body: next.$2);
                  }
                  if (card == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: card,
                  );
                },
              ),
              const SizedBox(height: 12),
              // Marketplace requests (FEATURE_2611_29 / D16 · R11) — 11st ·
              // LotteON cancel requests and the 11st seller return; each
              // hides itself when empty.
              if (isElevenst) ElevenstOrderSections(order: o),
              if (isLotteon) LotteonOrderSections(order: o),
              // Sheet · shipment · cancel are used one at a time, so they
              // share side-by-side tabs.
              // ⚠️ A full cancel keeps the local status (D7) — the tabs lock
              // it from outside **without editing the section widgets**. A
              // partial cancel is not locked (D19).
              // ⚠️ Orders other than Coupang · 11st · LotteON get no
              // shipment / cancel BLoC at all (provider guard above), so
              // they skip the tabs and keep only the sheet section — a tab
              // reading a missing BLoC crashes. 11st and LotteON have no
              // Coupang cancel BLoC (D12); their cancel tab is the 11st
              // sale refusal (FEATURE_2610_17 / D61) or the LotteON seller
              // cancel (FEATURE_2611_23 / D57).
              if (isMarketOrder)
                _ActionTabs(order: o, withCancel: isCoupang)
              else
                _OrderSheetSection(order: o),
              BlocBuilder<OrderDetailCubit, OrderDetailState>(
                builder: (context, detailState) {
                  final detail = detailState.detail;
                  if (detail == null) {
                    return const SizedBox.shrink();
                  }
                  final line = _lineOf(detail, o);
                  return _LiveOrderStatus(
                    order: line,
                    isCoupang: isCoupang,
                    isMarketOrder: isMarketOrder,
                    builder: (context, status, stage, qty) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _ProductListCard(detail: detail, highlightLineId: o.id),
                        const SizedBox(height: 12),
                        _PaymentCard(line: line, qty: qty),
                        const SizedBox(height: 12),
                        _CustomerCard(detail: detail),
                        const SizedBox(height: 12),
                        _orderInfoCard(detail, line: line),
                        const SizedBox(height: 12),
                        // No [상자 변경] from the order history (D27).
                        _ParcelListCard(
                          state: detailState,
                          cancelled: status == OrderStatus.cancelled,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live status of one order line (FEATURE_2611_29 / R7) — draws nothing
/// itself: it hands the shown status, the internal stage badge and the four
/// quantities to [builder], so the header, the progress steps, the next-step
/// card and the payment card read the same values.
/// For a Coupang · 11st · LotteON order the sends made on this screen move
/// them without a refetch — shipment gets `resultStatus: SHIPPED` from the
/// server (2609_11 D4), a successful order confirmation reads as
/// [OrderStatus.preparing], and a Coupang cancel result overrides the status
/// and the quantities (D15).
class _LiveOrderStatus extends StatelessWidget {
  final OrderItem order;
  final Widget Function(
    BuildContext context,
    OrderStatus status,
    InternalStage? stage,
    ({int cancel, int hold, int purchasable}) qty,
  ) builder;
  final bool isCoupang;
  final bool isMarketOrder;

  const _LiveOrderStatus({
    required this.order,
    required this.builder,
    required this.isCoupang,
    required this.isMarketOrder,
  });

  @override
  Widget build(BuildContext context) {
    final listQty = (
      cancel: order.cancelCount,
      hold: order.holdCount,
      purchasable: order.purchasableQty,
    );
    if (!isMarketOrder) {
      return builder(context, order.status, order.internalStage, listQty);
    }
    if (!isCoupang) {
      // 11st · LotteON have no cancel BLoC (FEATURE_2610_17 / D12 ·
      // FEATURE_2611_23 / D57) — only the shipment and confirmation results
      // move the status. The badge follows the internal-stage BLoC like
      // Coupang (FEATURE_2611_23 / D51).
      return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
        builder: (context, manual) =>
            BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
          builder: (context, ack) =>
              BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
            builder: (context, internal) {
              final acknowledged =
                  ack.result != null && ack.result!.succeeded > 0;
              final status = manual.result?.resultStatus ??
                  (acknowledged ? OrderStatus.preparing : order.status);
              final shownStage = acknowledged
                  ? null
                  : _AcknowledgeSection._internalMarked(internal)
                      ? InternalStage.internalPreparing
                      : order.internalStage;
              return builder(context, status, shownStage, listQty);
            },
          ),
        ),
      );
    }
    // Shipment (SHIPPED) is a later step than confirmation (PREPARING) — the
    // later step wins. A cancel is later still, so it wins from the
    // outermost (2609_25 D14).
    // ⚠️ Confirmation success = `succeeded > 0`. A Coupang rejection is also
    // 200 + failed, so judging by `result != null` alone shows a failed
    // order as preparing (D15).
    return BlocBuilder<OrderCancelBloc, OrderCancelState>(
      builder: (context, cancel) =>
          BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
        builder: (context, manual) =>
            BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
          builder: (context, ack) =>
              BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
            builder: (context, internal) {
              final acknowledged =
                  ack.result != null && ack.result!.succeeded > 0;
              final status = _isFullyCancelledByResult(cancel.result)
                  ? OrderStatus.cancelled
                  : (manual.result?.resultStatus ??
                      (acknowledged ? OrderStatus.preparing : order.status));
              // Badge = the result of what was just done on this screen
              // wins — same as the web `shownStage` (D9). A successful
              // confirmation cleared the internal stage on the server
              // (D14) → no badge.
              final shownStage = acknowledged
                  ? null
                  : _AcknowledgeSection._internalMarked(internal)
                      ? InternalStage.internalPreparing
                      : order.internalStage;
              // Quantities = the line values overridden by the cancel just
              // made here — same rule as the web `quantities`.
              final cancelledLine = cancel.result?.cancelled.firstOrNull;
              final qty = (
                cancel: cancelledLine?.resultCancelCount
                    ?? order.cancelCount,
                hold: cancelledLine?.resultHoldCount ?? order.holdCount,
                purchasable: cancelledLine?.resultPurchasableQty
                    ?? order.purchasableQty,
              );
              return builder(context, status, shownStage, qty);
            },
          ),
        ),
      ),
    );
  }
}

/// Order detail header in three lines (FEATURE_2611_29 / D4 · R4 · R19):
/// marketplace badge · alias + status badge · internal stage badge / order
/// number + copy / paid time + relative time (paid · preparing only, R6) +
/// order amount (R15, left out when unknown). [line] null = packing entry
/// (no amount); [status] null = no status badge and no relative time.
class _DetailHeader extends StatelessWidget {
  final OrderDetail detail;
  final OrderItem? line;
  final OrderStatus? status;
  final InternalStage? stage;

  const _DetailHeader({
    required this.detail,
    required this.line,
    required this.status,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget pill(String text, Color background, Color foreground) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        );
    final shownStatus = status;
    final tapped = line;
    final alias = detail.accountAlias?.trim() ?? '';
    final market =
        detail.platform == null ? '-' : platformName(detail.platform!);
    final recent = (shownStatus == OrderStatus.paid ||
            shownStatus == OrderStatus.preparing) &&
        detail.paidAt != null;
    final net = tapped == null ? null : _orderNetAmount(tapped);
    final paidText = '결제 ${formatPaidShort(detail.paidAt)}'
        '${recent ? ' · ${formatMarketRelativeTime(detail.paidAt)}' : ''}'
        '${net == null ? '' : ' · ${_amountText(net)}'}';
    final cancelled = shownStatus == OrderStatus.cancelled;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pill(market, scheme.surfaceContainerHighest, scheme.onSurface),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alias,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (shownStatus != null && tapped != null) ...[
                const SizedBox(width: 6),
                pill(
                  _statusText(tapped, shownStatus),
                  cancelled ? scheme.errorContainer : AppColors.infoSurface,
                  cancelled
                      ? scheme.onErrorContainer
                      : AppColors.infoForeground,
                ),
              ],
              if (stage != null) ...[
                const SizedBox(width: 4),
                InternalStageBadge(stage: stage),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  detail.externalOrderId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CopyIdButton(value: detail.externalOrderId),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            paidText,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Five progress steps (FEATURE_2611_29 / R5 · D19 ⑩): the current step =
/// filled dot + bold text, a passed step = filled dot, a later step = empty
/// dot. A fully cancelled order shows 「취소됨」 on the second step; an
/// unknown status shows every step as later. No times.
class _OrderProgress extends StatelessWidget {
  final OrderStatus status;

  const _OrderProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const steps = [
      OrderStatus.paid,
      OrderStatus.preparing,
      OrderStatus.shipped,
      OrderStatus.delivering,
      OrderStatus.delivered,
    ];
    final cancelled = status == OrderStatus.cancelled;
    // A cancelled order counts the paid step as passed.
    final current = cancelled ? 1 : steps.indexOf(status);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final isCancelStep = cancelled && i == 1;
                  final isCurrent = !cancelled && i == current;
                  final filled = current >= 0 && i <= current;
                  final textColor = isCancelStep
                      ? scheme.error
                      : isCurrent
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant;
                  return Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCancelStep
                              ? scheme.error
                              : filled
                                  ? AppColors.brandMain
                                  : null,
                          border: filled
                              ? null
                              : Border.all(color: scheme.outline),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCancelStep ? '취소됨' : getOrderStatusLabel(steps[i]),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : null,
                          color: textColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Next-step card texts by the shown status (FEATURE_2611_29 / D15 · PLAN
/// §3-2); a status not listed gets no card.
const Map<OrderStatus, (String, String)> _kNextStepByStatus = {
  OrderStatus.shipped: (
    '택배 집하 대기',
    '택배사가 집하하면 배송중으로 바뀝니다. '
        '송장 수정 탭에서 송장을 고칠 수 있습니다.',
  ),
  OrderStatus.delivering: ('배송 중', '고객에게 가는 중입니다.'),
  OrderStatus.delivered: ('배송 완료', '처리할 작업이 없습니다.'),
};

/// Tab lock reasons (FEATURE_2611_29 / R9).
const _kTabLockCanceled = '취소된 주문';
const _kTabLockShippedCancel = '발송 후에는 취소할 수 없습니다(반품으로 처리)';

/// 이 화면에서 방금 낸 취소가 **전량취소**였는지 — 정보 카드 상태 행과 발주/발송 섹션 숨김이
/// 같은 판정을 쓰도록 한 곳에 둔다. 서버가 전량취소 라인에만 `CANCELLED` 를 내려준다(D14).
///
/// ⚠️ 목록의 `order.cancelled`(서버 판정, D26)와 근거가 다르다 — 이쪽은 **방금 낸 취소 결과**
/// 기준의 낙관적 갱신이라 아직 재조회하지 않은 시점을 메운다. 둘을 합치지 말 것.
bool _isFullyCancelledByResult(OrderCancelResult? result) =>
    result != null &&
    result.cancelled.any((l) => l.resultStatus == OrderStatus.cancelled);

/// Status row text. The backend folds `NONE_TRACKING` (seller's own delivery)
/// into `SHIPPED` (D5), so the status alone cannot tell it is untracked —
/// **only this detail row** reads the raw value and adds it in brackets. An
/// 11st reserved sale adds 「11번가 예약판매」 from the server flag
/// `reservedSale` (FEATURE_2610_17 / D67).
///
/// ❌ Do not bring the untracked mark back to the list card or the status chips
/// (the chips are the six neutral statuses only).
String _statusText(OrderItem o, OrderStatus status) {
  final label = getOrderStatusLabel(status);
  final untracked =
      status == OrderStatus.shipped && o.platformStatus == 'NONE_TRACKING';
  final shown = untracked ? '$label (추적불가)' : label;
  return o.reservedSale ? '$shown · $kElevenstReservedLabel' : shown;
}

/// 금액 행 문구. null 은 **'—'** 다 — 0 으로 표시하면 "할인 없음"과 "모름"이 같아 보인다(D9).
String _amountText(int? amount) =>
    amount == null ? '—' : '${_amountFormat.format(amount)}원';

/// Order amount (R15) — null = unknown, never 0 (2609_26 D9 · D10).
int? _orderNetAmount(OrderItem line) {
  final amount = line.lineAmount;
  final discount = line.discountAmount;
  if (amount == null || discount == null) {
    return null;
  }
  return amount - discount;
}

/// Cancel quantity text of the cancelled card and the cancel tab
/// (FEATURE_2611_29 / D15) — the hold count only when above 0.
String _cancelQtyText(int cancel, int hold) =>
    hold > 0 ? '취소 수량 $cancel개 · 보류 $hold개' : '취소 수량 $cancel개';

final _amountFormat = NumberFormat('###,##0', 'ko_KR');

/// 전량취소되면 감출 섹션 래퍼 — 발주처리·발송처리 위젯 **내부를 고치지 않기 위한** 바깥 게이트.
/// 부분취소는 잔여 수량을 그대로 발송해야 하므로 감추지 않는다(D19).
class _HideWhenFullyCancelled extends StatelessWidget {
  final Widget child;

  const _HideWhenFullyCancelled({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCancelBloc, OrderCancelState>(
      buildWhen: (prev, curr) => prev.result != curr.result,
      builder: (context, state) => _isFullyCancelledByResult(state.result)
          ? const SizedBox.shrink()
          : child,
    );
  }
}

/// 정보 카드 (제목 + 라벨/값 행 목록). 다른 상세 페이지와 동일한 스타일.
class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  /// Widget right of the value — the copy button of an ID (FEATURE_2611_29
  /// / R18). null = the value only.
  final Widget? trailing;

  const _InfoRow(this.label, this.value, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
    final extra = trailing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          if (extra == null)
            valueText
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [valueText, extra],
            ),
        ],
      ),
    );
  }
}

/// 「주문 정보」 card (FEATURE_2611_29 / D8 · R18): seller · item ID · box ID
/// (each with a copy button when it has a value, 「-」 otherwise) · paid
/// date. [line] = the tapped line; null = packing entry (no ID rows).
_InfoCard _orderInfoCard(OrderDetail detail, {OrderItem? line}) {
  final itemId = line?.externalItemId ?? '';
  final boxId = line?.externalBoxId ?? '';
  return _InfoCard(
    title: '주문 정보',
    rows: [
      _InfoRow('판매자', detail.sellerName ?? '-'),
      if (line != null) ...[
        _InfoRow(
          '아이템 ID',
          itemId.isEmpty ? '-' : itemId,
          trailing: itemId.isEmpty ? null : CopyIdButton(value: itemId),
        ),
        _InfoRow(
          '박스 ID',
          boxId.isEmpty ? '-' : boxId,
          trailing: boxId.isEmpty ? null : CopyIdButton(value: boxId),
        ),
      ],
      _InfoRow('결제일', formatOrderDateTime(detail.paidAt)),
    ],
  );
}

/// 「결제 금액」 card with the four quantity cells (FEATURE_2611_29 / D8 ·
/// R15 · D19 ④). [qty] = the cancel · hold · purchasable values from
/// [_LiveOrderStatus] (same as the web `quantities`).
class _PaymentCard extends StatelessWidget {
  final OrderItem line;
  final ({int cancel, int hold, int purchasable}) qty;

  const _PaymentCard({required this.line, required this.qty});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final discount = line.discountAmount;
    final platformDiscount = line.platformDiscountAmount;
    final net = _orderNetAmount(line);
    final applied = discount != null && discount > 0 && net != null
        ? ' · 할인 적용'
        : '';
    Widget cell(String label, int value, {bool highlight = false}) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.successSurface
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: highlight
                        ? AppColors.successForeground
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: highlight ? AppColors.successForeground : null,
                  ),
                ),
              ],
            ),
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '결제 금액',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            '단가 × 수량',
            line.unitPrice == null
                ? '—'
                : '${_amountText(line.unitPrice)} × ${line.orderCount}',
          ),
          _InfoRow(
            '할인',
            discount == null
                ? '—'
                : discount == 0
                    ? '없음'
                    : _amountText(discount),
          ),
          if (platformDiscount != null && platformDiscount > 0)
            _InfoRow('플랫폼 부담 할인', _amountText(platformDiscount)),
          _InfoRow('주문금액', '${_amountText(net)}$applied'),
          const SizedBox(height: 12),
          Row(
            children: [
              cell('주문', line.orderCount),
              const SizedBox(width: 8),
              cell('취소', qty.cancel),
              const SizedBox(width: 8),
              cell('보류', qty.hold),
              const SizedBox(width: 8),
              cell('구매가능', qty.purchasable, highlight: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// 「주문자 · 수취인」 card (FEATURE_2611_29 / D8 · R15): one name + a
/// same-person note when both trimmed names are non-empty and equal,
/// otherwise two rows (empty name = 「-」).
class _CustomerCard extends StatelessWidget {
  final OrderDetail detail;

  const _CustomerCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final orderer = detail.ordererName?.trim() ?? '';
    final receiver = detail.receiverName?.trim() ?? '';
    final same =
        orderer.isNotEmpty && receiver.isNotEmpty && orderer == receiver;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주문자 · 수취인',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (same) ...[
            Text(
              orderer,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '수취인 = 주문자와 동일',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            _InfoRow('주문자', orderer.isEmpty ? '-' : orderer),
            _InfoRow('수취인', receiver.isEmpty ? '-' : receiver),
          ],
        ],
      ),
    );
  }
}

/// The tapped line inside the server answer, or the list row when missing.
OrderItem _lineOf(OrderDetail detail, OrderItem order) {
  for (final line in detail.lines) {
    if (line.id == order.id) {
      return line;
    }
  }
  return order;
}

/// The one text drawn instead of the cards while reading (only before the
/// first answer) or after a failed read (D18 · R8).
class _DetailStatusText extends StatelessWidget {
  final OrderDetailState state;

  const _DetailStatusText({required this.state});

  @override
  Widget build(BuildContext context) {
    final failed = !state.loading && state.error.isNotEmpty;
    return AppCard(
      child: Text(
        failed ? state.error : '불러오는 중...',
        style: failed
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
    );
  }
}

/// Photo 40×40 — gray box when there is no product (R11).
class _Thumb extends StatelessWidget {
  final int? productId;

  const _Thumb({required this.productId});

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final id = productId;
    if (id != null) {
      return ProductThumbnail(productId: id, size: _size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: _size,
        height: _size,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

/// 「상품 N건」 card — every line of the order (D13 · R10 · R16). Only the line
/// with [highlightLineId] gets the highlight background (D33 · R9); null = no
/// highlighted line (packing entry).
class _ProductListCard extends StatelessWidget {
  final OrderDetail detail;
  final int? highlightLineId;

  const _ProductListCard({required this.detail, this.highlightLineId});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '상품 ${detail.lines.length}건',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final line in detail.lines)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: line.id == highlightLineId
                    ? scheme.primaryContainer
                    : null,
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(productId: line.thumbnailProductId),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.itemName ?? '-',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '수량 ${line.orderCount}',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                        if (detail.lineMasterOf(line.id) case final master?)
                          _LineMasterInfo(
                            master: master,
                            admin: detail.admin,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    getOrderStatusLabel(line.status),
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Where one 「상품 N건」 line comes from (FEATURE_2611_15 / D3 · D5 · D8 ·
/// D19 · D20): linked = 「판매상품 마스터 {master} · {option}」 + 「구성상품」 +
/// one row per component (photo · name · 「× {count}」); broken = the reason
/// text only. The master name is a link only when [admin]; component names
/// are links for everyone. Links push (no `go`) so back returns here (D7).
class _LineMasterInfo extends StatelessWidget {
  final OrderLineMaster master;
  final bool admin;

  const _LineMasterInfo({required this.master, required this.admin});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gray = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final link = TextStyle(
      fontSize: 12,
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    );
    final reason = master.unexpandedReason;
    if (reason != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          unexpandedReasonLabel(reason),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.warningForeground,
          ),
        ),
      );
    }
    final masterName = master.masterProductName ?? '-';
    final masterId = master.masterProductId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('판매상품 마스터 ', style: gray),
            if (admin && masterId != null)
              _LinkText(
                text: masterName,
                style: link,
                onTap: () => context.pushNamed(
                  Routes.masterProductDetail,
                  pathParameters: {'id': '$masterId'},
                  extra: const MasterDetailArgs(fromOrderDetail: true),
                ),
              )
            else
              Text(masterName, style: gray),
            Text(' · ${master.masterOptionName ?? '-'}', style: gray),
          ],
        ),
        const SizedBox(height: 4),
        Text('구성상품', style: gray),
        for (final product in master.products)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                _Thumb(productId: product.productId),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _LinkText(
                      text: product.productName,
                      style: link,
                      onTap: () => context.pushNamed(
                        Routes.productDetail,
                        pathParameters: {'productId': '${product.productId}'},
                        extra: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('× ${product.quantity}', style: gray),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tappable link text of [_LineMasterInfo] — no button padding so it sits in
/// the line like plain text.
class _LinkText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onTap;

  const _LinkText({
    required this.text,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        onPressed: onTap,
        child: Text(text, style: style),
      );
}

/// 「송장」 card — parcel chips, the shown chip's content below (D23 · D25 ·
/// D28 · D29 · D36 · 2611_29 R16). [cancelled] = the empty text says the
/// order was cancelled. [onChangeBox] set = packing entry: a 「포장 완료」
/// parcel gets [상자 변경] (D27).
class _ParcelListCard extends StatelessWidget {
  final OrderDetailState state;
  final void Function(OrderDetailParcel parcel)? onChangeBox;
  final bool cancelled;

  const _ParcelListCard({
    required this.state,
    this.onChangeBox,
    this.cancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final parcels = state.detail?.parcels ?? const <OrderDetailParcel>[];
    final shown = state.shownParcel;
    final changeBox = onChangeBox;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '송장',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (parcels.isEmpty || shown == null)
            Text(
              cancelled ? '취소된 주문이라 송장이 없습니다.' : '아직 송장이 없습니다.',
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final parcel in parcels)
                  ChoiceChip(
                    label: Text(parcel.chipLabel),
                    selected: parcel.parcelId == shown.parcelId,
                    onSelected: (_) => context
                        .read<OrderDetailCubit>()
                        .selectParcel(parcel.parcelId),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow('택배사', shown.carrierName ?? '-'),
            _InfoRow('송장번호', shown.invoiceNumber),
            _InfoRow('상태', shown.statusLabel),
            _InfoRow(
              '처리 시각',
              shown.packedAt == null
                  ? '-'
                  : formatOrderDateTime(shown.packedAt),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _InfoRow('상자', shown.boxName ?? '-')),
                if (changeBox != null && shown.status == ParcelStatus.packed)
                  OutlinedButton(
                    onPressed: () => changeBox(shown),
                    child: const Text('상자 변경'),
                  ),
              ],
            ),
            _ParcelItems(items: shown.items),
          ],
        ],
      ),
    );
  }
}

/// 「담은 물품」 of the shown parcel — photo · name · 「수량 {n}」, 「-」 when
/// empty (D23 · D37).
class _ParcelItems extends StatelessWidget {
  final List<OrderDetailParcelItem> items;

  const _ParcelItems({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '담은 물품',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        if (items.isEmpty)
          const Text(
            '-',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          )
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  _Thumb(productId: item.productId),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.productName ?? '-',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '수량 ${item.quantity}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Packing entry body (FEATURE_2611_29 / R17): header (no status) →
/// 「상품 N건」 (no highlighted line) → 「주문자 · 수취인」 → 「주문 정보」 →
/// 「송장」 opened on [parcelId]
/// (D28). None of the order history action BLoCs are made here.
class _PackingOrderDetail extends StatelessWidget {
  final int parcelId;

  const _PackingOrderDetail({required this.parcelId});

  @override
  Widget build(BuildContext context) => BlocProvider<OrderDetailCubit>(
        create: (_) => getIt<OrderDetailCubit>()..loadByParcel(parcelId),
        child: AppPageBody.scroll(
          child: BlocBuilder<OrderDetailCubit, OrderDetailState>(
            builder: (context, state) {
              final detail = state.detail;
              if (detail == null) {
                return _DetailStatusText(state: state);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailHeader(
                    detail: detail,
                    line: null,
                    status: null,
                    stage: null,
                  ),
                  const SizedBox(height: 12),
                  _ProductListCard(detail: detail),
                  const SizedBox(height: 12),
                  _CustomerCard(detail: detail),
                  const SizedBox(height: 12),
                  _orderInfoCard(detail),
                  const SizedBox(height: 12),
                  _ParcelListCard(
                    state: state,
                    onChangeBox: (parcel) => _changeBox(context, parcel),
                  ),
                ],
              );
            },
          ),
        ),
      );

  /// [상자 변경] → the shared box sheet → on success the toast here and the
  /// same read again with the picked chip kept (D7 · D28 · R15).
  Future<void> _changeBox(
    BuildContext context,
    OrderDetailParcel parcel,
  ) async {
    final cubit = context.read<OrderDetailCubit>();
    final box = await showBoxChangeSheet(context,
        parcelId: parcel.parcelId, selectedPackageId: parcel.boxPackageId);
    if (box == null || !context.mounted) {
      return;
    }
    showSuccessToast(context, '상자를 바꿨습니다 — ${box.type}');
    await cubit.reload();
  }
}

/// Label sheet / shipment / order cancel switch tabs — three equal-width
/// tabs ([_DetailTabBar], FEATURE_2611_29 / D5 · R9).
///
/// **Purpose**: splits the actions used one at a time on an order into tabs.
/// From the left: sheet · shipment · cancel. The first tab is shipment —
/// most orders end in a shipment, and a cancel cannot be undone — except a
/// cancelled order, which opens on the cancel tab (R10).
/// An 11st order ([withCancel] false) gets its cancel tab from the 11st sale
/// refusal (FEATURE_2610_17 / D61) instead of the Coupang cancel section; a
/// LotteON order ([withCancel] false too) from the LotteON seller cancel
/// (FEATURE_2611_23 / D57).
/// ⚠️ The sheet lookup is a live marketplace call, so opening the tab does not
/// run it (only the button inside the section does).
///
/// ⚠️ The panels stay alive with [Offstage] — switching tabs keeps the typed
/// invoice number and cancel quantity (each section holds its state inside
/// the widget). [IndexedStack] is not used: it leaves the hidden side's height
/// as empty space.
/// ⚠️ A tab that cannot be used is kept **disabled**, not removed — removing it
/// hides why it is gone. The permission (403) and status gates already live in
/// each section; here they only decide whether a tab is enabled.
class _ActionTabs extends StatefulWidget {
  final OrderItem order;

  /// false = 11st · LotteON — no Coupang cancel BLoC (FEATURE_2610_17 / D12);
  /// the cancel tab is the 11st sale refusal on `ElevenstOrderActionBloc`
  /// (D61) or the LotteON seller cancel on `LotteonOrderActionBloc`
  /// (FEATURE_2611_23 / D57).
  final bool withCancel;

  const _ActionTabs({required this.order, required this.withCancel});

  @override
  State<_ActionTabs> createState() => _ActionTabsState();
}

enum _ActionTab { sheet, shipment, cancel }

class _ActionTabsState extends State<_ActionTabs> {
  _ActionTab _selected = _ActionTab.shipment; // first tab, see initState

  @override
  void initState() {
    super.initState();
    if (widget.order.cancelled) {
      _selected = _ActionTab.cancel;
    }
  }

  bool get _isLotteon => widget.order.platform == 'LOTTEON';

  @override
  Widget build(BuildContext context) {
    if (!widget.withCancel) {
      if (_isLotteon) {
        return BlocBuilder<LotteonOrderActionBloc, LotteonOrderActionState>(
          buildWhen: (p, c) => p.forbidden != c.forbidden,
          builder: (context, lotteon) =>
              _buildTabs(context, null, lotteon.forbidden),
        );
      }
      return BlocBuilder<ElevenstOrderActionBloc, ElevenstOrderActionState>(
        buildWhen: (p, c) => p.forbidden != c.forbidden,
        builder: (context, elevenst) =>
            _buildTabs(context, null, elevenst.forbidden),
      );
    }
    return BlocBuilder<OrderCancelBloc, OrderCancelState>(
      builder: (context, cancel) => _buildTabs(context, cancel, false),
    );
  }

  /// [cancel] = null for an 11st or LotteON order — there is no cancel BLoC
  /// to read.
  /// [marketForbidden] = an 11st or LotteON write came back 403
  /// (D61 · FEATURE_2611_23 / D57 cancel tab gate).
  Widget _buildTabs(
      BuildContext context, OrderCancelState? cancel, bool marketForbidden) {
    final order = widget.order;
    // FEATURE_2610_17 / D61 · FEATURE_2611_23 / D57: 11st sale refusal or
    // LotteON seller cancel — paid / preparing, not fully cancelled, and no
    // 403 from a write of that marketplace.
    final marketCancel = cancel == null &&
        !marketForbidden &&
        !order.cancelled &&
        (order.status == OrderStatus.paid ||
            order.status == OrderStatus.preparing);
    return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
        builder: (context, manual) {
          // 섹션 위젯 안 게이트와 같은 판정을 밖에서 한 번 더 쓴다(사본이 아니라 같은 근거).
          final fullyCancelled =
              cancel != null && _isFullyCancelledByResult(cancel.result);
          final canShip = !manual.optionsForbidden && !fullyCancelled;
          final canCancel = cancel == null
              ? marketCancel
              : !cancel.forbidden &&
                  (order.status == OrderStatus.paid ||
                      order.status == OrderStatus.preparing);
          // A fully cancelled order (on open or by the cancel just made)
          // locks the sheet and shipment tabs (FEATURE_2611_29 / R10); the
          // cancel tab of an order cancelled on open shows the cancel text.
          // Permission (403) and platform notices stay inside the sections.
          final fully = widget.order.cancelled ||
              (cancel != null && _isFullyCancelledByResult(cancel.result));
          final available = {
            _ActionTab.sheet: !fully,
            _ActionTab.shipment: canShip && !widget.order.cancelled,
            _ActionTab.cancel: widget.order.cancelled || canCancel,
          };
          final labels = {
            _ActionTab.sheet: '송장시트',
            _ActionTab.shipment:
                isAlreadyShipped(order.status) ? '송장 수정' : '발송처리',
            _ActionTab.cancel:
                widget.withCancel && order.status == OrderStatus.preparing
                    ? '출고중지'
                    : '취소',
          };
          final lockReasons = {
            _ActionTab.sheet:
                !available[_ActionTab.sheet]! && fully ? _kTabLockCanceled : '',
            _ActionTab.shipment: !available[_ActionTab.shipment]! && fully
                ? _kTabLockCanceled
                : '',
            _ActionTab.cancel: !available[_ActionTab.cancel]! &&
                    isAlreadyShipped(order.status)
                ? _kTabLockShippedCancel
                : '',
          };

          // 고른 탭을 쓸 수 없으면 왼쪽부터 첫 번째로 쓸 수 있는 탭을 보여준다 —
          // 파생값이라 setState 로 되돌리지 않는다.
          final selected = available[_selected]!
              ? _selected
              : _ActionTab.values.firstWhere((t) => available[t]!,
                  orElse: () => _selected);

          final Widget cancelPanel;
          if (widget.order.cancelled) {
            final qtyText =
                _cancelQtyText(order.cancelCount, order.holdCount);
            cancelPanel = AppCard(
              child: Text('이미 취소된 주문입니다 · $qtyText'),
            );
          } else {
            cancelPanel = cancel == null
                ? (_isLotteon
                    ? LotteonSellerCancelSection(order: order)
                    : ElevenstSaleRefusalSection(order: order))
                : _CancelSection(order: order);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailTabBar(
                selected: selected,
                labels: labels,
                available: available,
                lockReasons: lockReasons,
                onSelect: (tab) => setState(() => _selected = tab),
              ),
              const SizedBox(height: 12),
              Offstage(
                offstage: selected != _ActionTab.sheet,
                child: _OrderSheetSection(order: order),
              ),
              Offstage(
                offstage: selected != _ActionTab.shipment,
                // 내부 단계 주문(FEATURE_2609_75 / D27)은 입력 대신 안내 — 「송장」 + [저장된 송장으로 발송].
                // Same rule as the header badge ([_LiveOrderStatus] shown
                // stage); the server rejects with the same text (400).
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                cancel == null
                    ? (_isLotteon
                        ? _LotteonShipmentGate(order: order)
                        : _ElevenstShipmentGate(order: order))
                    : BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
                  builder: (context, ack) => BlocBuilder<OrderInternalStageBloc,
                      OrderInternalStageState>(
                    builder: (context, internal) {
                      final acknowledged =
                          ack.result != null && ack.result!.succeeded > 0;
                      final internalStage = !acknowledged &&
                          (_AcknowledgeSection._internalMarked(internal) ||
                              order.internalStage != null);
                      if (!internalStage) {
                        return _ManualShipmentSection(order: order);
                      }
                      return const AppCard(
                          child: Text(
                            '내부 단계 주문은 여기서 발송처리할 수 없습니다. 「송장」에 송장을 저장한 뒤 출고관리의 [저장된 송장으로 발송]을 누르세요',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warningForeground,
                            ),
                          ),
                      );
                    },
                  ),
                ),
                    // 「송장」 (D18) — draws nothing when the order has no
                    // internal-stage (paid) shipment, i.e. most orders. When
                    // [내부 발주처리] · [발주처리] succeed here, the order's
                    // invoices and history are read again, so 「송장」 shows /
                    // hides without reopening (same as the web 05 `shownStage`
                    // re-render, D9). In this tab since FEATURE_2611_29 / D16.
                    MultiBlocListener(
                      listeners: [
                        BlocListener<OrderInternalStageBloc,
                            OrderInternalStageState>(
                          listenWhen: (p, c) =>
                              c.result != null && p.result != c.result,
                          listener: (context, _) => context
                              .read<ReservedShipmentBloc>()
                              .add(ReservedShipmentsRequested(
                                  externalOrderId: order.externalOrderId)),
                        ),
                        BlocListener<OrderAcknowledgeBloc,
                            OrderAcknowledgeState>(
                          listenWhen: (p, c) =>
                              c.result != null && p.result != c.result,
                          listener: (context, _) => context
                              .read<ReservedShipmentBloc>()
                              .add(ReservedShipmentsRequested(
                                  externalOrderId: order.externalOrderId)),
                        ),
                      ],
                      child: const StoredInvoiceSection(),
                    ),
                    // Reserved shipment history (D30) — draws nothing when
                    // there is none (most orders).
                    const ReservedShipmentHistorySection(),
                  ],
                ),
              ),
              Offstage(
                offstage: selected != _ActionTab.cancel,
                child: cancelPanel,
              ),
            ],
          );
        },
    );
  }
}

/// Three equal-width order detail tabs (FEATURE_2611_29 / D5 · R9 · R19).
/// A locked tab keeps its place with gray text — the cancel tab stays red
/// even when locked (D1) — and has no lock icon; tapping it shows its
/// [lockReasons] text (when not empty) as a notice toast and does not
/// switch. The selected tab gets a 3px line below.
class _DetailTabBar extends StatelessWidget {
  final _ActionTab selected;
  final Map<_ActionTab, String> labels;
  final Map<_ActionTab, bool> available;
  final Map<_ActionTab, String> lockReasons;
  final ValueChanged<_ActionTab> onSelect;

  const _DetailTabBar({
    required this.selected,
    required this.labels,
    required this.available,
    required this.lockReasons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final tab in _ActionTab.values)
          Expanded(
            child: InkWell(
              onTap: () {
                if (available[tab]!) {
                  onSelect(tab);
                  return;
                }
                final reason = lockReasons[tab] ?? '';
                if (reason.isNotEmpty) {
                  showNoticeToast(context, reason);
                }
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      labels[tab]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: tab == selected ? FontWeight.bold : null,
                        color: tab == _ActionTab.cancel
                            ? scheme.error
                            : available[tab]!
                                ? scheme.onSurface
                                : scheme.outline,
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    color: tab != selected
                        ? null
                        : tab == _ActionTab.cancel
                            ? scheme.error
                            : AppColors.brandMain,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Internal-stage notice on top of the 11st shipment tab (FEATURE_2611_23 /
/// R4) — same text and same rule as the Coupang shipment tab: shown when this
/// screen just marked the order internal or the server says it has an
/// internal stage.
class _InternalStageShipmentNotice extends StatelessWidget {
  final OrderItem order;

  const _InternalStageShipmentNotice({required this.order});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
        builder: (context, internal) {
          if (!_AcknowledgeSection._internalMarked(internal) &&
              order.internalStage == null) {
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Text(
                '내부 단계 주문은 여기서 발송처리할 수 없습니다. '
                '「송장」에 송장을 저장한 뒤 출고관리의 '
                '[저장된 송장으로 발송]을 누르세요',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warningForeground,
                ),
              ),
            ),
          );
        },
      );
}

/// Shipment tab of an 11st order (FEATURE_2610_17 / D20 · D21): a paid order
/// needs [발주처리] first, and 11st has no invoice-update API — both show a
/// notice instead of the form. A confirmation made on this screen opens the
/// form without a refetch (same `succeeded > 0` rule as [_LiveOrderStatus]).
/// A visit-pickup order shows [방문수령 완료] instead, from paid on (D66); the
/// form picks one of three ways to send (D64); a paid / preparing order also
/// gets [발송지연 안내] below (D63).
class _ElevenstShipmentGate extends StatelessWidget {
  final OrderItem order;

  const _ElevenstShipmentGate({required this.order});

  @override
  Widget build(BuildContext context) {
    final openStatus = order.status == OrderStatus.paid ||
        order.status == OrderStatus.preparing;
    return BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
      builder: (context, ack) {
        final acknowledged = ack.result != null && ack.result!.succeeded > 0;
        final String? notice = order.status == OrderStatus.paid && !acknowledged
            ? '11번가 주문은 [발주처리] 뒤에 송장을 등록할 수 있습니다.'
            : isAlreadyShipped(order.status)
                ? '11번가는 송장 수정을 지원하지 않습니다. 11번가 셀러오피스에서 고쳐 주세요.'
                : null;
        final Widget body = order.visitPickup && openStatus
            ? ElevenstVisitPickupSection(order: order)
            : notice == null
                ? _ElevenstShipmentModes(order: order)
                : AppCard(
                    child: Text(
                      notice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warningForeground,
                      ),
                    ),
                  );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!acknowledged) _InternalStageShipmentNotice(order: order),
            body,
            if (openStatus) ElevenstDeliveryDelaySection(order: order),
          ],
        );
      },
    );
  }
}

/// Shipment tab of a LotteON order (FEATURE_2611_23 / D18 · D19 · D96 · R51):
/// an internal-stage order shows only the internal notice; a paid order needs
/// [발주처리] first (a confirmation made on this screen opens the form without
/// a refetch); a preparing order gets the one-invoice form; a shipped order
/// gets [송장 수정하기], which opens the LotteON 「송장 수정」 sheet. A paid /
/// preparing order also gets [발송 약정일 안내] below (R55).
class _LotteonShipmentGate extends StatelessWidget {
  final OrderItem order;

  const _LotteonShipmentGate({required this.order});

  @override
  Widget build(BuildContext context) {
    final openStatus = order.status == OrderStatus.paid ||
        order.status == OrderStatus.preparing;
    return BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
      builder: (context, ack) {
        final acknowledged = ack.result != null && ack.result!.succeeded > 0;
        // ignore: omit_local_variable_types
        final String? notice = order.status == OrderStatus.paid && !acknowledged
            ? '롯데ON 주문은 [발주처리] 뒤에 송장을 등록할 수 있습니다.'
            : null;
        return BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
          builder: (context, internal) {
            final internalStage = !acknowledged &&
                (_AcknowledgeSection._internalMarked(internal) ||
                    order.internalStage != null);
            final body = internalStage
                ? null
                : notice != null
                    ? AppCard(
                        child: Text(
                          notice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warningForeground,
                          ),
                        ),
                      )
                    : isAlreadyShipped(order.status)
                        ? _ManualShipmentSection(
                            order: order,
                            onEditShippedInvoice: () async {
                              final detail = context.read<OrderDetailCubit>();
                              final options = context
                                  .read<ManualShipmentBloc>()
                                  .state
                                  .options;
                              if (await showLotteonInvoiceEditSheet(context,
                                  order: order, carrierOptions: options)) {
                                await detail.reload();
                              }
                            },
                          )
                        : _ManualShipmentSection(order: order);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!acknowledged) _InternalStageShipmentNotice(order: order),
                if (body != null) body,
                if (openStatus) LotteonDeliveryAppointmentSection(order: order),
              ],
            );
          },
        );
      },
    );
  }
}

/// The three ways an 11st invoice of a preparing order is sent
/// (FEATURE_2610_17 / D64): 「한 번에 모두」 (the one-invoice form, default) ·
/// 「일부 줄만 보내기」 · 「한 줄을 송장 여러 장으로」. The choice locks with the
/// inputs once a result came back; the result and error stay in the shared
/// shipment card.
class _ElevenstShipmentModes extends StatefulWidget {
  final OrderItem order;

  const _ElevenstShipmentModes({required this.order});

  @override
  State<_ElevenstShipmentModes> createState() => _ElevenstShipmentModesState();
}

enum _ElevenstMode { all, partial, split }

class _ElevenstShipmentModesState extends State<_ElevenstShipmentModes> {
  _ElevenstMode _mode = _ElevenstMode.all;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
      buildWhen: (p, c) =>
          p.submitting != c.submitting || p.result != c.result,
      builder: (context, manual) {
        final locked = manual.submitting || manual.result != null;
        final picker = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (mode, label) in const [
              (_ElevenstMode.all, '한 번에 모두'),
              (_ElevenstMode.partial, '일부 줄만 보내기'),
              (_ElevenstMode.split, '한 줄을 송장 여러 장으로'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _mode == mode,
                onSelected:
                    locked ? null : (_) => setState(() => _mode = mode),
              ),
          ],
        );
        return _ManualShipmentSection(
          order: widget.order,
          modePicker: picker,
          altForm: _mode == _ElevenstMode.all
              ? null
              : ElevenstSplitShipmentSection(
                  order: widget.order,
                  split: _mode == _ElevenstMode.split,
                ),
        );
      },
    );
  }
}

/// Order-confirmation section inside the order detail (inline — no separate
/// screen / dialog).
///
/// **Purpose**: paid → preparing for the **whole box** this line belongs to
/// (Coupang), or for this line's (delivery number, product number) group
/// (11st, FEATURE_2610_17 / D48). Used to confirm right after checking the
/// goods (PLAN 2609_17 D14).
///
/// ⚠️ Only the line id is sent — box / group dedupe and the status filter are
/// the server's (D1).
/// ⚠️ Cannot be undone — always through the confirm dialog, and no automatic
/// retry (D15).
/// ⚠️ Success = `succeeded > 0`. A marketplace rejection is also 200 +
/// `failed`, so judging by `result != null` alone shows a failure as done
/// (D15).
/// ⚠️ No permission gate in the client. A 403 hides the section — that
/// reflects the server's decision, not a second one (same rule as the single
/// shipment).
/// Order-status refresh icon on the top bar (FEATURE_2609_50 ·
/// FEATURE_2611_29 / D11).
///
/// Reads this order from Coupang again now to align the local status — the
/// manual way out for an order stuck outside the regular / nightly sync
/// windows.
///
/// 🔴 Drawn for Coupang orders only (D24 · FEATURE_2610_17 / D12) — for
/// other orders `_buildContent` passes `appBarActions: null`. For Coupang it
/// shows whatever the detail read state is (FEATURE_2611_29 / D4).
/// 🔴 When something changed it **goes back to the list** (D22) — this page is
/// a StatelessWidget using the [OrderItem] from the route `extra`, so it has no
/// way to refresh the status badge in place. Do not solve it with a new
/// `OrderDetailBloc` (having none is intended).
class _RefreshAction extends StatelessWidget {
  final OrderItem order;

  const _RefreshAction({required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderRefreshBloc, OrderRefreshState>(
      // Listens only to transitions so that toasts do not pile up when the
      // same value is emitted again.
      listenWhen: (prev, curr) =>
          (curr.result != null && curr.result != prev.result) ||
          (curr.errorMessage != null && curr.errorMessage != prev.errorMessage),
      listener: (context, state) {
        final result = state.result;
        if (result != null) {
          // 실패 사유는 서버 원문 그대로 보여준다. empty(쿠팡 0박스)는 실패가 아니다.
          // 마켓에서 취소·반품된 건은 서버가 로컬까지 정리했으므로 그렇게 알린다.
          if (result.failed.isNotEmpty) {
            showErrorToast(context, result.failed.first.reason);
          } else if (result.cancelled.isNotEmpty) {
            _showSnackBar(
              context,
              result.cancelled.first.cancelledLines > 0
                  ? '마켓에서 취소·반품된 주문입니다. 발송 전이라 취소로 정리했습니다.'
                  : '마켓에서 취소·반품된 주문입니다. 이미 발송한 건이라 금액은 그대로 두었습니다.',
            );
          } else if (result.refreshed > 0) {
            showSuccessToast(context, '최신 상태로 갱신했습니다.');
          } else {
            _showSnackBar(context, '이미 최신입니다.');
          }
          context.read<OrderRefreshBloc>().add(const RefreshResultCleared());
          // 바뀐 게 있을 때만 목록으로 돌아간다(D22). 이미 최신이거나 실패면 그 자리에
          // 머문다 — 보여줄 변화가 없는데 화면을 옮기면 사용자가 뭘 눌렀는지 놓친다.
          if (result.refreshed > 0 || result.cancelled.isNotEmpty) {
            context.go(Routes.orderHistoryPath);
          }
          return;
        }
        final error = state.errorMessage;
        if (error == null) return;
        showErrorToast(context, error);
        context.read<OrderRefreshBloc>().add(const RefreshResultCleared());
      },
      builder: (context, state) => IconButton(
        tooltip: '주문 상태 갱신',
        onPressed: state.submitting
            ? null
            : () => context
                .read<OrderRefreshBloc>()
                .add(RefreshRequested([order.id])),
        icon: state.submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }

  /// Only the notice texts of the refresh result pass through here (order
  /// cancelled in the marketplace, already current) — kind = notice. The
  /// failure reason, the refreshed text and a failed request call the toast
  /// of their own kind directly (FEATURE_2610_02 · N13 · D124).
  void _showSnackBar(BuildContext context, String message) {
    showNoticeToast(context, message);
  }
}

class _AcknowledgeSection extends StatelessWidget {
  final OrderItem order;

  const _AcknowledgeSection({required this.order});

  /// 이 화면에서 방금 [내부 발주처리]에 성공했는가(FEATURE_2609_75 / D13).
  static bool _internalMarked(OrderInternalStageState s) =>
      s.lastAction == InternalStageAction.mark &&
      s.result != null &&
      s.result!.changedShipments > 0;

  @override
  Widget build(BuildContext context) {
    // Only Coupang · 11st · LotteON orders have the internal-stage BLoC
    // (FEATURE_2611_23 / D51 · R50).
    if (order.platform != 'COUPANG' &&
        order.platform != 'ELEVENST' &&
        order.platform != 'LOTTEON') {
      return _buildBody(context, null);
    }
    return BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
      builder: (context, internal) => _buildBody(context, internal),
    );
  }

  /// [internal] = null for an order other than Coupang · 11st · LotteON — no
  /// [내부 발주처리] there.
  Widget _buildBody(BuildContext context, OrderInternalStageState? internal) {
    return BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
        builder: (context, state) {
          // Shown only for paid Coupang · 11st · LotteON orders (D2·D10·D14 ·
          // FEATURE_2610_17 / D20 · FEATURE_2611_23 / D16). A 403 hides the
          // entry point.
          if ((order.platform != 'COUPANG' &&
              order.platform != 'ELEVENST' &&
              order.platform != 'LOTTEON') ||
              order.status != OrderStatus.paid ||
              state.forbidden) {
            return const SizedBox.shrink();
          }

          final result = state.result;
          final acknowledged = result != null && result.succeeded > 0;
          // The marketplace rejected it (200 + failed) — show the original
          // text as is and open the button again.
          final rejected = result != null && result.succeeded == 0;
          final failureText = rejected && result.failed.isNotEmpty
              ? '${result.failed.first.resultCode}: ${result.failed.first.message}'
              : state.errorMessage;
          final internalMarked = internal != null && _internalMarked(internal);
          // [내부 발주처리] = only orders without an internal stage yet
          // (D1·D13), never a visit-pickup order (FEATURE_2611_23 / D53).
          // Hidden on 403.
          final canMarkInternal = !order.visitPickup &&
              internal != null &&
              order.internalStage == null &&
              !internal.forbidden;
          final busy = state.submitting || internal?.submitting != null;

          return OrderNextStepCard(
            title: '다음 단계 · 발주 확인',
            // FEATURE_2610_17 / D52 · FEATURE_2611_23 / D17:
            // 11st and LotteON confirm this product only — their notice
            // has no box number.
            body: acknowledged
                ? null
                : order.platform == 'ELEVENST'
                    ? '이 상품(주문 줄)이 발주확인 처리되어 배송준비중으로 '
                        '바뀝니다. 되돌릴 수 없습니다.'
                    : order.platform == 'LOTTEON'
                    ? '이 상품(주문 줄)이 발주확인 처리되어 상품준비중으로 '
                        '바뀝니다. 되돌릴 수 없습니다.'
                    : '이 주문의 배송건(박스 ${order.externalBoxId ?? '-'}) '
                        '전체가 상품준비중으로 전환됩니다. 되돌릴 수 없습니다.',
            children: [
              if (acknowledged)
                const Text(
                  '발주처리 완료',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.successForeground,
                  ),
                )
              else
                // [내부 발주처리] comes first and stays green — written
                // here, not in the theme (D13 · D101 · 2611_29 R8).
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (canMarkInternal)
                      internalMarked
                          ? const Text(
                              '내부 발주 완료',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.successForeground,
                              ),
                            )
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandGreen,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onSecondary,
                              ),
                              onPressed: busy
                                  ? null
                                  : () => context
                                      .read<OrderInternalStageBloc>()
                                      .add(InternalStageRequested(
                                        InternalStageAction.mark,
                                        [order.id],
                                      )),
                              child: internal.submitting ==
                                      InternalStageAction.mark
                                  ? const AppBusyLabel('내부 발주처리')
                                  : const Text('내부 발주처리'),
                            ),
                    FilledButton(
                      onPressed:
                          busy ? null : () => _confirmAndSubmit(context),
                      child: state.submitting
                          ? const AppBusyLabel('발주처리')
                          : const Text('발주처리'),
                    ),
                  ],
                ),
              if (failureText != null) ...[
                const SizedBox(height: 8),
                Text(
                  failureText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              if (internal?.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  internal!.errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          );
        },
    );
  }

  /// 되돌릴 수 없는 작업이라 확인을 반드시 거친다. 일괄과 **같은 UseCase·같은 엔드포인트**다(D6).
  /// 내부 단계 주문이면(방금 이 화면에서 내부 발주한 경우 포함) D14 안내 문구로 묻는다.
  Future<void> _confirmAndSubmit(BuildContext context) async {
    final bloc = context.read<OrderAcknowledgeBloc>();
    final reserved = order.internalStage != null ||
        ((order.platform == 'COUPANG' ||
            order.platform == 'ELEVENST' ||
            order.platform == 'LOTTEON') &&
            _internalMarked(context.read<OrderInternalStageBloc>().state));
    final ok = await showAppConfirmDialog(
      context,
      title: reserved ? '예약된 주문 포함' : '발주처리',
      message: reserved
          ? '예약된 주문입니다. 마켓에 지금 발주처리하면 해당 주문의 내부 발주·예약 발송이 해제됩니다. 계속할까요?'
          : '이 주문을 발주처리합니다. 되돌릴 수 없습니다.',
      confirmText: '발주처리',
    );
    // 다이얼로그가 열려 있는 사이 페이지를 벗어날 수 있다.
    if (!ok || bloc.isClosed) return;
    bloc.add(AcknowledgeRequested([order.id]));
  }
}

/// 주문 상세 안 발송 전 주문 취소 섹션 (인라인 확장 — 별도 화면/다이얼로그 없음).
///
/// **용도**: 사유와 수량을 골라 **이 주문 라인**을 취소한다 — 결제완료는 즉시취소,
/// 상품준비중은 출고중지로 접수된다(PLAN 2609_25 D2).
///
/// ⚠️ 취소 단위는 박스가 아니라 **라인(옵션) × 수량**이다 — 발주처리·발송처리와 다르다.
/// 계정→주문번호→박스 그룹핑은 서버가 한다(D1).
/// ⚠️ 되돌릴 수 없고 **쿠팡 판매자 점수가 하락한다** — 확인 다이얼로그를 반드시 거치고
/// 자동 재시도를 넣지 말 것(D13).
/// ⚠️ 사유 라벨을 코드에 두지 않는다 — 목록의 소유자는 서버다(D4).
/// ⚠️ 전량취소 판정은 `purchasableQty == 0` 이다 — 수량으로 다시 세지 말 것.
/// ⚠️ 권한 게이트는 클라이언트에 두지 않는다. 다만 403(사유 조회 포함)이면 섹션을 숨긴다 —
/// 서버가 내린 판정을 반영하는 것이라 이중 판정이 아니다.
///
/// 수량은 BLoC 상태로 올리지 않는다 → [TextEditingController] 를 들기 위해 StatefulWidget.
class _CancelSection extends StatefulWidget {
  final OrderItem order;

  const _CancelSection({required this.order});

  @override
  State<_CancelSection> createState() => _CancelSectionState();
}

class _CancelSectionState extends State<_CancelSection> {
  late final TextEditingController _quantityController;

  /// 서버가 내려준 사유 `code`. 라벨은 상태의 목록에서 찾는다(하드코딩 금지, D4).
  String? _reasonCode;

  @override
  void initState() {
    super.initState();
    // 기본값 = 취소 가능 수량 전량(D3).
    _quantityController =
        TextEditingController(text: '${widget.order.purchasableQty}');
  }

  @override
  void dispose() {
    _quantityController.dispose(); // 누락 시 leak — 상세는 주문마다 새로 만들어진다.
    super.dispose();
  }

  int? get _quantity => int.tryParse(_quantityController.text.trim());

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return BlocConsumer<OrderCancelBloc, OrderCancelState>(
      // Notifies only at the moment the result first arrives — showing it on
      // every rebuild would repeat the toast.
      listenWhen: (prev, curr) =>
          prev.result != curr.result && curr.result != null,
      listener: (context, state) {
        final result = state.result!;
        if (result.cancelled.isEmpty) return;
        showSuccessToast(context, '취소 접수 완료 — ${result.succeededQty}개');
      },
      builder: (context, state) {
        // 결제완료·상품준비중 쿠팡 주문에만 노출한다(D2·D10). 403 이면 진입점을 숨긴다.
        if (order.platform != 'COUPANG' ||
            (order.status != OrderStatus.paid &&
                order.status != OrderStatus.preparing) ||
            state.forbidden) {
          return const SizedBox.shrink();
        }

        final result = state.result;
        final succeeded = result != null && result.cancelled.isNotEmpty;
        // 취소 후 남은 수량은 서버가 라인별로 내려준다(D14). 정보 카드에는 넣지 않는다.
        final remainingQty = succeeded
            ? result.cancelled.first.resultPurchasableQty
            : order.purchasableQty;
        // 쿠팡이 접수한 뒤에는 입력을 잠근다 — 같은 라인을 두 번 보내면 그만큼 더 취소된다.
        final locked = state.submitting || succeeded;
        final quantity = _quantity;
        final quantityValid =
            quantity != null && quantity >= 1 && quantity <= remainingQty;
        final canSubmit = !locked &&
            !state.reasonsFailed &&
            _reasonCode != null &&
            quantityValid;

        return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '주문 취소',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // 아직 아무것도 취소하지 않았는데 취소 가능 수량이 0 이면 입력 자체를 띄우지 않는다.
                if (!succeeded && order.purchasableQty == 0)
                  Text(
                    '취소 가능한 수량이 없습니다 (이미 취소된 주문)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Text(
                    '취소 가능 $remainingQty개',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.loadingReasons)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (state.reasonsFailed)
                    // 막다른 길로 두지 않는다 — 자동 재시도는 없고 버튼 1개만 둔다(D4).
                    Row(
                      children: [
                        const Expanded(
                          child: Text('사유 목록을 불러오지 못했습니다.',
                              style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => context
                              .read<OrderCancelBloc>()
                              .add(const CancelReasonsRequested()),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      // 목록에 없는 값을 넘기면 Dropdown 이 assert 로 죽는다.
                      value: state.reasons.any((r) => r.code == _reasonCode)
                          ? _reasonCode
                          : null,
                      isExpanded: true, // 라벨이 길다 — overflow 방지
                      decoration: const InputDecoration(
                        labelText: '취소 사유',
                      ),
                      items: state.reasons
                          .map((r) => DropdownMenuItem<String>(
                                value: r.code,
                                child: Text(
                                  r.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: locked || state.reasons.isEmpty
                          ? null
                          : (value) => setState(() => _reasonCode = value),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    enabled: !locked,
                    // 파싱값을 화면 상태로 올려야 버튼 활성/비활성이 즉시 갱신된다
                    // (build 안에서 controller.text 만 읽으면 입력해도 버튼이 안 열린다).
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: '취소 수량',
                      errorText: quantityValid
                          ? null
                          : '1~$remainingQty 사이로 입력하세요',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '결제완료는 즉시 취소, 상품준비중은 출고중지로 접수됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '⚠️ 되돌릴 수 없으며 쿠팡 판매자 점수가 하락합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed:
                        canSubmit ? () => _confirmAndSubmit(context, state) : null,
                    child: state.submitting
                        ? const AppBusyLabel('주문 취소')
                        : const Text('주문 취소'),
                  ),
                ],
                if (succeeded) ...[
                  const SizedBox(height: 8),
                  Text(
                    '취소 접수 완료 — ${result.succeededQty}개 '
                    '(${_receiptTypeLabel(result.cancelled.first.receiptType)})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.successForeground,
                    ),
                  ),
                ],
                // 쿠팡이 거절한 건은 원문 그대로 노출하고 버튼은 다시 열어 둔다(D16).
                for (final failed in result?.failed ?? const <FailedLine>[]) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${failed.code ?? '-'}: ${failed.message ?? '-'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                // 스킵·전송불가 사유는 서버 문구를 그대로 쓴다(모바일에서 새로 짓지 않는다).
                for (final skipped in [
                  ...?result?.skipped,
                  ...?result?.unsupported,
                ]) ...[
                  const SizedBox(height: 8),
                  Text(
                    skipped.reason ?? '전송하지 않았습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
        );
      },
    );
  }

  /// 되돌릴 수 없고 판매자 점수가 깎이는 작업이라 확인을 반드시 거친다(D13).
  Future<void> _confirmAndSubmit(
    BuildContext context,
    OrderCancelState state,
  ) async {
    final bloc = context.read<OrderCancelBloc>();
    final quantity = _quantity;
    final code = _reasonCode;
    if (quantity == null || code == null) return;
    final label = state.reasons
        .firstWhere(
          (r) => r.code == code,
          orElse: () => CancelReasonOption(code: code, label: code),
        )
        .label;

    final ok = await showAppConfirmDialog(
      context,
      title: '주문 취소',
      message: '$quantity개를 "$label" 사유로 취소합니다.\n'
          '되돌릴 수 없고 판매자 점수가 하락합니다.',
      confirmText: '주문 취소',
      cancelText: '닫기',
      isDangerous: true,
    );
    // 다이얼로그가 열려 있는 사이 페이지를 벗어날 수 있다.
    if (!ok || bloc.isClosed) return;
    bloc.add(CancelRequested(
      [
        {'orderItemId': widget.order.id, 'quantity': quantity}
      ],
      code,
    ));
  }

  /// 쿠팡 접수 유형 라벨 — 모르는 값은 원문 폴백.
  String _receiptTypeLabel(String? receiptType) {
    switch (receiptType) {
      case 'CANCEL':
        return '즉시취소';
      case 'STOP_SHIPMENT':
        return '출고중지 접수';
      default:
        return receiptType ?? '-';
    }
  }
}

/// Single shipment section inside the order detail (inline — no separate
/// screen / dialog).
///
/// **Purpose**: pick a carrier, type the invoice number and ship this order's
/// one box (Coupang) or delivery number (11st, FEATURE_2610_17 / D2). Used for
/// orders without a result file (xlsx), orders shipped with another carrier,
/// and fixing a wrong invoice (Coupang inline — 11st has no update, D21;
/// LotteON opens its own sheet through [onEditShippedInvoice],
/// FEATURE_2611_23 / D19).
///
/// ⚠️ The send unit is **the whole box this line belongs to**, not the line
/// on screen (PLAN 2609_11 D1) — Coupang accepts only the same invoice on
/// every option of the box, and 11st ships the whole delivery number. The
/// 11st partial / split ways ([altForm], FEATURE_2610_17 / D64) send only the
/// chosen lines.
/// ⚠️ New upload / invoice update **mode is decided by the server from the
/// order status** (D3). Here only the button label changes.
/// ⚠️ Once the marketplace answered (success and partial failure alike) the
/// input locks (D14) — a resend would hit DUPLICATE_INVOICE_NUMBER. It does
/// not lock when the request itself failed (nothing was sent).
/// ⚠️ No permission gate in the client. A 403 on the carrier lookup hides the
/// section — otherwise a non-ADMIN user is left with a `다시 시도` button that
/// always fails.
///
/// The invoice number is not lifted into BLoC state (an emit per character
/// wastes rebuilds) → StatefulWidget to hold the [TextEditingController].
class _ManualShipmentSection extends StatefulWidget {
  final OrderItem order;

  /// 11st only (FEATURE_2610_17 / D64): the way-to-send chips under the title.
  final Widget? modePicker;

  /// 11st only (D64): replaces the carrier · invoice form for a partial /
  /// split send; the title, error and result stay this card's.
  final Widget? altForm;

  /// LotteON only (FEATURE_2611_23 / D19): [송장 수정하기] opens the LotteON
  /// invoice-update sheet instead of the inline form.
  final VoidCallback? onEditShippedInvoice;

  const _ManualShipmentSection({
    required this.order,
    this.modePicker,
    this.altForm,
    this.onEditShippedInvoice,
  });

  @override
  State<_ManualShipmentSection> createState() => _ManualShipmentSectionState();
}

class _ManualShipmentSectionState extends State<_ManualShipmentSection> {
  final TextEditingController _invoiceController = TextEditingController();

  @override
  void dispose() {
    _invoiceController.dispose(); // 누락 시 leak — 상세는 주문마다 새로 만들어진다.
    super.dispose();
  }

  void _onInvoiceChanged(BuildContext context, String? currentError) {
    // 입력을 고치면 직전 전송 실패 문구를 지운다(웹의 onChange 클리어와 같은 규칙).
    if (currentError != null) {
      context.read<ManualShipmentBloc>().add(const SubmitErrorCleared());
    }
    setState(() {}); // 버튼 활성 갱신 (글자마다 emit 하지 않는다)
  }

  @override
  Widget build(BuildContext context) {
    final shipped = isAlreadyShipped(widget.order.status);
    return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
      builder: (context, state) {
        // ADMIN 이 아님 — 서버가 내린 판정을 그대로 반영한다.
        if (state.optionsForbidden) return const SizedBox.shrink();

        final locked = state.submitting || state.result != null;
        final canSubmit = !locked &&
            state.carrierCode != null &&
            _invoiceController.text.trim().isNotEmpty &&
            state.options.isNotEmpty;
        // The form is open right away, shipped orders included
        // (FEATURE_2611_29 / D19 ⑥); only a shipped LotteON order keeps
        // [송장 수정하기], which opens its own sheet (R14).
        final formOpen = !shipped || widget.onEditShippedInvoice == null;

        return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  shipped ? '송장 수정' : '발송처리',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.modePicker != null) ...[
                  widget.modePicker!,
                  const SizedBox(height: 8),
                ],
                if (widget.altForm == null)
                  Text(
                    '박스 ${widget.order.externalBoxId ?? '-'} 의 모든 옵션에 같은 운송장번호가 적용됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (shipped && formOpen) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '이미 발송처리된 주문입니다. '
                    '입력한 운송장으로 송장 수정을 요청합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warningForeground,
                    ),
                  ),
                ],
                if (!formOpen && widget.onEditShippedInvoice != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: locked ? null : widget.onEditShippedInvoice,
                    child: const Text('송장 수정하기'),
                  ),
                ],
                if (widget.altForm != null) widget.altForm!,
                if (formOpen && widget.altForm == null) ...[
                  const SizedBox(height: 12),
                  if (state.loadingOptions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    // 값은 마켓 코드 자체다(D2 개정) — 쿠팡은 택배사 목록 API 가 없어 코드표 전량이 온다.
                    // 서버가 등록 택배사를 맨 위로 정렬해 주므로 여기서 다시 정렬하지 않는다.
                    DropdownButtonFormField<String>(
                      // 목록에 없는 값을 넘기면 Dropdown 이 assert 로 죽는다 — 조회 실패로
                      // options 가 비었는데 직전 선택이 남아 있는 경우를 막는다.
                      value: state.options.any(
                              (o) => o.deliveryCompanyCode == state.carrierCode)
                          ? state.carrierCode
                          : null,
                      isExpanded: true, // 코드표가 길다 — 긴 이름이 overflow 하지 않게
                      decoration: const InputDecoration(
                        labelText: '택배사',
                      ),
                      items: state.options
                          .map((o) => DropdownMenuItem<String>(
                                value: o.deliveryCompanyCode,
                                child: Text(
                                  o.registered
                                      ? '${o.carrierName} (등록)'
                                      : o.carrierName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: locked || state.options.isEmpty
                          ? null
                          : (value) {
                              if (value != null) {
                                context
                                    .read<ManualShipmentBloc>()
                                    .add(CarrierSelected(value));
                              }
                            },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _invoiceController,
                    maxLength: 50, // 형식 검증은 하지 않는다(택배사마다 다르다, D15)
                    enabled: !locked && state.options.isNotEmpty,
                    onChanged: (_) =>
                        _onInvoiceChanged(context, state.errorMessage),
                    decoration: const InputDecoration(
                      labelText: '송장번호',
                    ),
                  ),
                  // 조회 실패와 '등록된 택배사 없음' 은 안내가 다르다 — 합치면 거짓 안내가 된다.
                  if (!state.loadingOptions && state.optionsLoadFailed)
                    Row(
                      children: [
                        const Expanded(
                          child: Text('택배사 목록을 불러오지 못했습니다.',
                              style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => context
                              .read<ManualShipmentBloc>()
                              .add(LoadCarrierOptions(widget.order.platform)),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    )
                  else if (!state.loadingOptions && state.options.isEmpty)
                    // 쿠팡은 코드표 전량을 내려주므로 여기까지 오면 서버 쪽 문제다.
                    Text(
                      '선택할 수 있는 택배사가 없습니다. 잠시 후 다시 시도해주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: canSubmit
                        ? () => context.read<ManualShipmentBloc>().add(
                              SubmitManualShipment(
                                orderItemId: widget.order.id,
                                invoiceNumber: _invoiceController.text.trim(),
                              ),
                            )
                        : null,
                    child: state.submitting
                        ? AppBusyLabel(shipped ? '송장 수정 요청' : '발송처리')
                        : Text(shipped ? '송장 수정 요청' : '발송처리'),
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (state.result != null) ...[
                  const SizedBox(height: 12),
                  ..._buildResult(state.result!),
                ],
              ],
            ),
        );
      },
    );
  }

  // The result stays inline (toast ❌ — it must be possible to scroll back and
  // see it again).
  List<Widget> _buildResult(ManualShipmentResult result) {
    final widgets = <Widget>[];
    if (result.succeeded > 0 && result.failed.isEmpty) {
      widgets.add(Text(
        '${result.isUpdateMode ? '송장 수정 요청 완료' : '발송처리 완료'} — '
        '박스 ${result.shipmentBoxId} · ${result.sentLines}건',
        style:
            const TextStyle(fontSize: 13, color: AppColors.successForeground),
      ));
    }
    // Failures show the marketplace's original resultCode / message as is (D6).
    for (final failed in result.failed) {
      widgets.add(Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${failed.shipmentBoxId} · ${failed.resultCode} · ${failed.message}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ));
    }
    return widgets;
  }
}

/// 주문 상세 안 송장 접수시트 섹션 (인라인 확장 — 별도 화면/다이얼로그 없음).
///
/// **용도**: 이 주문 한 건(상태 무관)의 접수시트 rows 를 불러와 라인별 택배수량을 조정하고
/// xlsx 로 저장한다. 진입 시 자동 조회하지 않고 버튼 탭에서만 [LoadOrderSheet] 를 발행한다.
///
/// ⚠️ 개인정보 최소 노출 — 수령인 이름/전화/우편번호/전체주소는 그리지 않는다(단건이라 이름
/// 없이도 라인 식별 가능). 송장시트 목록 화면(다건)이 이름을 보여주는 것과 의도적으로 다르다.
///
/// ⚠️ 권한 게이트는 클라이언트에 두지 않는다 — 서버 403 을 에러 메시지로 노출한다.
/// 플랫폼 버튼 비활성은 표시용 `order.platform` 기준이라 서버(계정 platform) 판정과
/// 어긋날 수 있어 400 메시지 매핑을 함께 둔다.
class _OrderSheetSection extends StatelessWidget {
  final OrderItem order;

  const _OrderSheetSection({required this.order});

  /// Coupang · 11st · LotteON — the platforms the sheet serves
  /// (FEATURE_2610_17 / D2 · FEATURE_2611_23).
  bool get _isMarketOrder =>
      order.platform == 'COUPANG' ||
          order.platform == 'ELEVENST' ||
          order.platform == 'LOTTEON';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderSheetBloc, OrderSheetState>(
      // transient 상태만 리스닝 — 저장/에러 알림. 중첩 BlocListener 를 두면 두 번 저장된다.
      listenWhen: (prev, curr) =>
          curr is OrderSheetExportSuccess || curr is OrderSheetExportFailure,
      listener: (context, state) {
        if (state is OrderSheetExportSuccess) {
          _saveAndNotify(context, state.bytes);
        } else if (state is OrderSheetExportFailure) {
          showErrorToast(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is OrderSheetLoading) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is OrderSheetError) {
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<OrderSheetBloc>()
                        .add(LoadOrderSheet(order.id)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is OrderSheetLoaded) {
          return _buildSheet(context, state.rows, isExporting: false);
        }
        if (state is OrderSheetExporting) {
          return _buildSheet(context, state.rows, isExporting: true);
        }
        if (state is OrderSheetExportSuccess) {
          return _buildSheet(context, state.rows, isExporting: false);
        }
        if (state is OrderSheetExportFailure) {
          return _buildSheet(context, state.rows, isExporting: false);
        }

        // OrderSheetInitial — 섹션 접힘(버튼만).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '송장시트에서 여러 주문의 송장을 '
              '한 번에 등록·조회할 수 있습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isMarketOrder
                  ? () => context
                      .read<OrderSheetBloc>()
                      .add(LoadOrderSheet(order.id))
                  : null,
              child: const Text('송장시트 조회'),
            ),
            if (!_isMarketOrder) ...[
              const SizedBox(height: 8),
              Text(
                '쿠팡 · 11번가 주문만 지원합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSheet(
    BuildContext context,
    List<ShippingLabelPreviewRow> rows, {
    required bool isExporting,
  }) {
    final isEmpty = rows.isEmpty;

    // Coupang safe numbers expire 48h after delivery and then come
    // back empty. The row cards never render the phone (PII), so this
    // banner is the only signal the user gets. No reissue/refetch button:
    // Coupang has no OpenAPI endpoint for it and a refetch returns the
    // same empty value — reissue happens in WING(반품관리) or via ARS.
    // See PLAN.md D3~D6.
    final hasMissingPhone = rows.any((r) => r.receiverPhone.trim().isEmpty);
    final platformLabel = platformName(order.platform);

    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '송장 접수시트',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '주문번호 ${order.externalOrderId} · ${rows.length}건',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasMissingPhone) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  border: Border.all(color: AppColors.warningBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$platformLabel에서 고객 안심번호를 재발행하십시오.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warningForeground,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('발송 대상 라인이 없습니다.', textAlign: TextAlign.center),
              )
            else
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OrderSheetRowCard(
                    row: row,
                    onChanged: (parcel) => context.read<OrderSheetBloc>().add(
                          UpdateOrderSheetParcelQuantity(row.rowKey, parcel),
                        ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: isEmpty || isExporting
                  ? null
                  : () => context
                      .read<OrderSheetBloc>()
                      .add(const ExportOrderSheetRequested()),
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: const Text('엑셀 다운로드'),
            ),
          ],
        ),
    );
  }

  Future<void> _saveAndNotify(BuildContext context, Uint8List bytes) async {
    try {
      // saveAs: 시스템 저장 다이얼로그로 사용자가 위치 선택 → 실제 보이는 파일로 저장.
      // saveFile(bytes) 는 Android 에서 앱 전용 디렉토리에만 써서 사용자가 못 찾는다.
      final path = await FileSaver.instance.saveAs(
        name: '주문목록_${order.externalOrderId}',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      // null when the user cancels the dialog → ends without a toast.
      if (path == null || path.isEmpty) return;
    } catch (_) {
      if (context.mounted) {
        showErrorToast(context, '파일 저장에 실패했습니다.');
      }
      return;
    }
    if (!context.mounted) return;
    showSuccessToast(context, '주문목록을 저장했습니다.');
  }
}

/// 시트 한 라인 카드 — 배송지 앞부분 / 상품명 / 내품수량 + 택배수량 편집(-, 값, +).
/// 송장시트 목록 화면의 `_PreviewRowCard` 와 같은 구조지만 수령인 이름은 제외한다.
class _OrderSheetRowCard extends StatelessWidget {
  final ShippingLabelPreviewRow row;
  final ValueChanged<int> onChanged;

  const _OrderSheetRowCard({required this.row, required this.onChanged});

  /// 배송지 앞부분 = 공백 split 앞 2토큰(예: "울산광역시 중구"). 그 이상은 표시하지 않는다.
  String get _addressHead {
    final parts =
        row.address.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return parts.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _addressHead,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            row.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '내품수량 ${row.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              const Text('택배수량', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              _ParcelStepper(
                quantity: row.parcelQuantity,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 택배수량 -, 값, + 스테퍼. 하한 최소 1(1에서 - 버튼 disabled). 상한 없음.
///
/// ⚠️ `TextFormField` 금지 — 키 입력마다 Loaded 재emit → 재빌드로 커서/입력이 초기화되고
/// 빈 문자열이 1 로 튄다. 송장시트 화면(`_ParcelStepper`)과 편집 UX 를 맞추기 위한 복제본이다
/// (기존 화면의 private 위젯은 변경 금지 대상이라 공유 추출하지 않는다).
class _ParcelStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ParcelStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: quantity <= 1 ? null : () => onChanged(quantity - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
