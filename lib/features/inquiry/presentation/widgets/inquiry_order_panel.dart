import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_item.dart';
import '../../domain/entities/inquiry_detail.dart';

/// 문의 상세의 관련 주문 / 관련 상품 패널 — 3가지 상태를 그린다.
///
/// **용도**: 문의가 걸린 주문의 라인 목록(합포장이면 같은 주문의 다른 라인도), 주문 연결이
/// 없으면 상품(셀) 정보, 둘 다 없으면 안내 한 줄.
/// **파일**: lib/features/inquiry/presentation/widgets/inquiry_order_panel.dart
///
/// ⚠️ 주문 미연결은 **정상**이다(2609_23 D15 — 상품문의는 주문 없는 질문이 다수다).
/// 붉은 경고로 그리지 말 것.
/// ⚠️ 라인 상태 라벨은 주문 기능의 기존 함수 2개를 쓴다 —
/// `getOrderStatusLabel(orderStatusFrom(status))`. 문의 전용 상태 enum·라벨 맵을 만들면
/// 같은 주문이 주문 화면과 문의 화면에서 다른 라벨로 보인다.
/// ❌ 금액 표시 금지 — 서버가 내려주지 않는다.
class InquiryOrderPanel extends StatelessWidget {
  final RelatedOrder? relatedOrder;
  final RelatedListing? relatedListing;

  const InquiryOrderPanel({
    super.key,
    required this.relatedOrder,
    required this.relatedListing,
  });

  @override
  Widget build(BuildContext context) {
    final order = relatedOrder;
    if (order != null) return _buildOrder(context, order);

    final listing = relatedListing;
    if (listing != null) return _buildListing(context, listing);

    return _Panel(
      title: '관련 주문',
      children: [
        Text(
          '연결된 주문·상품 정보가 없습니다.',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildOrder(BuildContext context, RelatedOrder order) => _Panel(
        title: '관련 주문',
        children: [
          _Row('주문번호', order.externalOrderId ?? '-'),
          _Row(
            '주문일',
            formatOrderDateTime(order.paidAt?.toIso8601String()),
          ),
          _Row('주문자', order.ordererName ?? '-'),
          _Row('수취인', order.receiverName ?? '-'),
          const SizedBox(height: 4),
          ...order.lines.map((line) => _LineTile(line: line)),
          const SizedBox(height: 8),
          // ⚠️ 주문 상세는 `extra` 로 `OrderItem` 을 받는다 — 우리는 그 객체가 없어
          // orderItemId 만으로 push 하면 상세가 '주문 정보를 찾을 수 없습니다' 를 띄운다.
          // 그래서 **주문내역 목록**으로 보낸다(웹과 같은 처리). 주문번호는 위에 있으니
          // 사용자가 그 화면의 검색에 쓴다.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(Routes.orderHistoryPath),
              child: const Text('주문내역에서 찾기'),
            ),
          ),
        ],
      );

  Widget _buildListing(BuildContext context, RelatedListing listing) => _Panel(
        title: '관련 상품',
        children: [
          Text(
            '이 문의는 주문과 연결되지 않았습니다. '
            '(구매 전 문의이거나 주문이 아직 적재되지 않았습니다)',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _Row('판매상품', listing.listingName ?? '-'),
          _Row('옵션', listing.optionName ?? '-'),
        ],
      );
}

/// 라인 1개. [RelatedOrderLine.isInquiryLine] 이면 강조한다(이 문의가 가리키는 라인).
class _LineTile extends StatelessWidget {
  final RelatedOrderLine line;

  const _LineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlight = line.isInquiryLine;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? scheme.primaryContainer : null,
        border: Border.all(
          color: highlight ? scheme.primary : scheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.itemName ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                getOrderStatusLabel(orderStatusFrom(line.status)),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '수량 ${line.orderCount}'
            '${line.cancelCount > 0 ? ' · 취소 ${line.cancelCount}' : ''}',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          if (highlight) ...[
            const SizedBox(height: 4),
            Text(
              '이 문의의 상품',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 제목 + 내용 카드. 클레임 상세의 `_InfoCard` 와 같은 스타일이다.
class _Panel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Panel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
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
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
