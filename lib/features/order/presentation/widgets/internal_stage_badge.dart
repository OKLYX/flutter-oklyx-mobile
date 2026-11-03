import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import '../../domain/entities/order_item.dart';

/// Internal stage badge — 「내부 상품준비중」 · 「발송대기중」 (FEATURE_2609_75 /
/// D9 · D10 · D11).
///
/// **Purpose**: placed next to the order number on the order card (the
/// [OrderCard] shared by order history and outbound) and on the order detail
/// (「주문 정보」 card 「주문번호」 row, FEATURE_2611_07 / D34).
/// **File**: lib/features/order/presentation/widgets/internal_stage_badge.dart
///
/// **Example**:
/// ```dart
/// InternalStageBadge(stage: order.internalStage)
/// ```
///
/// ⚠️ The text comes only from [kInternalStageLabels] — never write new text
/// here.
/// ❌ Never decide by `status` (the Coupang status). Draws nothing when
/// [stage] is null.
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
