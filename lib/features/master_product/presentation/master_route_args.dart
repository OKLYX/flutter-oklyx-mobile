/// Arguments passed between master screens through go_router `extra`
/// (FEATURE_2609_80 R17).
///
/// **File**: lib/features/master_product/presentation/master_route_args.dart
/// Path parameters (`:id`, `:listingId`) travel in the path; the rest here.
/// ⚠️ When `extra` is missing or of another type, open with the defaults
///    (`const MasterDetailArgs()` etc.).

/// Master detail (`Routes.masterProductDetail`) — web `?overview=1` / `?notice=`.
class MasterDetailArgs {
  /// Open once with the product-relation overview on, right after creation
  /// (UX D69).
  final bool openOverview;

  /// Notice for a partially failed follow-up save after creation
  /// (web `?notice=`). null = none.
  final String? notice;

  const MasterDetailArgs({this.openOverview = false, this.notice});
}

/// Master create page (`Routes.masterProductNew`) — web
/// `?sellerId=&platform=&platformProductId=&productIds=` (market entry
/// "새 마스터로"). Opened from the drawer it has no `extra` (not market mode).
class MasterCreateArgs {
  final int sellerId;
  final String platform;
  final String platformProductId;

  /// Product ids to preselect as components (first-seen order, no duplicates).
  final List<int> productIds;

  const MasterCreateArgs({
    required this.sellerId,
    required this.platform,
    required this.platformProductId,
    required this.productIds,
  });
}
