import 'package:flutter/material.dart';

import '../../domain/entities/claim.dart';

/// 클레임 상태 칩 바 — 건수 배지를 단 칩을 가로 스크롤로 배치한다.
///
/// **용도**: 선택된 상태만 목록에 남긴다. 활성 칩을 다시 누르면 [onSelect] 에 null 을 전달해
/// 필터를 해제(전체)한다 — '전체' 칩은 없다(`OrderStatusFilterBar` 와 같은 규칙).
/// **필수 규칙**: 후보 상태는 [statuses] 파라미터로 넘긴다. 화면에서 칩을 다시 만들지 말 것.
/// **파일**: lib/features/claim/presentation/widgets/claim_status_filter_bar.dart
///
/// **사용 예제**:
/// ```dart
/// ClaimStatusFilterBar(
///   selectedStatus: s.selectedStatus,
///   counts: s.statusCounts,
///   onSelect: (status) => bloc.add(SelectStatus(status: status)),
/// )
/// ```
///
/// ⚠️ [counts] 는 **목록과 같은 소스**에서 파생한 값이어야 한다 — 배지와 목록이 다른 집합을
/// 세면 화면이 어긋난다.
/// ❌ 라벨표 사본 금지 — 한글 라벨은 `getClaimStatusLabel` 하나뿐이다.
class ClaimStatusFilterBar extends StatelessWidget {
  final ClaimStatus? selectedStatus;
  final Map<ClaimStatus, int> counts;
  final void Function(ClaimStatus? status) onSelect;

  /// 후보 상태. 기본값은 반품에서 실제로 나타나는 3종(PLAN §3.1).
  /// 교환 상태는 08 이 추가한다.
  final List<ClaimStatus> statuses;

  const ClaimStatusFilterBar({
    super.key,
    required this.selectedStatus,
    required this.counts,
    required this.onSelect,
    this.statuses = returnStatusFilters,
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
              label: getClaimStatusLabel(status),
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
