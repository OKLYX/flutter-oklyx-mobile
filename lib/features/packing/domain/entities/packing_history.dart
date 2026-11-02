import 'packing.dart';

/// One row of the 「포장 이력」 screen (FEATURE_2611_03 / PLAN D30 · D31) —
/// the server `PackingHistoryView`.
class PackingHistoryEntry {
  final int id;

  /// History row time as a KST wall clock, `yyyy-MM-ddTHH:mm:ss` with no zone —
  /// the server converts it (D40). Print it as is; no `toLocal` / UTC
  /// re-reading (not `formatRelativeTime`).
  final String changedAt;
  final int parcelId;
  final String invoiceNumber;
  final String? carrierName;
  final String externalOrderId;
  final String? sellerName;
  final ParcelStatus fromStatus;
  final ParcelStatus toStatus;

  /// Who moved it, null when unknown.
  final String? changedBy;

  const PackingHistoryEntry({
    required this.id,
    required this.changedAt,
    required this.parcelId,
    required this.invoiceNumber,
    required this.carrierName,
    required this.externalOrderId,
    required this.sellerName,
    required this.fromStatus,
    required this.toStatus,
    required this.changedBy,
  });

  /// Action name of the status pair (D30): 「포장 완료」 · 「미사용 처리」 ·
  /// 「미사용 되돌리기」 — the same table as the web `parcelActionLabel`. Any
  /// other pair is never written (D16) and shows `-`.
  String get actionLabel => switch ((fromStatus, toStatus)) {
        (ParcelStatus.pending, ParcelStatus.packed) => '포장 완료',
        (ParcelStatus.pending, ParcelStatus.unused) => '미사용 처리',
        (ParcelStatus.unused, ParcelStatus.pending) => '미사용 되돌리기',
        _ => '-',
      };
}
