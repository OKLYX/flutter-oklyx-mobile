import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/sync_target.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/claim.dart';

abstract class ClaimListState {}

/// 초기 상태 (진입 직후)
class ClaimListInitial extends ClaimListState {}

/// **최초 로드 중에만** 쓴다 (전체 화면 스피너).
/// 🔴 재조회에서 이 상태를 emit 하면 판매자·기간·검색어·칩이 통째로 사라졌다 돌아온다 —
/// 재조회는 [ClaimListLoaded.isSearching] 으로 표현한다.
class ClaimListLoading extends ClaimListState {}

/// **최초 로드 실패 전용** (화면에 아무것도 없을 때 + 재시도 버튼).
/// 이미 목록을 보고 있는 상태의 재조회 실패는 [ClaimListLoaded.actionError] 다.
class ClaimListError extends ClaimListState {
  final String message;

  ClaimListError({required this.message});
}

/// 조회 성공 상태.
///
/// 필터 컨트롤을 유지해야 하므로 재조회는 별도 상태가 아닌 [isSearching] 플래그로 표현한다
/// (`OrderListLoaded` 와 동일). 일시적 실패는 [actionError] 로 전달해 SnackBar 로 소비한 뒤
/// `copyWith(clearActionError: true)` 로 비운다.
class ClaimListLoaded extends ClaimListState {
  /// 서버가 준 원본 목록. 상태 칩 필터는 [visible] 로 파생한다(서버 왕복 없음).
  final List<Claim> claims;
  final List<Seller> sellers;
  final int? selectedSellerId;

  /// 상태 칩 선택 (null = 전체). 클라이언트 필터라 재조회를 트리거하지 않는다.
  final ClaimStatus? selectedStatus;

  /// 드롭다운에 보이는 '고른 기간'. 조회 버튼을 누르기 전엔 목록에 반영되지 않는다.
  final String selectedPeriod;

  /// 🔴 지금 목록이 실제로 담고 있는 기간. 빈 상태 문구가 이쪽을 봐야 어긋나지 않는다.
  final String appliedPeriod;

  /// 검색어. **서버로 보낸다**(`SearchClaims` 시점) — 클라이언트 필터가 아니다.
  final String searchTerm;

  final bool isSearching;
  final String? actionError;

  /// 동기화 대상 채널(계정). **판매자 필터에 따라 좁아진다** — 비어 있으면 [동기화] 버튼이
  /// 비활성된다(FEATURE_2609_70 / D14). 조회 실패도 빈 목록이다(비차단).
  final List<SyncTarget> syncTargets;

  /// 동기화 진행 중 — 화면 안 한 줄 + 진행바다. 🔴 다이얼로그를 띄우지 않는다(M4).
  final bool isSyncing;
  final int syncTotal;
  final int syncDone;

  /// 지금 가져오는 중인 채널 표시명('판매자 · 플랫폼').
  final String? syncingChannelName;

  /// 채널들의 `lastClaimSyncAt` 중 **가장 최근** 값(D16). null 이면 「마지막 동기화」 줄을
  /// 아예 그리지 않는다 — 주문내역과 같은 자세다.
  final String? lastClaimSyncedAt;

  /// 동기화 **성공** 요약 한 줄. ⚠️ [actionError] 와 다른 필드다 — 성공 요약을 에러 자리에
  /// 넣으면 실패 문구와 구분할 수 없다(고객문의 화면과 같은 규칙).
  final String? syncSummary;

  /// 지금 보고 있는 탭(반품 / 교환). **서버 조회 파라미터**라 바뀌면 재조회가 따라온다.
  final ClaimType claimType;

  ClaimListLoaded({
    required this.claims,
    required this.sellers,
    this.selectedSellerId,
    this.selectedStatus,
    this.selectedPeriod = kRecentPeriod,
    this.appliedPeriod = kRecentPeriod,
    this.searchTerm = '',
    this.isSearching = false,
    this.actionError,
    this.claimType = ClaimType.returnClaim,
    this.syncTargets = const [],
    this.isSyncing = false,
    this.syncTotal = 0,
    this.syncDone = 0,
    this.syncingChannelName,
    this.lastClaimSyncedAt,
    this.syncSummary,
  });

  /// 조회·동기화 중에는 컨트롤을 잠근다.
  bool get busy => isSearching || isSyncing;

  /// 이 탭에서 보여줄 상태 칩. 칩 목록은 탭마다 다르다.
  List<ClaimStatus> get statusFilters => claimType == ClaimType.exchange
      ? exchangeStatusFilters
      : returnStatusFilters;

  /// 빈 상태·에러 문구에 쓰는 명칭('반품' / '교환').
  String get typeLabel => getClaimTypeLabel(claimType);

  /// 화면에 그릴 목록 — 상태 칩만 얹는다(검색·기간·판매자는 이미 서버가 걸렀다).
  List<Claim> get visible => selectedStatus == null
      ? claims
      : claims.where((c) => c.status == selectedStatus).toList();

  /// 상태별 건수 (칩 배지). 목록과 **같은 소스**([claims])에서 센다 —
  /// 다른 집합을 세면 배지와 목록이 어긋난다.
  Map<ClaimStatus, int> get statusCounts {
    final counts = <ClaimStatus, int>{};
    for (final claim in claims) {
      counts[claim.status] = (counts[claim.status] ?? 0) + 1;
    }
    return counts;
  }

  ClaimListLoaded copyWith({
    List<Claim>? claims,
    List<Seller>? sellers,
    int? selectedSellerId,
    bool clearSelectedSeller = false,
    ClaimStatus? selectedStatus,
    bool clearSelectedStatus = false,
    String? selectedPeriod,
    String? appliedPeriod,
    String? searchTerm,
    bool? isSearching,
    String? actionError,
    // ⚠️ `??` 관례상 null 을 넘겨서는 못 지운다 — 명시적 clear 플래그가 필요하다.
    bool clearActionError = false,
    // ⚠️ null 이 될 수 없는 축이라 clear 플래그가 없다.
    ClaimType? claimType,
    List<SyncTarget>? syncTargets,
    bool? isSyncing,
    int? syncTotal,
    int? syncDone,
    String? syncingChannelName,
    bool clearSyncingChannelName = false,
    String? lastClaimSyncedAt,
    bool clearLastClaimSyncedAt = false,
    String? syncSummary,
    bool clearSyncSummary = false,
  }) {
    return ClaimListLoaded(
      claims: claims ?? this.claims,
      sellers: sellers ?? this.sellers,
      selectedSellerId: clearSelectedSeller
          ? null
          : (selectedSellerId ?? this.selectedSellerId),
      selectedStatus: clearSelectedStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      appliedPeriod: appliedPeriod ?? this.appliedPeriod,
      // '' 가 곧 "검색 없음" 이라 clear 플래그가 필요 없다.
      searchTerm: searchTerm ?? this.searchTerm,
      isSearching: isSearching ?? this.isSearching,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      claimType: claimType ?? this.claimType,
      syncTargets: syncTargets ?? this.syncTargets,
      isSyncing: isSyncing ?? this.isSyncing,
      syncTotal: syncTotal ?? this.syncTotal,
      syncDone: syncDone ?? this.syncDone,
      syncingChannelName: clearSyncingChannelName
          ? null
          : (syncingChannelName ?? this.syncingChannelName),
      // 판매자를 바꾸면 기록이 없는 채널만 남을 수 있다 — 그때는 명시적으로 비운다.
      lastClaimSyncedAt: clearLastClaimSyncedAt
          ? null
          : (lastClaimSyncedAt ?? this.lastClaimSyncedAt),
      syncSummary: clearSyncSummary ? null : (syncSummary ?? this.syncSummary),
    );
  }
}
