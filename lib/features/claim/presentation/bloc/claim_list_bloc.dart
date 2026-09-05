import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
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
///
/// 판매자 목록은 기존 seller 기능의 [GetSellersUseCase] 를 재사용한다(신규 API 없음).
class ClaimListBloc extends Bloc<ClaimListEvent, ClaimListState> {
  final ClaimUseCase claimUseCase;
  final GetSellersUseCase getSellersUseCase;

  ClaimListBloc({
    required this.claimUseCase,
    required this.getSellersUseCase,
  }) : super(ClaimListInitial()) {
    on<LoadClaims>(_onLoad);
    on<SelectSeller>(_onSelectSeller);
    on<SelectPeriod>(_onSelectPeriod);
    on<ChangeSearchTerm>(_onChangeSearchTerm);
    on<SearchClaims>(_onSearch);
    on<SelectStatus>(_onSelectStatus);
    on<SelectClaimType>(_onSelectClaimType);
  }

  Future<void> _onLoad(LoadClaims event, Emitter<ClaimListState> emit) async {
    emit(ClaimListLoading());

    // 판매자 목록 실패는 비치명적: 드롭다운만 '전체'로 폴백(주문내역과 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    // 기본값이 kRecentPeriod 라 from/to 를 보내지 않는다 = 서버 기본 창.
    // 진입 탭은 반품 고정 — ClaimListLoaded 의 claimType 기본값과 같아야 한다.
    final result = await claimUseCase.getClaims(type: ClaimType.returnClaim);
    result.fold(
      (failure) => emit(ClaimListError(message: failure.message)),
      (claims) => emit(ClaimListLoaded(claims: claims, sellers: sellers)),
    );
  }

  void _onSelectSeller(SelectSeller event, Emitter<ClaimListState> emit) {
    final current = state;
    if (current is! ClaimListLoaded) return;
    emit(current.copyWith(
      selectedSellerId: event.sellerId,
      clearSelectedSeller: event.sellerId == null,
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
    if (current.isSearching) return;

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
    if (current.claimType == event.type || current.isSearching) return;

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

  /// 공용 조회 — [SearchClaims] 와 [SelectClaimType] 이 **같은 파라미터 조립**을 쓰게 한다
  /// (두 벌이 되면 탭 전환만 검색어가 빠지는 버그가 난다).
  ///
  /// [base] 는 방금 emit 한 Loaded 상태 — 여기서 판매자·기간·검색어·claimType 을 모두 읽는다.
  /// ⚠️ `state` 를 다시 읽어 파생값을 만들지 말 것(emit 후 재조회 금지 관례).
  Future<void> _fetch(
    Emitter<ClaimListState> emit,
    ClaimListLoaded base, {
    required bool clearOnFailure,
  }) async {
    final range = toPeriodRange(base.selectedPeriod);
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
        appliedPeriod: base.selectedPeriod,
      )),
    );
  }
}
