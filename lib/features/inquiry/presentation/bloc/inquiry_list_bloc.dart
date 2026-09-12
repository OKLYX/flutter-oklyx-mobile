import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/sync_target.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_type_option.dart';
import '../../domain/usecases/inquiry_usecase.dart';
import 'inquiry_list_event.dart';
import 'inquiry_list_state.dart';

/// 고객문의 목록 BLoC (FEATURE_2609_36).
///
/// - 진입 시 유형 목록(`/types`) + 판매자 + 동기화 대상 + 기본 창 조회 ([LoadInquiries])
/// - 유형 탭([SelectType])은 **서버 파라미터**라 전환 즉시 재조회한다
/// - 판매자·채널·기간·검색어는 **고르기만** 하고 [SearchInquiries](조회 버튼)에서 보낸다
/// - 상태 칩([SelectStatus])은 클라이언트 필터라 서버를 부르지 않는다
/// - [SyncInquiries] 는 채널을 하나씩 돌며 `POST /api/inquiries/sync` 를 부른다(M4)
///
/// 판매자 목록은 [GetSellersUseCase], 동기화 대상은 [OrderUseCase.getSyncTargets] 를
/// **재사용**한다 — 문의 전용 API 를 새로 만들지 않는다.
class InquiryListBloc extends Bloc<InquiryListEvent, InquiryListState> {
  final InquiryUseCase inquiryUseCase;
  final GetSellersUseCase getSellersUseCase;
  final OrderUseCase orderUseCase;

  InquiryListBloc({
    required this.inquiryUseCase,
    required this.getSellersUseCase,
    required this.orderUseCase,
  }) : super(InquiryListInitial()) {
    on<LoadInquiries>(_onLoad);
    on<SelectType>(_onSelectType);
    on<SelectSeller>(_onSelectSeller);
    on<SelectChannel>(_onSelectChannel);
    on<SelectPeriod>(_onSelectPeriod);
    on<ChangeSearchTerm>(_onChangeSearchTerm);
    on<SearchInquiries>(_onSearch);
    on<SelectStatus>(_onSelectStatus);
    on<SyncInquiries>(_onSync);
    on<ActionErrorCleared>(_onActionErrorCleared);
  }

  Future<void> _onLoad(
    LoadInquiries event,
    Emitter<InquiryListState> emit,
  ) async {
    emit(InquiryListLoading());

    // 판매자·동기화 대상 실패는 비치명적: 드롭다운만 좁아진다(주문내역과 동일).
    final sellersResult = await getSellersUseCase();
    final sellers = sellersResult.fold((_) => <Seller>[], (list) => list);
    final targets = await _fetchTargets(null);

    // `/types` 실패 시 탭을 그리지 않고 **유형 없이 전체 조회**한다 — 화면이 비지 않게
    // (웹 `InquiryContainer` 와 같은 폴백).
    final typesResult = await inquiryUseCase.getTypeOptions();
    final typeOptions =
        typesResult.fold((_) => <InquiryTypeOption>[], (list) => list);
    // 기본 탭 = 첫 항목(웹과 같다). 후보가 없으면 null = 전체 유형.
    final selectedType =
        typeOptions.isEmpty ? null : typeOptions.first.code;

    // 기본값이 kRecentPeriod 라 from/to 를 보내지 않는다 = 서버 기본 창(최근 14일).
    final result = await inquiryUseCase.getInquiries(type: selectedType);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(InquiryListError(message: failure.message)),
      (inquiries) => emit(InquiryListLoaded(
        inquiries: inquiries,
        typeOptions: typeOptions,
        selectedType: selectedType,
        sellers: sellers,
        syncTargets: targets,
      )),
    );
  }

  /// 유형 탭 전환 — 탭은 **서버 파라미터**라 즉시 재조회한다.
  /// 🔴 [InquiryListLoading] 을 emit 하지 않는 규칙은 [_onSearch] 와 같다.
  Future<void> _onSelectType(
    SelectType event,
    Emitter<InquiryListState> emit,
  ) async {
    final current = state;
    if (current is! InquiryListLoaded) return;
    if (current.selectedType == event.type || current.busy) return;

    // 🔴 상태 칩을 해제한다 — 건수 배지는 이전 유형의 목록에서 센 값이라, 선택을 남기면
    // 새 목록이 0건이 되는데 화면에는 이유가 없다(웹과 같은 처리).
    final next = current.copyWith(
      selectedType: event.type,
      clearSelectedStatus: true,
      isSearching: true,
      clearActionError: true,
      clearSyncSummary: true,
    );
    emit(next);

    // 탭이 이미 바뀌었으므로 실패 시 목록을 비운다(재조회와 판단이 반대인 유일한 지점).
    await _fetch(emit, next, period: next.selectedPeriod, clearOnFailure: true);
  }

  /// 판매자 선택 — 목록은 [SearchInquiries] 때 반영하되, **채널 옵션은 지금 좁힌다**
  /// (웹 `InquiryContainer` 의 채널 로딩과 같다). 좁힌 목록에 고른 채널이 없으면
  /// 전체 채널로 되돌린다 — 그대로 두면 결과가 없는 조합이 남는다.
  Future<void> _onSelectSeller(
    SelectSeller event,
    Emitter<InquiryListState> emit,
  ) async {
    final current = state;
    if (current is! InquiryListLoaded) return;

    emit(current.copyWith(
      selectedSellerId: event.sellerId,
      clearSelectedSeller: event.sellerId == null,
    ));

    final targets = await _fetchTargets(event.sellerId);
    if (emit.isDone) return;
    final latest = state;
    if (latest is! InquiryListLoaded) return;
    final stillThere =
        targets.any((t) => t.accountId == latest.selectedAccountId);
    emit(latest.copyWith(
      syncTargets: targets,
      clearSelectedAccount: !stillThere,
    ));
  }

  void _onSelectChannel(
    SelectChannel event,
    Emitter<InquiryListState> emit,
  ) {
    final current = state;
    if (current is! InquiryListLoaded) return;
    emit(current.copyWith(
      selectedAccountId: event.accountId,
      clearSelectedAccount: event.accountId == null,
    ));
  }

  void _onSelectPeriod(SelectPeriod event, Emitter<InquiryListState> emit) {
    final current = state;
    if (current is! InquiryListLoaded) return;
    emit(current.copyWith(selectedPeriod: event.period));
  }

  void _onChangeSearchTerm(
    ChangeSearchTerm event,
    Emitter<InquiryListState> emit,
  ) {
    final current = state;
    if (current is! InquiryListLoaded) return;
    emit(current.copyWith(searchTerm: event.term));
  }

  /// 상태 칩 — 클라이언트 필터라 서버를 부르지 않는다(목록은 `visible` 로 파생).
  void _onSelectStatus(SelectStatus event, Emitter<InquiryListState> emit) {
    final current = state;
    if (current is! InquiryListLoaded) return;
    emit(current.copyWith(
      selectedStatus: event.status,
      clearSelectedStatus: event.status == null,
    ));
  }

  void _onActionErrorCleared(
    ActionErrorCleared event,
    Emitter<InquiryListState> emit,
  ) {
    final current = state;
    if (current is! InquiryListLoaded) return;
    emit(current.copyWith(clearActionError: true, clearSyncSummary: true));
  }

  /// 조회 버튼 — 🔴 [InquiryListLoading] 을 emit 하지 않는다.
  /// 필터 UI 를 유지한 채 [InquiryListLoaded.isSearching] 만 켠다.
  Future<void> _onSearch(
    SearchInquiries event,
    Emitter<InquiryListState> emit,
  ) async {
    final current = state;
    if (current is! InquiryListLoaded) return;
    if (current.busy) return;

    final next = current.copyWith(
      isSearching: true,
      clearActionError: true,
      clearSyncSummary: true,
    );
    emit(next);

    // 재조회 실패는 기존 목록을 지키므로 clearOnFailure = false.
    await _fetch(emit, next, period: next.selectedPeriod, clearOnFailure: false);
  }

  /// 문의만 가져오기(M4) — 채널을 **하나씩** 돌며 진행을 상태로 올린다.
  ///
  /// ⚠️ `SyncProgressDialog` 를 쓰지 않는다 — 그 위젯은 `OrderListBloc`/`OrderListState` 를
  /// 직접 읽는다. 여기서 쓰려면 검증된 주문 동기화 화면을 건드려야 한다.
  /// ⚠️ 한 채널이 실패해도 **루프를 멈추지 않는다**(채널별 격리). 실패 사유는 서버 문구를
  /// 그대로 쓴다 — 앱이 지어내지 않는다.
  Future<void> _onSync(
    SyncInquiries event,
    Emitter<InquiryListState> emit,
  ) async {
    final current = state;
    if (current is! InquiryListLoaded) return;
    if (current.busy) return;

    final selected = current.selectedAccountId;
    final targets = selected == null
        ? current.syncTargets
        : current.syncTargets.where((t) => t.accountId == selected).toList();
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

    var fetched = 0;
    var failed = 0;
    String? firstError;
    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      running = running.copyWith(syncingChannelName: _channelLabel(target));
      emit(running);

      final result = await inquiryUseCase.syncInquiries(target.accountId);
      if (emit.isDone) return;
      result.fold(
        (failure) {
          failed++;
          firstError ??= failure.message;
        },
        (syncResult) => fetched += syncResult.fetched,
      );

      running = running.copyWith(syncDone: i + 1);
      emit(running);
    }

    // 루프 직후 스피너를 푼다(웹과 같은 자세) — 목록 재조회는 이어서 돈다.
    // 요약은 성공만이면 syncSummary, 실패가 있으면 actionError 로 나눠 올린다
    // (성공 요약을 에러 자리에 넣지 않는다).
    running = running.copyWith(
      isSyncing: false,
      clearSyncingChannelName: true,
      isSearching: true,
      actionError:
          failed > 0 ? '가져오기 실패 $failed건 — ${firstError ?? ''}' : null,
      syncSummary: failed > 0 ? null : '문의 $fetched건을 가져왔습니다.',
    );
    emit(running);

    // 🔴 재조회는 **목록이 담고 있던 기간**(appliedPeriod)으로 한다 — 사용자가 그 사이
    // 드롭다운만 만져 둔 기간을 쓰면 말없이 다른 조회가 된다.
    await _fetch(
      emit,
      running,
      period: running.appliedPeriod,
      clearOnFailure: false,
    );
  }

  /// 공용 조회 — 탭 전환·조회 버튼·동기화 후 재조회가 **같은 파라미터 조립**을 쓰게 한다
  /// (두 벌이 되면 한쪽만 검색어가 빠지는 버그가 난다).
  ///
  /// [base] 는 방금 emit 한 Loaded 상태 — 여기서 유형·판매자·채널·검색어를 모두 읽는다.
  /// ⚠️ `state` 를 다시 읽어 파생값을 만들지 말 것(emit 후 재조회 금지 관례).
  Future<void> _fetch(
    Emitter<InquiryListState> emit,
    InquiryListLoaded base, {
    required String period,
    required bool clearOnFailure,
  }) async {
    final range = toPeriodRange(period);
    final term = base.searchTerm.trim();
    final result = await inquiryUseCase.getInquiries(
      type: base.selectedType,
      // 상태는 서버로 보내지 않는다 — 칩이 클라이언트 필터라 건수 배지가 항상 전체를 세야 한다.
      accountId: base.selectedAccountId,
      sellerId: base.selectedSellerId,
      from: range?.from,
      to: range?.to,
      keyword: term.isEmpty ? null : term,
    );
    if (emit.isDone) return;
    result.fold(
      // 재조회 실패는 **기존 목록을 지우지 않는다** — SnackBar 로만 알린다.
      // ⚠️ 탭 전환(clearOnFailure)만 예외다 — 탭은 이미 바뀌었는데 이전 유형의 목록이
      // 남으면 화면과 데이터가 어긋난다.
      // ⚠️ `copyWith(inquiries: null)` 은 `??` 관례상 '기존 유지' 라 삼항으로 값을 고른다.
      (failure) => emit(base.copyWith(
        isSearching: false,
        actionError: failure.message,
        inquiries: clearOnFailure ? const <Inquiry>[] : null,
      )),
      (inquiries) => emit(base.copyWith(
        isSearching: false,
        inquiries: inquiries,
        appliedPeriod: period,
      )),
    );
  }

  /// 동기화 대상 조회 — 실패는 비치명적이라 빈 목록으로 떨어뜨린다(채널 드롭다운만 좁아진다).
  Future<List<SyncTarget>> _fetchTargets(int? sellerId) async {
    final result = await orderUseCase.getSyncTargets(sellerId: sellerId);
    return result.fold((_) => <SyncTarget>[], (targets) => targets);
  }

  /// 진행 한 줄에 쓰는 채널 표시명 — '판매자 · 플랫폼'.
  String _channelLabel(SyncTarget target) =>
      '${target.sellerName} · ${target.platform}';
}
