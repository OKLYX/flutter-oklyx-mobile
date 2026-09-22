import '../../domain/entities/claim_sync_result.dart';

/// `POST /api/claims/sync?accountId=` 응답 → [ClaimSyncResult].
class ClaimSyncResultModel extends ClaimSyncResult {
  const ClaimSyncResultModel({
    super.accountId,
    super.skipped,
    super.syncedAt,
  });

  factory ClaimSyncResultModel.fromJson(Map<String, dynamic> json) =>
      ClaimSyncResultModel(
        accountId: (json['accountId'] as num?)?.toInt(),
        skipped: json['skipped'] == true,
        syncedAt: DateTime.tryParse(json['syncedAt'] as String? ?? ''),
      );
}
