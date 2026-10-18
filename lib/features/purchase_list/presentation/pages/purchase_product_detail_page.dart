import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/purchase_list_item.dart';
import '../bloc/purchase_list_bloc.dart';
import '../bloc/purchase_list_event.dart';
import '../bloc/purchase_list_state.dart';
import '../bloc/purchase_setting_bloc.dart';
import '../widgets/purchase_intake_card.dart';
import '../widgets/purchase_line_section.dart';
import '../widgets/purchase_product_card.dart';
import '../widgets/purchase_share_actions.dart';

/// `Routes.purchaseProductDetail` 의 extra.
///
/// 목록 페이지의 [PurchaseListBloc] 을 **그대로** 넘긴다 — 상세에서 입고·수동 제거를 하면
/// 같은 bloc 이 목록을 재조회하므로, 뒤로 가면 목록 숫자가 이미 새것이다.
/// ⚠️ `context.push` 로만 연다(목록 페이지가 아래에 살아 있어야 bloc 이 닫히지 않는다).
class PurchaseProductDetailArgs {
  final PurchaseListBloc bloc;
  final int productId;

  const PurchaseProductDetailArgs({
    required this.bloc,
    required this.productId,
  });
}

/// Purchase list product detail (2026-10-09, replaced the card expand toggle).
///
/// **Purpose**: one product's summary card + intake + recent purchases + seller
/// shares (「전체」 only, FEATURE_2610_09 D83) + channel chips and lines. The
/// list tab, the 「오늘 넘김」 group and the completed tab open **the same page**
/// (D21).
/// **File**: lib/features/purchase_list/presentation/pages/purchase_product_detail_page.dart
///
/// **Usage**:
/// ```dart
/// context.push(
///   Routes.purchaseProductDetailPath,
///   extra: PurchaseProductDetailArgs(bloc: bloc, productId: item.productId),
/// );
/// ```
///
/// ⚠️ The product is found by productId in the bloc state (the current tab's
///    rows; the list tab also searches 「오늘 넘김」). When it leaves that tab the
///    last seen values stay and a notice line says why (D64 — deleting its last
///    manual line here, else moving it to another seller here, else by tab).
///    The page is not closed — a correction intake can follow.
/// ⚠️ Errors and intake notices are shown by the list page's listener underneath
///    (showing them here too would show them twice).
/// ❌ Do not move the intake input back to the list card — this page replaced
///    the expand toggle.
class PurchaseProductDetailPage extends StatefulWidget {
  final PurchaseProductDetailArgs args;

  const PurchaseProductDetailPage({required this.args, super.key});

  @override
  State<PurchaseProductDetailPage> createState() =>
      _PurchaseProductDetailPageState();
}

class _PurchaseProductDetailPageState extends State<PurchaseProductDetailPage> {
  /// Last item seen in the bloc state; kept when a refresh drops it from the
  /// list.
  PurchaseListItem? _lastItem;

  PurchaseListItem? _find(PurchaseListLoaded state) {
    final source = state.activeTab == PurchaseTab.completed
        ? (state.completedItems ?? const <PurchaseListItem>[])
        : [...state.items, ...state.skippedToday];
    for (final item in source) {
      if (item.productId == widget.args.productId) {
        return item;
      }
    }
    return null;
  }

  /// D64: the first sentence of the "left this tab" notice. A manual line just
  /// deleted here wins, then a manual line just moved to another seller here,
  /// then the tab.
  String _removedReason(PurchaseListLoaded? state, PurchaseListItem item) {
    final deleted = state?.deletedManualItemId;
    if (deleted != null && item.lines.any((line) => line.itemId == deleted)) {
      return '수동 줄을 지워 목록에서 빠졌습니다. ';
    }
    final moved = state?.movedManualItemId;
    if (moved != null && item.lines.any((line) => line.itemId == moved)) {
      return '수동 줄을 다른 판매자에게 넘겨 목록에서 빠졌습니다. ';
    }
    return state?.activeTab == PurchaseTab.completed
        ? '구매목록으로 돌아갔습니다. '
        : '매입 완료로 옮겨졌습니다. ';
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: widget.args.bloc,
        child: BlocBuilder<PurchaseListBloc, PurchaseListState>(
          builder: (context, state) {
            final loaded = state is PurchaseListLoaded ? state : null;
            final found = loaded == null ? null : _find(loaded);
            if (found != null) {
              _lastItem = found;
            }
            final item = found ?? _lastItem;
            final busy = loaded == null ||
                loaded.isRefreshing ||
                loaded.isSyncing ||
                loaded.isLoadingCompleted;

            return ScaffoldWithNavBar(
              title: item?.productName ?? '상품 상세',
              navBarIndex: 2,
              onBackPressed: () => context.pop(),
              body: AppPageBody(
                extraBottom: MediaQuery.of(context).viewInsets.bottom,
                children: item == null
                    ? [const Center(child: Text('상품을 찾을 수 없습니다.'))]
                    : _content(context, item, loaded, busy,
                        removed: found == null && !busy),
              ),
            );
          },
        ),
      );

  List<Widget> _content(
    BuildContext context,
    PurchaseListItem item,
    PurchaseListLoaded? state,
    bool busy, {
    required bool removed,
  }) {
    final bloc = widget.args.bloc;
    final sellers = state?.sellers ?? const [];
    final stockLinked =
        context.watch<PurchaseSettingBloc>().state.stockLinked == true;
    return [
      if (removed) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.successSurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${_removedReason(state, item)}아래 숫자는 마지막으로 본 값입니다.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.successForeground,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      PurchaseProductCard(item: item),
      const SizedBox(height: 12),
      if (state != null && state.filterSellerId == null) ...[
        _sharesCard(context, item, busy),
        const SizedBox(height: 12),
      ],
      PurchaseIntakeCard(
        productId: item.productId,
        sellers: sellers,
        // D9 · D53: the page's seller filter, else the only seller, else empty.
        initialSellerId: state?.filterSellerId ??
            (sellers.length == 1 ? sellers.first.id : null),
        hideSeller: sellers.length == 1,
        stockLinked: stockLinked,
        busy: busy,
        onSubmit: ({
          required int sellerId,
          required String purchasedOn,
          required int quantity,
          double? totalAmount,
          double? unitPrice,
          required bool reflectToBasePrice,
        }) =>
            bloc.add(RecordPurchase(
          productId: item.productId,
          sellerId: sellerId,
          purchasedOn: purchasedOn,
          quantity: quantity,
          totalAmount: totalAmount,
          unitPrice: unitPrice,
          reflectToBasePrice: reflectToBasePrice,
        )),
      ),
      const SizedBox(height: 4),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주문 줄',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PurchaseLineSection(
              lines: item.lines,
              sellers: sellers,
              busy: busy,
              onSaveManualQty: (itemId, qty) =>
                  bloc.add(AdjustManualQty(itemId: itemId, manualQty: qty)),
              onChangeManualSeller: (itemId, sellerId) => bloc.add(
                ChangeManualSeller(itemId: itemId, sellerId: sellerId),
              ),
              onRemoveManualLine: (itemId) =>
                  bloc.add(DeleteManualLine(itemId: itemId)),
            ),
          ],
        ),
      ),
    ];
  }

  /// 「전체」: one row per seller share with its numbers, tag and buttons
  /// (FEATURE_2610_09 D59 · D83).
  Widget _sharesCard(BuildContext context, PurchaseListItem item, bool busy) {
    final bloc = widget.args.bloc;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '판매자 몫',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          for (final share in item.shares)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        share.sellerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TargetMetTag(share: share),
                    ],
                  ),
                  Text(
                    '필요 ${share.neededQty} · 매입 완료 ${share.purchasedQty}'
                    ' · 매입 필요 ${share.remainingQty}',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 4),
                  PurchaseShareActions(
                    share: share,
                    busy: busy,
                    onCheck: (status) => bloc.add(CheckShare(
                      productId: item.productId,
                      sellerId: share.sellerId,
                      status: status,
                    )),
                    onCancel: (checkId) =>
                        bloc.add(CancelShareCheck(checkId: checkId)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
