import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import '../../domain/entities/order_item.dart';

/// 내부 단계 배지 — 「내부 상품준비중」·「발송대기중」(FEATURE_2609_75 / D9·D10·D11).
///
/// **용도**: 주문 카드(주문내역·출고관리 공용 [OrderCard])와 주문 상세(기본 정보 카드 `주문번호` 행)의 주문번호 옆에 붙인다.
/// **파일**: lib/features/order/presentation/widgets/internal_stage_badge.dart
///
/// **사용 예제**:
/// ```dart
/// InternalStageBadge(stage: order.internalStage)
/// ```
///
/// ⚠️ 문구는 [kInternalStageLabels] 에서만 온다 — 여기서 글자를 새로 쓰지 않는다.
/// ❌ `status`(쿠팡 상태)로 판정하지 않는다. [stage] 가 null 이면 아무것도 그리지 않는다.
class InternalStageBadge extends StatelessWidget {
  final InternalStage? stage;

  const InternalStageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final s = stage;
    if (s == null) return const SizedBox.shrink();
    final isInternal = s == InternalStage.internalPreparing;
    final surface = isInternal ? AppColors.infoSurface : AppColors.warningSurface;
    final border = isInternal ? AppColors.infoBorder : AppColors.warningBorder;
    final foreground =
        isInternal ? AppColors.infoForeground : AppColors.warningForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInternal ? Icons.assignment_turned_in : Icons.schedule,
            size: 12,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            kInternalStageLabels[s]!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
