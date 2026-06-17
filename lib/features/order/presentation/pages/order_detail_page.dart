import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/order_item.dart';

/// 주문 상세 페이지
///
/// **용도**: 주문내역 목록에서 선택한 단일 주문 항목의 전체 정보를 표시.
/// 프론트엔드 주문관리 > 주문내역의 `OrderDetailsModal`(읽기 전용)을 모바일로 이식.
///
/// **데이터 출처**:
/// 프론트와 동일하게 주문 상세 API는 존재하지 않으므로 별도 조회(BLoC) 없이
/// 목록에서 받은 [OrderItem]을 go_router `extra`로 전달받아 그대로 표시한다.
/// → 새로고침/딥링크 등으로 [order]가 null이면 목록으로 복귀.
///
/// **표시 필드(프론트 OrderDetailsModal과 동일)**:
/// 플랫폼 / 주문번호 / 박스 ID / 아이템 ID / 상품명 /
/// 주문수량 / 취소수량 / 보류수량 / 구매가능수량 / 상태 / 결제일 / 마켓 계정 ID
///
/// **UI**: 다른 상세 페이지(ProductListingDetailPage 등)와 동일한
/// `_InfoCard` / `_InfoRow` 카드 레이아웃을 따른다.
class OrderDetailPage extends StatelessWidget {
  final OrderItem? order;

  const OrderDetailPage({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '주문 상세',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.orderHistoryPath),
      body: order == null ? _buildMissing(context) : _buildContent(order!),
    );
  }

  // extra 로 전달된 주문 정보가 없는 경우(딥링크/새로고침) 목록 복귀를 유도한다.
  Widget _buildMissing(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('주문 정보를 찾을 수 없습니다.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go(Routes.orderHistoryPath),
            child: const Text('주문내역으로'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(OrderItem o) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(
            title: '기본 정보',
            rows: [
              _InfoRow('플랫폼', o.platform),
              _InfoRow('주문번호', o.externalOrderId),
              _InfoRow('박스 ID', o.externalBoxId ?? '-'),
              _InfoRow('아이템 ID', o.externalItemId),
              _InfoRow('상품명', o.itemName ?? '-'),
              _InfoRow('상태', o.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: '수량 정보',
            rows: [
              _InfoRow('주문수량', '${o.orderCount}'),
              _InfoRow('취소수량', '${o.cancelCount}'),
              _InfoRow('보류수량', '${o.holdCount}'),
              _InfoRow('구매가능수량', '${o.purchasableQty}'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: '기타',
            rows: [
              _InfoRow('결제일', _formatDate(o.paidAt)),
              _InfoRow('마켓 계정 ID', '${o.marketplaceAccountId}'),
            ],
          ),
          const SizedBox(height: 80),
        ],
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

/// 정보 카드 (제목 + 라벨/값 행 목록). 다른 상세 페이지와 동일한 스타일.
class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
