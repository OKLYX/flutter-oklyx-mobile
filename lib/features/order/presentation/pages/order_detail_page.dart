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
import '../widgets/internal_stage_badge.dart';
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
/// **Content**: cards 「주문 정보」 · 「기본 정보」 · 「수량 정보」 (D34), then
/// 「상품 목록」 (every line of the order) and 「송장 목록」 (parcel chips, D29).
/// The packing entry draws only 「주문 정보」 + 「상품 목록」 + 「송장 목록」 and
/// adds [상자 변경] to packed parcels (D14 · D27).
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
    return ScaffoldWithNavBar(
      title: '주문 상세',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.orderHistoryPath),
      body: order == null
          ? _buildMissing(context,
              label: '주문내역으로',
              onPressed: () => context.go(Routes.orderHistoryPath))
          : _buildContent(context, order!),
    );
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
    // stage · reservation cover 11st too (FEATURE_2611_23 / D51).
    final isElevenst = o.platform == 'ELEVENST';
    final isMarketOrder = isCoupang || isElevenst;
    return MultiBlocProvider(
      providers: [
        // The order read on open (FEATURE_2611_07 / D18).
        BlocProvider<OrderDetailCubit>(
          create: (_) => getIt<OrderDetailCubit>()..loadByLine(o.id),
        ),
        BlocProvider<OrderSheetBloc>(create: (_) => getIt<OrderSheetBloc>()),
        // ⚠️ Made only for Coupang · 11st orders — gating only the render would
        // call the ADMIN-only carrier API for nothing on every other order.
        if (isMarketOrder)
          BlocProvider<ManualShipmentBloc>(
            create: (_) => getIt<ManualShipmentBloc>()
              ..add(LoadCarrierOptions(o.platform)),
          ),
        // Order confirmation sits in the same guard (Coupang · 11st, D20) — no
        // idle instance for other orders.
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
        // The internal acknowledge is Coupang · 11st only (FEATURE_2609_75 / D1 ·
        // FEATURE_2611_23 / D51) — same guard. No automatic send on entry.
        if (isCoupang || isElevenst)
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
        // Reserved shipment history (D30) + 「송장」(D18) — Coupang · 11st only
        // (FEATURE_2611_23 / D51); reads that order's history · invoices once on
        // entry, with that order's marketplace carriers (D64 ④).
        if (isCoupang || isElevenst)
          BlocProvider<ReservedShipmentBloc>(
            create: (_) => getIt<ReservedShipmentBloc>()
              ..add(ReservedShipmentsRequested(
                  externalOrderId: o.externalOrderId, platform: o.platform)),
          ),
      ],
      child: AppPageBody.scroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 갱신 버튼 줄. 🔴 AppBar 가 아니라 본문 최상단이다(2609_50 D23) —
            // ScaffoldWithNavBar 에 actions 슬롯이 없고, 모든 페이지가 쓰는 공용 위젯에
            // 슬롯을 새로 뚫지 않는다. 🔴 발주·발송이 있는 하단 액션 영역에도 두지 않는다 —
            // 그쪽은 마켓에 쓰는 작업 자리이고 상태 갱신은 읽기다.
            if (isCoupang) _RefreshRow(order: o),
            // ⚠️ These BlocBuilders wrap only the cards and the two lists —
            // wrapping the Column or AppPageBody.scroll would rebuild even the
            // shipping-label sheet section on every send and the edited parcel
            // count would jump. While reading / failed, one text takes the
            // place of all of them (D18).
            BlocBuilder<OrderDetailCubit, OrderDetailState>(
              builder: (context, detailState) {
                final detail = detailState.detail;
                if (detail == null) {
                  return _DetailStatusText(state: detailState);
                }
                // The tapped line as the server returned it (fallback = the
                // list row).
                final line = _lineOf(detail, o);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(line, detail,
                        isCoupang: isCoupang, isMarketOrder: isMarketOrder),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: '수량 정보',
                      rows: [
                        _InfoRow('주문수량', '${line.orderCount}'),
                        _InfoRow('취소수량', '${line.cancelCount}'),
                        _InfoRow('보류수량', '${line.holdCount}'),
                        _InfoRow('구매가능수량', '${line.purchasableQty}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ProductListCard(detail: detail, highlightLineId: o.id),
                    const SizedBox(height: 12),
                    // No [상자 변경] from the order history (D27).
                    _ParcelListCard(state: detailState),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // 11st only — cancel requests and the seller return (D19 · D35).
            if (isElevenst) ElevenstOrderSections(order: o),
            // 송장(D18 🔁) — 내부 단계(결제완료) 배송건이 없으면(대부분의 주문) 아무것도 그리지 않는다.
            // 이 화면에서 [내부 발주처리]·[발주처리]가 성공하면 그 주문의 송장·기록을 다시 읽는다 —
            // 다시 들어오지 않아도 「송장」이 바로 나타나고/사라진다(웹 05 의 `shownStage` 재렌더와 같은 동작, D9).
            if (isCoupang || isElevenst)
              MultiBlocListener(
                listeners: [
                  BlocListener<OrderInternalStageBloc, OrderInternalStageState>(
                    listenWhen: (p, c) => c.result != null && p.result != c.result,
                    listener: (context, _) => context
                        .read<ReservedShipmentBloc>()
                        .add(ReservedShipmentsRequested(
                            externalOrderId: o.externalOrderId)),
                  ),
                  BlocListener<OrderAcknowledgeBloc, OrderAcknowledgeState>(
                    listenWhen: (p, c) => c.result != null && p.result != c.result,
                    listener: (context, _) => context
                        .read<ReservedShipmentBloc>()
                        .add(ReservedShipmentsRequested(
                            externalOrderId: o.externalOrderId)),
                  ),
                ],
                child: const StoredInvoiceSection(),
              ),
            // 예약 발송 기록(D30) — 기록이 없으면(대부분의 주문) 아무것도 그리지 않는다.
            if (isCoupang || isElevenst) const ReservedShipmentHistorySection(),
            // Sheet · shipment · cancel are used one at a time, so they share
            // side-by-side tabs.
            // ⚠️ A full cancel keeps the local status (D7), so the section
            // stays open — it is hidden from outside (tab gate · wrapper)
            // **without editing the widget**. A partial cancel is not hidden
            // (D19).
            // ⚠️ Orders other than Coupang · 11st get no shipment / cancel BLoC at
            // all (provider guard above), so they skip the tabs and keep only
            // the sheet section — a tab reading a missing BLoC crashes. 11st
            // has no Coupang cancel BLoC (D12); its cancel tab is the 11st sale
            // refusal on `ElevenstOrderActionBloc` (FEATURE_2610_17 / D61).
            if (isMarketOrder)
              _ActionTabs(order: o, withCancel: isCoupang)
            else
              _OrderSheetSection(order: o),
            // 발주(결제완료→상품준비중)는 발송·취소의 앞 단계라 탭에 섞지 않고 화면 하단에 따로 둔다.
            if (isMarketOrder) ...[
              const SizedBox(height: 12),
              // The full-cancel gate reads the Coupang-only cancel BLoC. An 11st
              // reserved sale takes [입고완료 처리] instead (FEATURE_2610_17 /
              // D67).
              if (isCoupang)
                _HideWhenFullyCancelled(child: _AcknowledgeSection(order: o))
              else if (o.reservedSale && !o.cancelled)
                ElevenstStockConfirmSection(order: o)
              else
                _AcknowledgeSection(order: o),
            ],
          ],
        ),
      ),
    );
  }
}

/// 「주문 정보」 + 「기본 정보」 cards in one [Column] (FEATURE_2611_07 / D34).
/// For a Coupang · 11st order only the `상태` row and the badge follow the
/// sends made on this screen — shipment gets `resultStatus: SHIPPED` from the
/// server (2609_11 D4), and a successful order confirmation reads as
/// [OrderStatus.preparing]. Both show without a refetch.
Widget _buildInfoCard(
  OrderItem o,
  OrderDetail detail, {
  required bool isCoupang,
  required bool isMarketOrder,
}) {
  // [stage] = internal stage badge next to 「주문번호」 (FEATURE_2609_75 / D9).
  // null = no badge. Never a text-only row of its own (D9).
  Widget rows(OrderStatus status, InternalStage? stage) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _orderInfoCard(detail, stage: stage),
          const SizedBox(height: 12),
          _InfoCard(
            title: '기본 정보',
            rows: [
              _InfoRow('아이템 ID', o.externalItemId),
              // Same Korean label SSOT as the list (no copied label table).
              _InfoRow('상태', _statusText(o, status)),
              // Amount snapshot at order time — '—' for old orders not
              // backfilled (never 0, D9 · D10).
              _InfoRow('단가', _amountText(o.unitPrice)),
              _InfoRow('상품금액', _amountText(o.lineAmount)),
              _InfoRow('할인금액', _amountText(o.discountAmount)),
              _InfoRow('플랫폼 부담 할인', _amountText(o.platformDiscountAmount)),
            ],
          ),
        ],
      );

  if (!isMarketOrder) {
    return rows(o.status, o.internalStage);
  }
  if (!isCoupang) {
    // 11st has no cancel BLoC (FEATURE_2610_17 / D12) — only the shipment and
    // confirmation results move the status row. The badge follows the
    // internal-stage BLoC like Coupang (FEATURE_2611_23 / D51).
    return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
      builder: (context, manual) =>
          BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
        builder: (context, ack) =>
            BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
          builder: (context, internal) {
            final acknowledged =
                ack.result != null && ack.result!.succeeded > 0;
            final status = manual.result?.resultStatus ??
                (acknowledged ? OrderStatus.preparing : o.status);
            final shownStage = acknowledged
                ? null
                : _AcknowledgeSection._internalMarked(internal)
                    ? InternalStage.internalPreparing
                    : o.internalStage;
            return rows(status, shownStage);
          },
        ),
      ),
    );
  }
  // 발송(SHIPPED)이 발주(PREPARING)보다 뒤 단계 — 나중 단계가 이긴다.
  // 취소는 그보다 더 뒤 단계라 가장 바깥에서 이긴다(2609_25 D14).
  // ⚠️ 발주 성공 판정은 `succeeded > 0` 이다. 쿠팡 거절도 200 + failed 라 `result != null`
  // 만으로 판정하면 실패한 주문이 상품준비중으로 보인다(D15).
  return BlocBuilder<OrderCancelBloc, OrderCancelState>(
    builder: (context, cancel) => BlocBuilder<ManualShipmentBloc,
        ManualShipmentState>(
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
                    (acknowledged ? OrderStatus.preparing : o.status));
            // 배지 = 방금 이 화면에서 한 동작의 결과가 우선 — 웹 `shownStage` 와 같은 식(D9).
            // 발주처리 성공이면 서버가 내부 단계를 지웠다(D14) → 배지 없음.
            final shownStage = acknowledged
                ? null
                : _AcknowledgeSection._internalMarked(internal)
                    ? InternalStage.internalPreparing
                    : o.internalStage;
            return rows(status, shownStage);
          },
        ),
      ),
    ),
  );
}

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

  /// 값 오른쪽에 붙는 위젯 — 주문번호 옆 내부 단계 배지(FEATURE_2609_75 / D9). null 이면 값만 그린다.
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

/// 「주문 정보」 card (FEATURE_2611_07 / R17 · D34 · D35) — [stage] = the
/// internal stage badge next to 「주문번호」, null = no badge (packing entry).
_InfoCard _orderInfoCard(OrderDetail detail, {InternalStage? stage}) =>
    _InfoCard(
      title: '주문 정보',
      rows: [
        _InfoRow(
          '주문번호',
          detail.externalOrderId,
          trailing: stage == null ? null : InternalStageBadge(stage: stage),
        ),
        _InfoRow('판매자', detail.sellerName ?? '-'),
        _InfoRow('판매처', detail.salesChannel),
        _InfoRow('주문자', detail.ordererName ?? '-'),
        _InfoRow('수취인', detail.receiverName ?? '-'),
        _InfoRow('결제일', formatOrderDateTime(detail.paidAt)),
      ],
    );

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

/// 「상품 목록」 card — every line of the order (D13 · R10). Only the line
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
          const Text(
            '상품 목록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

/// Where one 「상품 목록」 line comes from (FEATURE_2611_15 / D3 · D5 · D8 ·
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

/// 「송장 목록」 card — parcel chips, the shown chip's content below (D23 ·
/// D25 · D28 · D29 · D36 · R10). [onChangeBox] set = packing entry: a
/// 「포장 완료」 parcel gets [상자 변경] (D27).
class _ParcelListCard extends StatelessWidget {
  final OrderDetailState state;
  final void Function(OrderDetailParcel parcel)? onChangeBox;

  const _ParcelListCard({required this.state, this.onChangeBox});

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
            '송장 목록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (parcels.isEmpty || shown == null)
            const Text('송장이 없습니다')
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
            _InfoRow('송장번호', shown.invoiceNumber),
            _InfoRow('택배사', shown.carrierName ?? '-'),
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

/// Packing entry body (FEATURE_2611_07 / D14 · R16): 「주문 정보」 (no badge)
/// + 「상품 목록」 (no highlighted line) + 「송장 목록」 opened on [parcelId]
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
                  _orderInfoCard(detail),
                  const SizedBox(height: 12),
                  _ProductListCard(detail: detail),
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

/// Label sheet / shipment / order cancel switch tabs — the same idiom
/// (`SegmentedButton`) as the list screen's `ClaimTypeTabs`.
///
/// **Purpose**: splits the actions used one at a time on an order into tabs.
/// From the left: sheet · shipment · cancel, and **shipment is selected by
/// default** — most orders end in a shipment, and a cancel cannot be undone,
/// so it is safer to need one more tap.
/// An 11st order ([withCancel] false) gets its cancel tab from the 11st sale
/// refusal (FEATURE_2610_17 / D61) instead of the Coupang cancel section.
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

  /// false = 11st — no Coupang cancel BLoC (FEATURE_2610_17 / D12); the cancel
  /// tab is the 11st sale refusal on `ElevenstOrderActionBloc` (D61).
  final bool withCancel;

  const _ActionTabs({required this.order, required this.withCancel});

  @override
  State<_ActionTabs> createState() => _ActionTabsState();
}

enum _ActionTab { sheet, shipment, cancel }

class _ActionTabsState extends State<_ActionTabs> {
  _ActionTab _selected = _ActionTab.shipment; // 기본 = 왼쪽(발송처리)

  @override
  Widget build(BuildContext context) {
    if (!widget.withCancel) {
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

  /// [cancel] = null for an 11st order — there is no cancel BLoC to read.
  /// [elevenstForbidden] = an 11st write came back 403 (D61 cancel tab gate).
  Widget _buildTabs(
      BuildContext context, OrderCancelState? cancel, bool elevenstForbidden) {
    final order = widget.order;
    // FEATURE_2610_17 / D61: 11st sale refusal — paid / preparing, not fully
    // cancelled, and no 403 from an 11st write.
    final elevenstCancel = cancel == null &&
        !elevenstForbidden &&
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
              ? elevenstCancel
              : !cancel.forbidden &&
                  (order.status == OrderStatus.paid ||
                      order.status == OrderStatus.preparing);
          // 시트 탭은 늘 열려 있다 — 권한(403)·플랫폼 안내는 섹션이 자기 안에서 처리한다.
          // 여기서 막으면 비-ADMIN 에게 아무 탭도 안 보인다.
          final available = {
            _ActionTab.sheet: true,
            _ActionTab.shipment: canShip,
            _ActionTab.cancel: canCancel,
          };

          // 고른 탭을 쓸 수 없으면 왼쪽부터 첫 번째로 쓸 수 있는 탭을 보여준다 —
          // 파생값이라 setState 로 되돌리지 않는다.
          final selected = available[_selected]!
              ? _selected
              : _ActionTab.values.firstWhere((t) => available[t]!);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<_ActionTab>(
                  segments: [
                    const ButtonSegment<_ActionTab>(
                      value: _ActionTab.sheet,
                      label: Text('송장시트'),
                    ),
                    ButtonSegment<_ActionTab>(
                      value: _ActionTab.shipment,
                      label: const Text('발송처리'),
                      enabled: canShip,
                    ),
                    ButtonSegment<_ActionTab>(
                      value: _ActionTab.cancel,
                      label: const Text('주문 취소'),
                      enabled: canCancel,
                    ),
                  ],
                  selected: {selected},
                  showSelectedIcon: false,
                  onSelectionChanged: (set) =>
                      setState(() => _selected = set.first),
                ),
              ),
              const SizedBox(height: 12),
              Offstage(
                offstage: selected != _ActionTab.sheet,
                child: _OrderSheetSection(order: order),
              ),
              Offstage(
                offstage: selected != _ActionTab.shipment,
                // 내부 단계 주문(FEATURE_2609_75 / D27)은 입력 대신 안내 — 「송장」 + [저장된 송장으로 발송].
                // 판정 = 주문번호 옆 배지와 같은 식(`_buildInfoCard` 의 shownStage). 서버도 같은 문구로 거절한다(400).
                child: cancel == null
                    ? _ElevenstShipmentGate(order: order)
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
              ),
              Offstage(
                offstage: selected != _ActionTab.cancel,
                child: cancel == null
                    ? ElevenstSaleRefusalSection(order: order)
                    : _CancelSection(order: order),
              ),
            ],
          );
        },
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
/// form without a refetch (same `succeeded > 0` rule as the info card).
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
/// Order-status refresh row (FEATURE_2609_50).
///
/// Reads this order from Coupang again now to align the local status — the
/// manual way out for an order stuck outside the regular / nightly sync
/// windows.
///
/// 🔴 Drawn for Coupang orders only (D24 · FEATURE_2610_17 / D12). For other
/// orders the caller (`_buildContent`) does not build the row at all.
/// 🔴 When something changed it **goes back to the list** (D22) — this page is
/// a StatelessWidget using the [OrderItem] from the route `extra`, so it has no
/// way to refresh the status badge in place. Do not solve it with a new
/// `OrderDetailBloc` (having none is intended).
class _RefreshRow extends StatelessWidget {
  final OrderItem order;

  const _RefreshRow({required this.order});

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
      builder: (context, state) => Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: state.submitting
              ? null
              : () => context
                  .read<OrderRefreshBloc>()
                  .add(RefreshRequested([order.id])),
          icon: state.submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: Text(state.submitting ? '확인 중…' : '주문 상태 갱신'),
        ),
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
    // Only Coupang · 11st orders have the internal-stage BLoC (FEATURE_2611_23 / D51).
    if (order.platform != 'COUPANG' && order.platform != 'ELEVENST') {
      return _buildBody(context, null);
    }
    return BlocBuilder<OrderInternalStageBloc, OrderInternalStageState>(
      builder: (context, internal) => _buildBody(context, internal),
    );
  }

  /// [internal] = null for an order other than Coupang · 11st — no
  /// [내부 발주처리] there.
  Widget _buildBody(BuildContext context, OrderInternalStageState? internal) {
    return BlocBuilder<OrderAcknowledgeBloc, OrderAcknowledgeState>(
        builder: (context, state) {
          // Shown only for paid Coupang · 11st orders (D2·D10·D14 ·
          // FEATURE_2610_17 / D20). A 403 hides the entry point.
          if ((order.platform != 'COUPANG' && order.platform != 'ELEVENST') ||
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

          return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '발주처리',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (acknowledged)
                    const Text(
                      '발주처리 완료',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.successForeground,
                      ),
                    )
                  else ...[
                    // FEATURE_2610_17 / D52: 11st confirms this product only —
                    // its notice has no box number.
                    Text(
                      order.platform == 'ELEVENST'
                          ? '이 상품(주문 줄)이 발주확인 처리되어 배송준비중으로 바뀝니다. 되돌릴 수 없습니다.'
                          : '이 주문의 배송건(박스 ${order.externalBoxId ?? '-'}) 전체가 '
                              '상품준비중으로 전환됩니다. 되돌릴 수 없습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // [내부 발주처리] sits right next to [발주처리] and stays green — written here, not in the theme (D13 · D101).
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton(
                          onPressed:
                              busy ? null : () => _confirmAndSubmit(context),
                          child: state.submitting
                              ? const AppBusyLabel('발주처리')
                              : const Text('발주처리'),
                        ),
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
                      ],
                    ),
                  ],
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
              ),
          );
        },
    );
  }

  /// 되돌릴 수 없는 작업이라 확인을 반드시 거친다. 일괄과 **같은 UseCase·같은 엔드포인트**다(D6).
  /// 내부 단계 주문이면(방금 이 화면에서 내부 발주한 경우 포함) D14 안내 문구로 묻는다.
  Future<void> _confirmAndSubmit(BuildContext context) async {
    final bloc = context.read<OrderAcknowledgeBloc>();
    final reserved = order.internalStage != null ||
        ((order.platform == 'COUPANG' || order.platform == 'ELEVENST') &&
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
/// and fixing a wrong invoice (Coupang only — 11st has no update, D21).
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

  const _ManualShipmentSection(
      {required this.order, this.modePicker, this.altForm});

  @override
  State<_ManualShipmentSection> createState() => _ManualShipmentSectionState();
}

class _ManualShipmentSectionState extends State<_ManualShipmentSection> {
  final TextEditingController _invoiceController = TextEditingController();

  /// 이미 발송처리된 주문은 입력칸을 감춰 둔다 — [송장 수정하기] 를 눌러야 열린다.
  /// 실수로 정상 송장을 덮어쓰는 경로를 한 번 막는 것이라 미발송 주문에는 영향이 없다.
  bool _editing = false;

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
        // 미발송이면 늘 열려 있고, 발송된 건은 [송장 수정하기] 를 누른 뒤에만 열린다.
        final formOpen = !shipped || _editing;

        return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '발송처리',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                if (shipped) ...[
                  const SizedBox(height: 8),
                  Text(
                    formOpen
                        ? '이미 발송처리된 주문입니다. 입력한 운송장으로 송장 수정을 요청합니다.'
                        : '이미 발송처리된 주문입니다. 운송장을 고치려면 [송장 수정하기] 를 누르세요.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warningForeground,
                    ),
                  ),
                ],
                if (!formOpen) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed:
                        locked ? null : () => setState(() => _editing = true),
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

  /// Coupang · 11st — the platforms the sheet serves (FEATURE_2610_17 / D2).
  bool get _isMarketOrder =>
      order.platform == 'COUPANG' || order.platform == 'ELEVENST';

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
            FilledButton.icon(
              onPressed: _isMarketOrder
                  ? () => context
                      .read<OrderSheetBloc>()
                      .add(LoadOrderSheet(order.id))
                  : null,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('엑셀 다운로드'),
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
