import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/claim_usecase.dart';
import 'claim_list_event.dart';
import 'claim_list_state.dart';

/// 반품/교환 목록 BLoC (FEATURE_2609_18 Stage A — 반품 조회 전용).
///
/// - 진입 시 판매자 목록 + 기본 창(최근 2주) 조회 ([LoadClaims])
/// - 판매자·기간·검색어는 **고르기만** 하고, [SearchClaims](조회 버튼)에서 서버로 보낸다
/// - 상태 칩([SelectStatus])은 클라이언트 필터라 서버를 부르지 않는다
///
/// 판매자 목록은 기존 seller 기능의 [GetSellersUseCase] 를 재사용한다(신규 API 없음).
///
/// ⚠️ [ClaimType.returnClaim] 상수 고정이 의도다 — Stage A 는 반품만이다.
/// 교환 탭과 그 state 는 후속(08)이 추가한다.
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
  }

  /// Stage A 는 반품만 조회한다(08 이 교환 탭을 붙일 때 state 로 승격된다).
  static const _type = ClaimType.returnClaim;

  Future<void> _onLoad(LoadClaims event, Emitter<ClaimListState> emit) async {
    emit(ClaimListLoading());

    // 판매자 목록 실패는 비치명적: 드롭다운만 '전체'로 폴백(주문내역과 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);

    // 기본값이 kRecentPeriod 라 from/to 를 보내지 않는다 = 서버 기본 창.
    final result = await claimUseCase.getClaims(type: _type);
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

    emit(current.copyWith(isSearching: true, clearActionError: true));

    final range = toPeriodRange(current.selectedPeriod);
    final term = current.searchTerm.trim();
    final result = await claimUseCase.getClaims(
      type: _type,
      sellerId: current.selectedSellerId,
      // 상태는 서버로 보내지 않는다 — 칩이 클라이언트 필터라 건수 배지가 항상 전체를 세야 한다.
      keyword: term.isEmpty ? null : term,
      from: range?.from,
      to: range?.to,
    );
    if (emit.isDone) return;
    result.fold(
      // 재조회 실패는 **기존 목록을 지우지 않는다** — SnackBar 로만 알린다.
      // appliedPeriod 도 그대로 둔다(목록이 여전히 이전 기간을 담고 있다).
      (failure) => emit(current.copyWith(
        isSearching: false,
        actionError: failure.message,
      )),
      (claims) => emit(current.copyWith(
        isSearching: false,
        claims: claims,
        appliedPeriod: current.selectedPeriod,
      )),
    );
  }
}
