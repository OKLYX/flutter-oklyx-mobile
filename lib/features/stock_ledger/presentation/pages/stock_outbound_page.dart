import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/outbound_order.dart';
import '../../domain/entities/stock_enums.dart';
import '../bloc/stock_ledger_bloc.dart';
import '../bloc/stock_ledger_event.dart';
import '../bloc/stock_ledger_state.dart';
import '../widgets/outbound_order_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// 출고 확인 페이지 (`/stock/outbound`, PLAN 2609_28 D11·D12·D13).
///
/// 나갈 주문(결제완료·상품준비중)을 오래된 순으로 보여주고, 물품 줄마다 확인을 기록한다.
///
/// ❌ 물품 검색으로 출고를 시작하는 진입점을 만들지 않는다 — 주문 연결이 끊긴다(D11).
/// ❌ 확인을 모아 일괄 전송하지 않는다 — 중단 복구가 안 된다(D12).
/// ⚠️ 전개 불가 섹션은 접거나 숨기지 않는다 — 조용히 넘기면 재고가 틀린다(D13).
class StockOutboundPage extends StatelessWidget {
  const StockOutboundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StockLedgerBloc>()..add(LoadOutbound()),
      child: const _StockOutboundView(),
    );
  }
}

class _StockOutboundView extends StatelessWidget {
  const _StockOutboundView();

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '출고 확인',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<StockLedgerBloc, StockLedgerState>(
        listenWhen: (prev, curr) =>
            curr is StockLedgerLoaded &&
            (curr.actionError != null || curr.actionMessage != null),
        listener: (context, state) {
          final loaded = state as StockLedgerLoaded;
          if (loaded.actionError != null) {
            showErrorToast(context, loaded.actionError!);
          } else {
            showSuccessToast(context, loaded.actionMessage!);
          }
          context.read<StockLedgerBloc>().add(ClearStockLedgerNotice());
        },
        builder: (context, state) {
          if (state is StockLedgerInitial || state is StockLedgerLoading) {
            return const AppPageBody(children: [AppLoading()]);
          }
          if (state is StockLedgerError) {
            return AppPageBody(
              children: [
                AppErrorBox(
                  message: state.message,
                  action: FilledButton(
                    onPressed: () =>
                        context.read<StockLedgerBloc>().add(LoadOutbound()),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            );
          }
          final loaded = state as StockLedgerLoaded;
          final bloc = context.read<StockLedgerBloc>();
          final busy = loaded.actionInProgressKey != null;

          return AppPageBody(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SellerFilterDropdown(
                      sellers: loaded.sellers,
                      selectedSellerId: loaded.sellerId,
                      enabled: !busy,
                      onChanged: (value) =>
                          bloc.add(LoadOutbound(sellerId: value)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => bloc.add(LoadOutbound(sellerId: loaded.sellerId)),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('새로고침'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (loaded.outbound.isEmpty)
                const AppEmpty('출고할 주문이 없습니다.')
              else
                for (var i = 0; i < loaded.outbound.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  OutboundOrderCard(
                    key: ValueKey(loaded.outbound[i].orderLineId),
                    order: loaded.outbound[i],
                    busy: busy,
                    inProgressProductId:
                        _inProgressProductId(loaded, loaded.outbound[i]),
                    onConfirm: (productId, quantity) => bloc.add(
                      ConfirmOutbound(
                        orderLineId: loaded.outbound[i].orderLineId,
                        productId: productId,
                        quantity: quantity,
                        movedOn: _today(),
                      ),
                    ),
                  ),
                ],
              if (loaded.unexpanded.isNotEmpty)
                _UnexpandedSection(items: loaded.unexpanded),
            ],
          );
        },
      ),
    );
  }

  /// 처리 중인 줄(주문 라인 × 물품)만 스피너를 띄운다.
  int? _inProgressProductId(StockLedgerLoaded state, OutboundOrder order) {
    final key = state.actionInProgressKey;
    if (key == null) return null;
    for (final product in order.products) {
      if (key ==
          StockLedgerBloc.outboundActionKey(
              order.orderLineId, product.productId)) {
        return product.productId;
      }
    }
    return null;
  }

  static String _today() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

/// 전개 불가 섹션 — 하단 고정. 확인 버튼 없음, 접기 없음(D13).
class _UnexpandedSection extends StatelessWidget {
  final List<OutboundUnexpanded> items;

  const _UnexpandedSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        border: Border.all(color: AppColors.warningForeground),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠ 전개 불가 ${items.length}건',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.externalOrderId,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${item.itemName} — ${unexpandedReasonLabel(item.reason)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
