import 'package:flutter/material.dart';

import '../../domain/entities/unmapped_order.dart';

/// 미매핑주문 섹션 (프론트 UnmappedOrdersSection와 동일).
///
/// 옵션이 등록되지 않아 구성품 전개가 불가한 주문을 amber 박스로 안내한다.
/// 항목이 없으면 아무것도 그리지 않는다.
class UnmappedOrdersSection extends StatelessWidget {
  final List<UnmappedOrder> orders;

  const UnmappedOrdersSection({required this.orders, super.key});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: Colors.amber[800]),
              const SizedBox(width: 6),
              Text(
                '미등록 주문 ${orders.length}건',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '옵션이 등록되지 않아 구성품 전개가 불가한 주문입니다. 옵션을 등록해 주세요.',
            style: TextStyle(fontSize: 12, color: Colors.amber[900]),
          ),
          const SizedBox(height: 8),
          ...orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.itemName.isEmpty ? '(이름 없음)' : o.itemName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '옵션ID ${o.externalItemId} · 주문 ${o.orderCount}건',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '총 주문수량 ${o.purchasableQty}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[900],
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
