import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';

/// 주문관리 > 주문내역 페이지 (조회 + 동기화)
///
/// **용도**: Coupang 등 외부 마켓플레이스에서 동기화된 주문 목록 조회 및 동기화.
/// 프론트엔드 주문관리 > 주문내역(dashboard/orders)을 모바일로 이식.
///
/// **기능(Frontend OrderContainer와 동일)**:
/// - 판매자 필터 드롭다운 (기존 seller 기능 재사용)
/// - 조회: GET /api/orders?sellerId=
/// - 동기화: POST /api/orders/sync?sellerId= → 신규/수정/취소 건수 배너 표시
/// - 상태 필터: 6개 상태 버튼(건수 배지) — 선택 상태만 표시, 재선택 시 전체
/// - 카드 항목(프론트 OrderTable과 동일): 주문번호 / 상품명 / 주문수량 / 취소 / 결제일
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderListBloc>()..add(LoadOrders()),
      child: const _OrderHistoryView(),
    );
  }
}

class _OrderHistoryView extends StatelessWidget {
  const _OrderHistoryView();

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '주문내역',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<OrderListBloc, OrderListState>(
        // 검색/동기화 중 발생한 일시적 오류는 SnackBar로 표시한다.
        listenWhen: (prev, curr) =>
            curr is OrderListLoaded && curr.actionError != null,
        listener: (context, state) {
          final message = (state as OrderListLoaded).actionError;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message ?? '요청에 실패했습니다.'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
              ),
            );
        },
        builder: (context, state) {
          if (state is OrderListInitial || state is OrderListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderListError) {
            return _ErrorRetry(
              message: state.message,
              onRetry: () => context.read<OrderListBloc>().add(LoadOrders()),
            );
          }

          final loaded = state as OrderListLoaded;
          return _LoadedBody(state: loaded);
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final OrderListState state;

  const _LoadedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state as OrderListLoaded;
    final bloc = context.read<OrderListBloc>();
    final busy = s.isSearching || s.isSyncing;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 판매자 필터 + 조회/동기화 컨트롤 (프론트 OrderSearchCard)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: s.selectedSellerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: '판매자',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('전체'),
                            ),
                            ...s.sellers.map(
                              (Seller seller) => DropdownMenuItem<int?>(
                                value: seller.id,
                                child: Text(
                                  seller.sellerName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: busy
                              ? null
                              : (value) =>
                                  bloc.add(SelectSeller(sellerId: value)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: busy ? null : () => bloc.add(SearchOrders()),
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => bloc.add(SyncOrders()),
                          icon: s.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync, size: 18),
                          label: Text(s.isSyncing ? '동기화 중...' : '동기화'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 동기화 결과 배너 (프론트 syncResult 배너와 동일)
          if (s.syncResult != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '동기화 완료 — 신규 ${s.syncResult!.newOrders}건, '
                '수정 ${s.syncResult!.updatedOrders}건, '
                '취소 ${s.syncResult!.canceledUpdated}건',
                style: TextStyle(fontSize: 13, color: Colors.green[800]),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 상태 필터 버튼 (프론트 OrderStatusFilter). 같은 버튼 재선택 시 전체 해제.
          _StatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: s.statusCounts,
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${s.filteredOrders.length}건',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (s.lastSyncedAt != null)
                Text(
                  '마지막 동기화: ${_formatDate(s.lastSyncedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: s.filteredOrders.isEmpty
                ? const Center(child: Text('조회 결과가 없습니다.'))
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight + 24,
                    ),
                    itemCount: s.filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _OrderCard(order: s.filteredOrders[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 항목 탭 → 주문 상세 페이지로 이동 (선택한 OrderItem 을 extra 로 전달).
        onTap: () => context.push(Routes.orderHistoryDetailPath, extra: order),
        child: Padding(
          padding: const EdgeInsets.all(12),
          // 카드 항목은 프론트 OrderTable 컬럼과 동일: 주문번호 / 상품명 / 주문수량 / 취소 / 결제일.
          child: Column(
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
              Text(order.itemName ?? '-', style: const TextStyle(fontSize: 13)),
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
                '결제일 ${_formatDate(order.paidAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, int value) => Text(
        '$label $value',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      );
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('재시도')),
        ],
      ),
    );
  }
}

/// 상태 필터 버튼 바 (프론트 OrderStatusFilter와 동일).
///
/// 6개 상태 버튼을 가로 스크롤로 배치하고, 각 버튼에 해당 상태의 건수 배지를
/// 표시한다. 활성 버튼을 다시 누르면 [onSelect]에 null을 전달해 필터를
/// 해제(전체)한다.
class _StatusFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final Map<String, int> counts;
  final void Function(String? status) onSelect;

  const _StatusFilterBar({
    required this.selectedStatus,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kOrderStatuses.map((status) {
          final isActive = selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StatusChip(
              label: getOrderStatusLabel(status),
              count: counts[status] ?? 0,
              isActive: isActive,
              onTap: () => onSelect(isActive ? null : status),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isActive ? Colors.white : Colors.grey[800];
    return Material(
      color: isActive ? Colors.blue[600] : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ISO LocalDateTime → 'yyyy-MM-dd HH:mm'. null/파싱 실패 시 '-' 또는 원본 반환.
String _formatDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}
