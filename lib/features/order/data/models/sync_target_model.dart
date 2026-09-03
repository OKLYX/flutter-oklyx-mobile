import '../../domain/entities/sync_target.dart';

class SyncTargetModel extends SyncTarget {
  const SyncTargetModel({
    required super.accountId,
    required super.sellerId,
    required super.sellerName,
    required super.platform,
    super.accountAlias,
    super.lastSyncStatus,
    super.lastSyncAt,
    super.lastOrderSyncAt,
    super.lastCancelSyncAt,
    super.lastSyncError,
  });

  factory SyncTargetModel.fromJson(Map<String, dynamic> json) {
    return SyncTargetModel(
      accountId: (json['accountId'] as num?)?.toInt() ?? 0,
      sellerId: (json['sellerId'] as num?)?.toInt() ?? 0,
      sellerName: json['sellerName'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      accountAlias: json['accountAlias'] as String?,
      lastSyncStatus: json['lastSyncStatus'] as String?,
      lastSyncAt: json['lastSyncAt'] as String?,
      lastOrderSyncAt: json['lastOrderSyncAt'] as String?,
      lastCancelSyncAt: json['lastCancelSyncAt'] as String?,
      lastSyncError: json['lastSyncError'] as String?,
    );
  }
}
