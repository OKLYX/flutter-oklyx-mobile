import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import '../../domain/entities/packing.dart';
import '../../domain/entities/packing_history.dart';
import 'packing_event.dart';

/// Shown both as the error toast and as the error text of the box card.
const String packingUnexpandedMessage =
    '구성 물품을 전개할 수 없는 주문입니다 — 이 박스는 완료할 수 없습니다';

enum PackingNoticeKind { success, error, info }

/// One toast. A new object every time so the same text shows again.
class PackingNotice {
  final PackingNoticeKind kind;
  final String message;

  PackingNotice(this.kind, this.message);
}

/// State of the 「포장 작업」 screen (FEATURE_2611_03 / PLAN D23 · D27).
class PackingState {
  /// Work list (boxes left to pack).
  final List<PendingParcel> pending;
  final bool pendingLoading;

  /// 「오늘 완료」 rows — today's 「포장 완료」 history rows, latest first
  /// (FEATURE_2611_06 / D21).
  final List<PackingHistoryEntry> done;
  final bool doneLoading;

  /// The tab below the input field (FEATURE_2611_06 / D24).
  final PackingTab tab;

  /// Every box for a manual pick when there is no candidate.
  final List<Package> packages;

  /// The open box — null while waiting for an invoice.
  final PackingScan? scan;

  /// Packed quantity per `{orderLineId}:{productId}`.
  final Map<String, int> packed;
  final List<BoxCandidate> candidates;
  final bool candidatesLoading;
  final int? selectedBoxId;

  /// A request (open · barcode lookup · complete · unused · restore) is
  /// running.
  final bool busy;
  final PackingNotice? notice;

  const PackingState({
    this.pending = const [],
    this.pendingLoading = false,
    this.done = const [],
    this.doneLoading = false,
    this.tab = PackingTab.done,
    this.packages = const [],
    this.scan,
    this.packed = const {},
    this.candidates = const [],
    this.candidatesLoading = false,
    this.selectedBoxId,
    this.busy = false,
    this.notice,
  });

  static String lineKey(int orderLineId, int productId) =>
      '$orderLineId:$productId';

  int packedOf(PackingRemainingItem item) =>
      packed[lineKey(item.orderLineId, item.productId)] ?? 0;

  int get packedTotal => packed.values.fold(0, (sum, qty) => sum + qty);

  int get requiredTotal =>
      scan?.remaining.fold<int>(0, (sum, item) => sum + item.remainingQty) ?? 0;

  PackingState copyWith({
    List<PendingParcel>? pending,
    bool? pendingLoading,
    List<PackingHistoryEntry>? done,
    bool? doneLoading,
    PackingTab? tab,
    List<Package>? packages,
    PackingScan? scan,
    bool clearScan = false,
    Map<String, int>? packed,
    List<BoxCandidate>? candidates,
    bool? candidatesLoading,
    int? selectedBoxId,
    bool clearSelectedBox = false,
    bool? busy,
    PackingNotice? notice,
  }) =>
      PackingState(
        pending: pending ?? this.pending,
        pendingLoading: pendingLoading ?? this.pendingLoading,
        done: done ?? this.done,
        doneLoading: doneLoading ?? this.doneLoading,
        tab: tab ?? this.tab,
        packages: packages ?? this.packages,
        scan: clearScan ? null : (scan ?? this.scan),
        packed: packed ?? this.packed,
        candidates: candidates ?? this.candidates,
        candidatesLoading: candidatesLoading ?? this.candidatesLoading,
        selectedBoxId:
            clearSelectedBox ? null : (selectedBoxId ?? this.selectedBoxId),
        busy: busy ?? this.busy,
        notice: notice ?? this.notice,
      );
}
