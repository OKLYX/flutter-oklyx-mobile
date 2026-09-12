import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/sync_target.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_type_option.dart';

abstract class InquiryListState {}

/// 초기 상태 (진입 직후)
class InquiryListInitial extends InquiryListState {}

/// **최초 로드 중에만** 쓴다 (전체 화면 스피너).
/// 🔴 재조회·동기화 후 재조회에서 이 상태를 emit 하면 탭·필터·검색어가 통째로 사라졌다
/// 돌아온다 — 재조회는 [InquiryListLoaded.isSearching] 으로 표현한다.
class InquiryListLoading extends InquiryListState {}

/// **최초 로드 실패 전용** (화면에 아무것도 없을 때 + 재시도 버튼).
/// 이미 목록을 보고 있는 상태의 실패는 [InquiryListLoaded.actionError] 다.
class InquiryListError extends InquiryListState {
  final String message;

  InquiryListError({required this.message});
}

/// 조회 성공 상태.
///
/// 필터 컨트롤을 유지해야 하므로 재조회는 별도 상태가 아닌 [isSearching] 플래그로 표현한다
/// (`ClaimListLoaded` 와 동일).
class InquiryListLoaded extends InquiryListState {
  /// 서버가 준 원본 목록. 상태 칩 필터는 [visible] 로 파생한다(서버 왕복 없음).
  final List<Inquiry> inquiries;

  /// 유형 탭 후보. **서버 `/types` 가 유일한 원천**이다(PLAN M2). 비어 있으면 탭을
  /// 그리지 않고 유형 없이 전체를 조회한다.
  final List<InquiryTypeOption> typeOptions;

  /// 지금 보고 있는 유형. null = 유형 미지정(=`/types` 실패 시 전체 조회).
  final InquiryType? selectedType;

  final List<Seller> sellers;
  final int? selectedSellerId;

  /// 🔴 채널 드롭다운 옵션의 **유일한 원천**(PLAN M12) — 목록에만 있는
  /// `marketplaceAccountId` 를 옵션에 합치지 않는다(그 합집합 규칙은 주문내역 전용이다).
  final List<SyncTarget> syncTargets;
  final int? selectedAccountId;

  /// 상태 칩 선택 (null = 전체). 클라이언트 필터라 재조회를 트리거하지 않는다.
  final InquiryStatus? selectedStatus;

  /// 드롭다운에 보이는 '고른 기간'. [조회] 를 누르기 전엔 목록에 반영되지 않는다.
  final String selectedPeriod;

  /// 🔴 지금 목록이 실제로 담고 있는 기간. 동기화 후 재조회가 이 값을 쓴다.
  final String appliedPeriod;

  /// 검색어. **서버로 보낸다**(`SearchInquiries` 시점) — 클라이언트 필터가 아니다.
  final String searchTerm;

  final bool isSearching;

  /// 일시적 실패 문구(SnackBar 로 소비 후 `clearActionError` 로 비운다).
  final String? actionError;

  /// 동기화 진행 중 (화면 안 한 줄 + 진행바 — 다이얼로그 금지, M4)
  final bool isSyncing;
  final int syncDone;
  final int syncTotal;

  /// 지금 가져오는 중인 채널 표시명('판매자 · 플랫폼').
  final String? syncingChannelName;

  /// 동기화 **성공** 요약 한 줄. ⚠️ [actionError] 와 다른 필드다 — 성공 요약을 에러
  /// 자리에 넣으면 실패 문구와 구분할 수 없다.
  final String? syncSummary;

  InquiryListLoaded({
    required this.inquiries,
    required this.typeOptions,
    required this.sellers,
    required this.syncTargets,
    this.selectedType,
    this.selectedSellerId,
    this.selectedAccountId,
    this.selectedStatus,
    this.selectedPeriod = kRecentPeriod,
    this.appliedPeriod = kRecentPeriod,
    this.searchTerm = '',
    this.isSearching = false,
    this.actionError,
    this.isSyncing = false,
    this.syncDone = 0,
    this.syncTotal = 0,
    this.syncingChannelName,
    this.syncSummary,
  });

  /// 화면에 그릴 목록 — 상태 칩만 얹는다(유형·기간·판매자·채널·검색은 서버가 걸렀다).
  List<Inquiry> get visible => selectedStatus == null
      ? inquiries
      : inquiries.where((i) => i.status == selectedStatus).toList();

  /// 상태별 건수 (칩 배지). 목록과 **같은 소스**([inquiries])에서 센다 —
  /// 다른 집합을 세면 배지와 목록이 어긋난다.
  Map<InquiryStatus, int> get statusCounts {
    final counts = <InquiryStatus, int>{};
    for (final inquiry in inquiries) {
      counts[inquiry.status] = (counts[inquiry.status] ?? 0) + 1;
    }
    return counts;
  }

  /// 조회·동기화 중에는 컨트롤을 잠근다.
  bool get busy => isSearching || isSyncing;

  InquiryListLoaded copyWith({
    List<Inquiry>? inquiries,
    List<InquiryTypeOption>? typeOptions,
    InquiryType? selectedType,
    List<Seller>? sellers,
    int? selectedSellerId,
    bool clearSelectedSeller = false,
    List<SyncTarget>? syncTargets,
    int? selectedAccountId,
    bool clearSelectedAccount = false,
    InquiryStatus? selectedStatus,
    bool clearSelectedStatus = false,
    String? selectedPeriod,
    String? appliedPeriod,
    String? searchTerm,
    bool? isSearching,
    String? actionError,
    // ⚠️ `??` 관례상 null 을 넘겨서는 못 지운다 — 명시적 clear 플래그가 필요하다.
    bool clearActionError = false,
    bool? isSyncing,
    int? syncDone,
    int? syncTotal,
    String? syncingChannelName,
    bool clearSyncingChannelName = false,
    String? syncSummary,
    bool clearSyncSummary = false,
  }) =>
      InquiryListLoaded(
        inquiries: inquiries ?? this.inquiries,
        typeOptions: typeOptions ?? this.typeOptions,
        // 유형은 null 이 정상 값(전체 조회)이라 clear 플래그 없이 그대로 덮는다 —
        // 한 번 정해지면 화면에서 null 로 되돌리는 경로가 없다.
        selectedType: selectedType ?? this.selectedType,
        sellers: sellers ?? this.sellers,
        selectedSellerId: clearSelectedSeller
            ? null
            : (selectedSellerId ?? this.selectedSellerId),
        syncTargets: syncTargets ?? this.syncTargets,
        selectedAccountId: clearSelectedAccount
            ? null
            : (selectedAccountId ?? this.selectedAccountId),
        selectedStatus: clearSelectedStatus
            ? null
            : (selectedStatus ?? this.selectedStatus),
        selectedPeriod: selectedPeriod ?? this.selectedPeriod,
        appliedPeriod: appliedPeriod ?? this.appliedPeriod,
        // '' 가 곧 "검색 없음" 이라 clear 플래그가 필요 없다.
        searchTerm: searchTerm ?? this.searchTerm,
        isSearching: isSearching ?? this.isSearching,
        actionError:
            clearActionError ? null : (actionError ?? this.actionError),
        isSyncing: isSyncing ?? this.isSyncing,
        syncDone: syncDone ?? this.syncDone,
        syncTotal: syncTotal ?? this.syncTotal,
        syncingChannelName: clearSyncingChannelName
            ? null
            : (syncingChannelName ?? this.syncingChannelName),
        syncSummary:
            clearSyncSummary ? null : (syncSummary ?? this.syncSummary),
      );
}
