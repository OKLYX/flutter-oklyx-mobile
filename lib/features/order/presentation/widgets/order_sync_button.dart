import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Sync pill on the right of the order history · shipment management title
/// bar (FEATURE_2611_32 / D5 · D6).
///
/// **Purpose**: a status dot, the last sync time (relative) and the sync
/// icon in one pill. Tapping it starts the same sync as the old [동기화]
/// button.
/// **File**: lib/features/order/presentation/widgets/order_sync_button.dart
///
/// **Usage**:
/// ```dart
/// appBarActions: [
///   OrderSyncButton(
///     lastSyncedAt: state.lastSyncedFromServer,
///     hasIncompleteChannel: state.nonSuccessTargets.isNotEmpty,
///     syncing: state.isSyncing,
///     onPressed: _syncAction(state),
///   ),
/// ],
/// ```
///
/// ⚠️ What a tap does is passed in by the screen (the same work as the old
/// [동기화] button).
/// ⚠️ The red dot = the same condition that shows the channel status banner.
/// ❌ Do not add parameters to the shared frame (`ScaffoldWithNavBar`) for
/// this pill — pass it through `appBarActions` (D27).
class OrderSyncButton extends StatelessWidget {
  final String? lastSyncedAt;
  final bool hasIncompleteChannel;
  final bool syncing;
  final VoidCallback? onPressed;

  const OrderSyncButton({
    required this.lastSyncedAt,
    required this.hasIncompleteChannel,
    required this.syncing,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dimmed = onPressed == null && !syncing;
    final textColor = dimmed
        ? AppColors.textSecondary.withValues(alpha: 0.38)
        : AppColors.textSecondary;
    final iconColor = dimmed
        ? AppColors.textStrong.withValues(alpha: 0.38)
        : AppColors.textStrong;
    final String label;
    if (syncing) {
      label = '동기화 중…';
    } else if (lastSyncedAt == null) {
      label = '동기화';
    } else {
      label = '${formatRelativeTime(lastSyncedAt)} 동기화';
    }
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: colorScheme.surface,
        shape: StadiumBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasIncompleteChannel
                          ? colorScheme.error
                          : AppColors.syncOkDot,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(width: 6),
                  if (syncing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.sync, size: 16, color: iconColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
