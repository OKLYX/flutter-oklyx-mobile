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
import '../widgets/purchase_intake_card.dart';
import '../widgets/purchase_line_section.dart';
import '../widgets/purchase_product_card.dart';

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

/// 구매목록 상품 상세 (2026-10-09, 카드 펼침 토글을 대체).
///
/// **용도**: 한 상품(물품)의 요약 카드 + 입고 기록 + 최근 구매이력 + 채널 칩·주문 줄.
/// 구매목록 탭과 구매완료 탭이 **같은 페이지**를 연다(D21).
/// **위치**: lib/features/purchase_list/presentation/pages/purchase_product_detail_page.dart
///
/// **사용 예제**:
/// ```dart
/// context.push(
///   Routes.purchaseProductDetailPath,
///   extra: PurchaseProductDetailArgs(bloc: bloc, productId: item.productId),
/// );
/// ```
///
/// ⚠️ 상품은 bloc 상태(현재 탭 목록)에서 productId 로 찾는다. 입고로 매입 필요 수량이
///    0 이 되면 재조회된 구매목록에서 빠진다 — 그때는 마지막으로 본 값을 그대로 두고
///    안내 줄을 띄운다(페이지를 강제로 닫지 않는다 — 정정 입고를 이어서 할 수 있게).
/// ⚠️ 오류·입고 결과 알림은 아래에 깔린 목록 페이지의 listener 가 띄운다
///    (여기서 또 띄우면 두 번 뜬다).
/// ❌ 입고 입력을 목록 카드로 되돌리지 말 것 — 펼침 토글은 이 페이지로 대체됐다.
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
        : state.items;
    for (final item in source) {
      if (item.productId == widget.args.productId) {
        return item;
      }
    }
    return null;
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
    return [
      if (removed) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.successSurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '매입 필요 수량이 없어 구매목록에서 빠졌습니다. '
            '아래 숫자는 마지막으로 본 값입니다.',
            style: TextStyle(fontSize: 12, color: AppColors.successForeground),
          ),
        ),
        const SizedBox(height: 12),
      ],
      PurchaseProductCard(item: item),
      const SizedBox(height: 12),
      PurchaseIntakeCard(
        productId: item.productId,
        sellers: state?.sellers ?? const [],
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
              busy: busy,
              onRemoveManualLine: (itemId) =>
                  bloc.add(AdjustManualQty(itemId: itemId, manualQty: 0)),
            ),
          ],
        ),
      ),
    ];
  }
}
