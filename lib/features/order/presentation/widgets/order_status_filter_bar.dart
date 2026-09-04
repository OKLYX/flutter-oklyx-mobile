import 'package:flutter/material.dart';

import '../../domain/entities/order_item.dart';

/// 상태 칩 바 — 주문내역(전 상태)·출고관리(미발송 2종)가 공유한다.
///
/// **용도**: 상태별 건수 배지를 단 칩을 가로 스크롤로 배치하고, 선택된 상태만 목록에 남긴다.
/// 활성 칩을 다시 누르면 [onSelect] 에 null 을 전달해 필터를 해제(전체)한다 —
/// 모바일에는 '전체' 칩이 없다(PLAN 2609_15 D9).
/// **필수 규칙**: 후보 상태는 반드시 [statuses] 파라미터로 넘긴다. 화면에서 칩을 다시 만들지 말 것.
/// **파일**: lib/features/order/presentation/widgets/order_status_filter_bar.dart
///
/// **사용 예제**:
/// ```dart
/// // 주문내역 — 전 상태(기본값)
/// OrderStatusFilterBar(
///   selectedStatus: s.selectedStatus,
///   counts: counts,
///   onSelect: (status) => bloc.add(SelectStatus(status: status)),
/// )
///
/// // 출고관리 — 미발송 2종
/// OrderStatusFilterBar(
///   selectedStatus: s.selectedStatus,
///   counts: counts,
///   onSelect: (status) => bloc.add(SelectStatus(status: status)),
///   statuses: kShipmentStatuses,
/// )
/// ```
///
/// ⚠️ [counts] 는 **목록과 같은 소스**에서 파생한 값이어야 한다 — 배지와 목록이 다른 집합을
/// 세면 화면이 어긋난다.
/// ❌ 라벨표 사본 금지 — 한글 라벨은 `getOrderStatusLabel` 하나뿐이다.
class OrderStatusFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final Map<String, int> counts;
  final void Function(String? status) onSelect;

  /// 후보 상태. 기본값이 현행(전 상태)이라 주문내역은 표시 무변경.
  final List<String> statuses;

  const OrderStatusFilterBar({
    super.key,
    required this.selectedStatus,
    required this.counts,
    required this.onSelect,
    this.statuses = kOrderStatuses,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
