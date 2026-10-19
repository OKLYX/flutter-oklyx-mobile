import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// 「정산 내역」 refresh bar (FEATURE_2610_20 / D19 · D24) — the mobile twin of the
/// web `SyncBar`.
///
/// 🔴 These three buttons are the only market calls of the screen — the page
/// never refreshes on entry (D19).
/// ⚠️ While [rateLimitedMessage] is not empty the three buttons are hidden, not
/// disabled (D24).
/// ⚠️ One action at a time: any running action disables all three.
class SettlementSyncBar extends StatelessWidget {
  final String? lastSyncedAt;
  final String? lastPayoutSyncedAt;
  final bool syncing;
  final bool payoutSyncing;
  final bool backfillRunning;
  final String rateLimitedMessage;
  final String notice;
  final String error;
  final VoidCallback onSync;
  final VoidCallback onSyncPayout;
  final VoidCallback onBackfill;

  const SettlementSyncBar({
    required this.syncing,
    required this.payoutSyncing,
    required this.backfillRunning,
    required this.rateLimitedMessage,
    required this.notice,
    required this.error,
    required this.onSync,
    required this.onSyncPayout,
    required this.onBackfill,
    super.key,
    this.lastSyncedAt,
    this.lastPayoutSyncedAt,
  });

  @override
  Widget build(BuildContext context) {
    final busy = syncing || payoutSyncing || backfillRunning;
    final muted = TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('마지막 갱신: ${formatRelativeTime(lastSyncedAt)}', style: muted),
          const SizedBox(height: 4),
          Text('지급내역: ${formatRelativeTime(lastPayoutSyncedAt)}', style: muted),
          if (rateLimitedMessage.isEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onSync,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: syncing ? const AppBusyLabel('갱신') : const Text('갱신'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : onSyncPayout,
                  child: payoutSyncing
                      ? const AppBusyLabel('지급내역 갱신')
                      : const Text('지급내역 갱신'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onBackfill,
                  icon: const Icon(Icons.history, size: 18),
                  label: backfillRunning
                      ? const AppBusyLabel('과거 정산 불러오기')
                      : const Text('과거 정산 불러오기'),
                ),
              ],
            ),
          ],
          if (rateLimitedMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            SettlementMessageBox(
                tone: SettlementMessageTone.warning,
                message: rateLimitedMessage),
          ],
          if (notice.isNotEmpty) ...[
            const SizedBox(height: 8),
            SettlementMessageBox(
                tone: SettlementMessageTone.info, message: notice),
          ],
          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
            SettlementMessageBox(
                tone: SettlementMessageTone.error, message: error),
          ],
        ],
      ),
    );
  }
}
