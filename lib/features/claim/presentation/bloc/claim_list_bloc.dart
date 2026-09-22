import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/sync_target.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/claim_usecase.dart';
import 'claim_list_event.dart';
import 'claim_list_state.dart';

/// 반품/교환 목록 BLoC (FEATURE_2609_18).
///
/// - 진입 시 판매자 목록 + 기본 창(최근 2주) 조회 ([LoadClaims], 기본 탭 = 반품)
/// - 판매자·기간·검색어는 **고르기만** 하고, [SearchClaims](조회 버튼)에서 서버로 보낸다
/// - 상태 칩([SelectStatus])은 클라이언트 필터라 서버를 부르지 않는다
/// - 탭([SelectClaimType])은 **서버 파라미터**라 전환 즉시 재조회한다
/// - [SyncClaims] 는 동기화 대상 채널을 하나씩 돌며 `POST /api/claims/sync` 를 부른다
///   (FEATURE_2609_70 / D14 — 진행은 화면 안 한 줄, 다이얼로그 금지)
///
/// 판매자 목록은 기존 seller 기능의 [GetSellersUseCase], 동기화 대상은 order 기능의
/// [OrderUseCase.getSyncTargets] 를 재사용한다 — 클레임 전용 API 를 새로 만들지 않는다
/// (고객문의 화면과 같은 구성).
class ClaimListBloc extends Bloc<ClaimListEvent, ClaimListState> {
  final ClaimUseCase claimUseCase;
  final GetSellersUseCase getSellersUseCase;
  final OrderUseCase orderUseCase;

  ClaimListBloc({
    required this.claimUseCase,
    required this.getSellersUseCase,
    required this.orderUseCase,
  }) : super(ClaimListInitial()) {
    on<LoadClaims>(_onLoad);
    on<SelectSeller>(_onSelectSeller);
    on<SelectPeriod>(_onSelectPeriod);
    on<ChangeSearchTerm>(_onChangeSearchTerm);
    on<SearchClaims>(_onSearch);
    on<SelectStatus>(_onSelectStatus);
    on<SelectClaimType>(_onSelectClaimType);
    on<SyncClaims>(_onSync);
  }

  Future<void> _onLoad(LoadClaims event, Emitter<ClaimListState> emit) async {
    emit(ClaimListLoading());

    // 판매자 목록 실패는 비치명적: 드롭다운만 '전체'로 폴백(주문내역과 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    // 동기화 대상 실패도 비치명적 — 빈 목록이면 [동기화] 버튼만 비활성된다.
    final targets = await _fetchTargets(null);

    // 기본값이 kRecentPeriod 라 from/to 를 보내지 않는다 = 서버 기본 창.
    // 진입 탭은 반품 고정 — ClaimListLoaded 의 claimType 기본값과 같아야 한다.
    final result = await claimUseCase.getClaims(type: ClaimType.returnClaim);
    result.fold(
      (failure) => emit(ClaimListError(message: failure.message)),
      (claims) => emit(ClaimListLoaded(
        claims: claims,
        sellers: sellers,
        syncTargets: targets,
        lastClaimSyncedAt: _latestClaimSyncAt(targets),
      )),
    );
  }

  /// 판매자 선택 — 목록은 [SearchClaims] 때 반영하되, **동기화 대상은 지금 좁힌다**
  /// (고객문의 화면과 같은 처리). 대상이 0개가 되면 [동기화] 버튼이 꺼진다.
  Future<void> _onSelectSeller(
    SelectSeller event,
    Emitter<ClaimListState> emit,
  ) async {
    final current = state;
    if (current is! ClaimListLoaded) return;

    emit(current.copyWith(
      selectedSellerId: event.sellerId,
      clearSelectedSeller: event.sellerId == null,
    ));

    final targets = await _fetchTargets(event.sellerId);
    if (emit.isDone) return;
    final latest = state;
    if (latest is! ClaimListLoaded) return;
    final lastSyncedAt = _latestClaimSyncAt(targets);
    emit(latest.copyWith(
      syncTargets: targets,
      lastClaimSyncedAt: lastSyncedAt,
      // 좁힌 채널에 기록이 하나도 없으면 「마지막 동기화」 줄을 지운다 —
      // 남겨 두면 다른 판매자의 시각을 이 판매자 것으로 읽는다.
      clearLastClaimSyncedAt: lastSyncedAt == null,
    ));
  }

  void _onSelectPeriod(SelectPeriod event, Emitter<ClaimListState> emit) {
    final current = state;
    if (current is! ClaimListLoaded) return;
    emit(current.copyWith(selectedPeriod: event.period));
  }

  void _onChangeSearchTerm(
    ChangeSearchTerm event,
    Emitter<ClaimListState> emit,
  ) {
    final current = state;
    if (current is! ClaimListLoaded) return;
    emit(current.copyWith(searchTerm: event.term));
  }

  /// 상태 칩 — 클라이언트 필터라 서버를 부르지 않는다(목록은 `visible` 로 파생).
  void _onSelectStatus(SelectStatus event, Emitter<ClaimListState> emit) {
    final current = state;
    if (current is! ClaimListLoaded) return;
    emit(current.copyWith(
      selectedStatus: event.status,
      clearSelectedStatus: event.status == null,
    ));
  }

  /// 조회 버튼 — 🔴 [ClaimListLoading] 을 emit 하지 않는다.
  /// 필터 UI 를 유지한 채 [ClaimListLoaded.isSearching] 만 켠다.
  Future<void> _onSearch(
    SearchClaims event,
    Emitter<ClaimListState> emit,
  ) async {
    final current = state;
    if (current is! ClaimListLoaded) return;
    if (current.busy) return;

    // 🔴 emit 은 필수다 — 빼면 조회 버튼이 '조회 중...' 으로 바뀌지 않고,
    // 연타 가드(위 isSearching)도 상태가 갱신되지 않아 영영 걸리지 않는다.
    final next = current.copyWith(isSearching: true, clearActionError: true);
    emit(next);

    // 재조회 실패는 기존 목록을 지키므로 clearOnFailure = false.
    await _fetch(emit, next, clearOnFailure: false);
  }

  /// 반품 ↔ 교환 전환 — 탭은 **서버 파라미터**라 즉시 재조회한다.
  /// 🔴 [ClaimListLoading] 을 emit 하지 않는 규칙은 [_onSearch] 와 완전히 같다.
  Future<void> _onSelectClaimType(
    SelectClaimType event,
    Emitter<ClaimListState> emit,
  ) async {
    final current = state;
    if (current is! ClaimListLoaded) return;
    // 연타·중복 요청 방지.
    if (current.claimType == event.type || current.busy) return;

    // 🔴 상태 칩을 반드시 해제한다 — 칩 목록이 탭마다 달라, '확인요청'(반품 전용)을 고른 채
    // 교환으로 넘어가면 칩은 사라졌는데 필터만 살아 목록이 영구히 0건이 된다.
    final next = current.copyWith(
      claimType: event.type,
      clearSelectedStatus: true,
      isSearching: true,
      clearActionError: true,
    );
    emit(next);

    // 탭이 이미 바뀌었으므로 실패 시 목록을 비운다(재조회와 판단이 반대인 유일한 지점).
    await _fetch(emit, next, clearOnFailure: true);
  }

  /// 반품·교환만 다시 가져오기(D14) — 채널을 **하나씩** 돌며 진행을 상태로 올린다.
  ///
  /// ⚠️ `SyncProgressDialog` 를 쓰지 않는다 — 그 위젯은 `OrderListBloc`/`OrderListState` 를
  /// 직접 읽는다(고객문의 화면이 같은 이유로 쓰지 않았다).
  /// ⚠️ 한 채널이 실패해도 **루프를 멈추지 않는다**(채널별 격리). 사유는 서버 문구 그대로 쓴다.
  /// ⚠️ **건너뜀(skipped)은 실패가 아니다** — 따로 세어 끝난 뒤 함께 알린다.
  Future<void> _onSync(SyncClaims event, Emitter<ClaimListState> emit) async {
    final current = state;
    if (current is! ClaimListLoaded) return;
    if (current.busy) return;

    // 대상은 지금 화면이 들고 있는 목록이다(판매자 필터로 이미 좁혀져 있다).
    final targets = current.syncTargets;
    if (targets.isEmpty) {
      emit(current.copyWith(
        actionError: '가져올 채널이 없습니다.',
        clearSyncSummary: true,
      ));
      return;
    }

    var running = current.copyWith(
      isSyncing: true,
      syncTotal: targets.length,
      syncDone: 0,
      clearActionError: true,
      clearSyncSummary: true,
    );
    emit(running);

    var failed = 0;
    var skipped = 0;
    String? firstError;
    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      running = running.copyWith(syncingChannelName: _channelLabel(target));
      emit(running);

      final result = await claimUseCase.syncClaims(target.accountId);
      if (emit.isDone) return;
      result.fold(
        (failure) {
          failed++;
          firstError ??= failure.message;
        },
        (syncResult) {
          if (syncResult.skipped) skipped++;
        },
      );

      running = running.copyWith(syncDone: i + 1);
      emit(running);
    }

    // ① 대상 재조회 — 「마지막 동기화」 시각의 원천은 서버가 낙인한 lastClaimSyncAt 이다(D16).
    // 조회에 실패(빈 목록)하면 기존 대상을 그대로 둔다 — 여기서 버튼을 꺼 버리면 방금 성공한
    // 동기화 뒤에 '가져올 채널이 없습니다' 가 뜬다.
    final refreshed = await _fetchTargets(running.selectedSellerId);
    if (emit.isDone) return;
    final lastSyncedAt = refreshed.isEmpty
        ? running.lastClaimSyncedAt
        : _latestClaimSyncAt(refreshed);

    // 건너뛴 채널은 실패와 섞지 않고 문구 뒤에 절로 붙인다(0이면 그 절을 뺀다).
    final skippedClause =
        skipped > 0 ? ' · $skipped개 채널은 이미 동기화 중이라 건너뛰었습니다' : '';
    running = running.copyWith(
      isSyncing: false,
      clearSyncingChannelName: true,
      isSearching: true,
      syncTargets: refreshed.isEmpty ? null : refreshed,
      lastClaimSyncedAt: lastSyncedAt,
      clearLastClaimSyncedAt: lastSyncedAt == null,
      actionError: failed > 0
          ? '가져오기 실패 $failed건 — ${firstError ?? ''}$skippedClause'
          : null,
      syncSummary: failed > 0 ? null : '동기화 완료$skippedClause',
    );
    emit(running);

    // ② 목록 재조회는 **지금 목록에 반영된 기간**(appliedPeriod)으로 한다 — 사용자가 그 사이
    // 드롭다운만 만져 둔 기간을 쓰면 말없이 다른 조회가 된다.
    // 🔴 문구는 여기서 비운다 — 안 비우면 재조회 emit 이 같은 SnackBar 를 한 번 더 띄운다.
    await _fetch(
      emit,
      running.copyWith(clearActionError: true, clearSyncSummary: true),
      clearOnFailure: false,
      period: running.appliedPeriod,
    );
  }

  /// 동기화 대상 조회 — 실패는 비치명적이라 빈 목록으로 떨어뜨린다([동기화] 버튼만 꺼진다).
  Future<List<SyncTarget>> _fetchTargets(int? sellerId) async {
    final result = await orderUseCase.getSyncTargets(sellerId: sellerId);
    return result.fold((_) => <SyncTarget>[], (targets) => targets);
  }

  /// 채널들의 `lastClaimSyncAt` 중 가장 최근 값(D16).
  /// 서버가 주는 ISO LocalDateTime 은 **문자열 정렬 = 시간순**이라 그대로 비교한다.
  String? _latestClaimSyncAt(List<SyncTarget> targets) {
    String? latest;
    for (final target in targets) {
      final value = target.lastClaimSyncAt;
      if (value == null || value.isEmpty) continue;
      if (latest == null || value.compareTo(latest) > 0) latest = value;
    }
    return latest;
  }

  /// 진행 한 줄에 쓰는 채널 표시명 — '판매자 · 플랫폼'(고객문의 화면과 같은 문자열).
  String _channelLabel(SyncTarget target) =>
      '${target.sellerName} · ${target.platform}';

  /// 공용 조회 — [SearchClaims] 와 [SelectClaimType] 이 **같은 파라미터 조립**을 쓰게 한다
  /// (두 벌이 되면 탭 전환만 검색어가 빠지는 버그가 난다).
  ///
  /// [base] 는 방금 emit 한 Loaded 상태 — 여기서 판매자·기간·검색어·claimType 을 모두 읽는다.
  /// ⚠️ `state` 를 다시 읽어 파생값을 만들지 말 것(emit 후 재조회 금지 관례).
  /// [period] 를 주면 그 기간으로 조회한다 — 동기화 후 재조회가 **목록이 담고 있던 기간**
  /// (`appliedPeriod`)을 쓰기 위한 것이다. 생략하면 드롭다운에서 고른 기간이다.
  Future<void> _fetch(
    Emitter<ClaimListState> emit,
    ClaimListLoaded base, {
    required bool clearOnFailure,
    String? period,
  }) async {
    final effectivePeriod = period ?? base.selectedPeriod;
    final range = toPeriodRange(effectivePeriod);
    final term = base.searchTerm.trim();
    final result = await claimUseCase.getClaims(
      type: base.claimType,
      sellerId: base.selectedSellerId,
      // 상태는 서버로 보내지 않는다 — 칩이 클라이언트 필터라 건수 배지가 항상 전체를 세야 한다.
      keyword: term.isEmpty ? null : term,
      from: range?.from,
      to: range?.to,
    );
    if (emit.isDone) return;
    result.fold(
      // 재조회 실패는 **기존 목록을 지우지 않는다** — SnackBar 로만 알린다.
      // appliedPeriod 도 그대로 둔다(목록이 여전히 이전 기간을 담고 있다).
      // ⚠️ 탭 전환(clearOnFailure)만 예외다 — 탭은 이미 바뀌었는데 이전 탭의 목록이 남으면
      // 화면과 데이터가 어긋나므로 비우고 actionError 로 알린다.
      // ⚠️ `copyWith(claims: null)` 은 `??` 관례상 '기존 유지' 라 삼항으로 값을 고른다.
      (failure) => emit(base.copyWith(
        isSearching: false,
        actionError: failure.message,
        claims: clearOnFailure ? const <Claim>[] : null,
      )),
      (claims) => emit(base.copyWith(
        isSearching: false,
        claims: claims,
        appliedPeriod: effectivePeriod,
      )),
    );
  }
}
