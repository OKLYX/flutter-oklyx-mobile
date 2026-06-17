import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// 주문관리 > 주문내역 페이지 (Dummy)
///
/// **용도**: Coupang 등 외부 플랫폼에서 동기화된 주문 목록 조회.
/// 프론트엔드의 주문관리 > 주문내역(dashboard/orders) 기능을 모바일로 이식한
/// 화면으로, 현재는 더미 데이터로 레이아웃만 구성한 placeholder.
///
/// **참고(Frontend)**: nextjs-oklyx-front/src/app/dashboard/orders
/// - 판매자 필터 + 조회 + 동기화 버튼
/// - 컬럼: 주문번호 / 상품명 / 상태 / 주문수량 / 취소 / 보류 / 구매가능수량 / 결제일
///
/// **다음 단계**: domain/data/presentation 레이어 + OrderBloc 구현으로
/// 실제 API(GET /api/orders) 연동 예정.
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  // Dummy rows mirroring the frontend OrderTable columns.
  static const List<_DummyOrder> _dummyOrders = [
    _DummyOrder(
      externalOrderId: '20260617-0001',
      itemName: '샘플 상품 A',
      status: 'ACCEPT',
      orderCount: 3,
      cancelCount: 0,
      holdCount: 0,
      purchasableQty: 3,
      paidAt: '2026-06-17 09:12',
    ),
    _DummyOrder(
      externalOrderId: '20260617-0002',
      itemName: '샘플 상품 B',
      status: 'ACCEPT',
      orderCount: 5,
      cancelCount: 1,
      holdCount: 0,
      purchasableQty: 4,
      paidAt: '2026-06-17 10:48',
    ),
    _DummyOrder(
      externalOrderId: '20260616-0042',
      itemName: '샘플 상품 C',
      status: 'INSTRUCT',
      orderCount: 2,
      cancelCount: 0,
      holdCount: 1,
      purchasableQty: 1,
      paidAt: '2026-06-16 18:03',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '주문내역',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for the seller filter + search/sync controls (frontend OrderSearchCard).
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '판매자',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: '전체',
                        items: const [
                          DropdownMenuItem(value: '전체', child: Text('전체')),
                        ],
                        onChanged: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: null,
                      child: const Text('조회'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '총 ${_dummyOrders.length}건 (Dummy)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  bottom: kBottomNavigationBarHeight + 24,
                ),
                itemCount: _dummyOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _OrderCard(order: _dummyOrders[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _DummyOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.externalOrderId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(order.itemName, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _metric('주문수량', order.orderCount),
                _metric('취소', order.cancelCount),
                _metric('보류', order.holdCount),
                _metric('구매가능', order.purchasableQty),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '결제일 ${order.paidAt}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value) => Text(
        '$label $value',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      );
}

class _DummyOrder {
  final String externalOrderId;
  final String itemName;
  final String status;
  final int orderCount;
  final int cancelCount;
  final int holdCount;
  final int purchasableQty;
  final String paidAt;

  const _DummyOrder({
    required this.externalOrderId,
    required this.itemName,
    required this.status,
    required this.orderCount,
    required this.cancelCount,
    required this.holdCount,
    required this.purchasableQty,
    required this.paidAt,
  });
}
