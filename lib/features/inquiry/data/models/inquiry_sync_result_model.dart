import '../../domain/entities/inquiry_sync_result.dart';

/// `POST /api/inquiries/sync?accountId=` 응답 → [InquirySyncResult].
class InquirySyncResultModel extends InquirySyncResult {
  const InquirySyncResultModel({
    required super.fetched,
    required super.staleClosed,
    super.accountId,
    super.syncedAt,
  });

  factory InquirySyncResultModel.fromJson(Map<String, dynamic> json) =>
      InquirySyncResultModel(
        fetched: (json['fetched'] as num?)?.toInt() ?? 0,
        staleClosed: (json['staleClosed'] as num?)?.toInt() ?? 0,
        accountId: (json['accountId'] as num?)?.toInt(),
        syncedAt: DateTime.tryParse(json['syncedAt'] as String? ?? ''),
      );
}
