import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../../settlement/presentation/utils/settlement_format.dart';
import '../../domain/entities/stock_work.dart';
import '../../domain/usecases/claim_work_usecase.dart';
import 'outbound_work_cubit.dart';

/// Texts that differ between the two claim work tabs (FEATURE_2611_34 R14 ·
/// R27). Every such text lives in [kClaimWorkText] only.
class ClaimWorkText {
  final String invoiceHint;
  final String allDone;

  /// Followed by the scanned barcode.
  final String notInClaim;
  final String unknownItems;
  final String requiredLabel;
  final String doneLabel;
  final String enteredLabel;
  final String dateLabel;
  final String saveLabel;
  final String saved;
  final String saveFail;

  const ClaimWorkText({
    required this.invoiceHint,
    required this.allDone,
    required this.notInClaim,
    required this.unknownItems,
    required this.requiredLabel,
    required this.doneLabel,
    required this.enteredLabel,
    required this.dateLabel,
    required this.saveLabel,
    required this.saved,
    required this.saveFail,
  });
}

/// The one table of the claim work texts (FEATURE_2611_34 R14 · R27).
const Map<ClaimWorkKind, ClaimWorkText> kClaimWorkText = {
  ClaimWorkKind.returnIntake: ClaimWorkText(
    invoiceHint: '반품 송장을 스캔하거나 입력하세요',
    allDone: '이 반품은 모두 재입고했습니다',
    notInClaim: '이 반품에 없는 물건입니다: ',
    unknownItems: '이 반품은 받을 물건을 알 수 없습니다 — 입고·조정 화면의 반품 대기에서 기록하세요',
    requiredLabel: '받을 수량',
    doneLabel: '이미 재입고',
    enteredLabel: '이번 들어온 수량',
    dateLabel: '재입고일',
    saveLabel: '반품 재입고 저장',
    saved: '반품 재입고를 저장했습니다.',
    saveFail: '반품 재입고를 저장하지 못했습니다.',
  ),
  ClaimWorkKind.exchangeShip: ClaimWorkText(
    invoiceHint: '교환 송장을 스캔하거나 입력하세요',
    allDone: '이 교환은 모두 발송했습니다',
    notInClaim: '이 교환에 없는 물건입니다: ',
    unknownItems: '이 교환은 보낼 물건을 알 수 없습니다 — 판매상품의 옵션 연결을 고친 뒤 다시 여세요',
    requiredLabel: '보낼 수량',
    doneLabel: '이미 발송',
    enteredLabel: '이번 보낸 수량',
    dateLabel: '발송일',
    saveLabel: '교환 발송 저장',
    saved: '교환 발송을 저장했습니다.',
    saveFail: '교환 발송을 저장하지 못했습니다.',
  ),
};

/// Input hint while 「송장 없이 반품 완료」 is on (R14).
const String kNoInvoiceHint = '박스 출고 송장을 스캔하거나 입력하세요';

/// Input hint while a claim is open (R14).
const String kItemHint = '물건 바코드를 스캔하거나 입력하세요';

/// Guide under 「송장 없이 반품 완료」 (R14).
const String kNoInvoiceGuide = '박스의 출고 송장을 찍거나 아래 목록에서 주문을 고르세요.';

/// 「송장 대기」 · 「담는 중」 (FEATURE_2611_34 D17).
enum ClaimWorkPhase { invoice, items }

/// State of one claim work tab (FEATURE_2611_34 D16 ~ D33 · D42).
class ClaimWorkState {
  final ClaimWorkPhase phase;

  /// 「송장 없이 반품 완료」 is on (R18).
  final bool noInvoice;

  /// Open claims, in the server order (D22).
  final List<ClaimWork> claims;

  /// 「이번 수량」 texts by [claimItemKey].
  final Map<String, String> entered;
  final String movedOn;
  final bool busy;
  final bool listLoading;

  /// Recently shipped orders of 「송장 없이 반품 완료」 (D29).
  final List<ShippedOrder> orders;

  /// Exchanges still to send (D42).
  final List<ClaimWork> exchanges;
  final StockWorkNotice? notice;

  const ClaimWorkState({
    required this.movedOn,
    this.phase = ClaimWorkPhase.invoice,
    this.noInvoice = false,
    this.claims = const [],
    this.entered = const {},
    this.busy = false,
    this.listLoading = false,
    this.orders = const [],
    this.exchanges = const [],
    this.notice,
  });

  /// Fields holding a quantity above 0.
  int get enteredCount =>
      entered.values.where((v) => (int.tryParse(v.trim()) ?? 0) > 0).length;

  ClaimWorkState copyWith({
    ClaimWorkPhase? phase,
    bool? noInvoice,
    List<ClaimWork>? claims,
    Map<String, String>? entered,
    String? movedOn,
    bool? busy,
    bool? listLoading,
    List<ShippedOrder>? orders,
    List<ClaimWork>? exchanges,
    StockWorkNotice? notice,
  }) =>
      ClaimWorkState(
        phase: phase ?? this.phase,
        noInvoice: noInvoice ?? this.noInvoice,
        claims: claims ?? this.claims,
        entered: entered ?? this.entered,
        movedOn: movedOn ?? this.movedOn,
        busy: busy ?? this.busy,
        listLoading: listLoading ?? this.listLoading,
        orders: orders ?? this.orders,
        exchanges: exchanges ?? this.exchanges,
        notice: notice ?? this.notice,
      );
}

/// Shared cubit of the claim work tabs (FEATURE_2611_34 D16 ~ D33 · D42).
///
/// **Purpose**: finds claims by an invoice (or a list pick), collects the
/// scanned products into (claim × product) quantities and saves them at once.
/// **File**: stock_ledger/presentation/bloc/claim_work_cubit.dart
/// **Used by**: 「입고 작업」 「반품 재입고」 tab ([ClaimWorkKind.returnIntake])
/// and 「출고 작업」 「교환 발송」 tab ([ClaimWorkKind.exchangeShip]).
///
/// ```dart
/// BlocProvider(
///   create: (_) =>
///       getIt<ClaimWorkCubit>(param1: ClaimWorkKind.returnIntake),
/// )
/// ```
///
/// - One claim invoice open at a time: 「송장 대기」 → 「담는 중」 (D17).
/// - A product scan never calls the server — it matches the opened items
///   (R16) and fills the earliest received claim first (D22).
/// ⚠️ Registered by `getIt` as a factory with the kind as `param1`.
/// ❌ Do not write the tab texts in the widgets — read [text] (R14).
class ClaimWorkCubit extends Cubit<ClaimWorkState> {
  final ClaimWorkKind kind;
  final ClaimWorkUseCase claimWorkUseCase;

  ClaimWorkCubit({required this.kind, required this.claimWorkUseCase})
      : super(ClaimWorkState(movedOn: toDateText(DateTime.now())));

  ClaimWorkText get text => kClaimWorkText[kind]!;

  /// Hint of the barcode input field (R14).
  String get hint {
    if (state.phase == ClaimWorkPhase.items) {
      return kItemHint;
    }
    return state.noInvoice ? kNoInvoiceHint : text.invoiceHint;
  }

  void _notify(StockWorkNoticeKind kind, String message) {
    emit(state.copyWith(notice: StockWorkNotice(kind, message)));
  }

  /// One value from the input field — an invoice or a product barcode.
  Future<void> scan(String value) async {
    final scanned = value.trim();
    if (scanned.isEmpty || state.busy) {
      return;
    }
    if (state.phase == ClaimWorkPhase.items) {
      _addItem(scanned);
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await _lookup(scanned);
    if (isClosed) {
      return;
    }
    emit(state.copyWith(busy: false));
    result.fold(
      (failure) => _notify(StockWorkNoticeKind.error, failure.message),
      _open,
    );
  }

  Future<Either<Failure, List<ClaimWork>>> _lookup(String value) {
    if (kind == ClaimWorkKind.exchangeShip) {
      return claimWorkUseCase.claimsByReshipInvoice(value);
    }
    if (state.noInvoice) {
      return claimWorkUseCase.claimsByParcelInvoice(value);
    }
    return claimWorkUseCase.claimsByReturnInvoice(value);
  }

  /// +1 on the first open field of the scanned product (R16).
  void _addItem(String barcode) {
    String? fullName;
    for (final claim in state.claims) {
      if (claim.failure != null) {
        continue;
      }
      for (final item in claim.items) {
        if (item.barcode?.trim() != barcode) {
          continue;
        }
        final key = claimItemKey(claim.orderClaimId, item.productId);
        final count = int.tryParse(state.entered[key]?.trim() ?? '') ?? 0;
        if (count < item.remainingQty) {
          emit(state.copyWith(
            entered: {...state.entered, key: '${count + 1}'},
          ));
          return;
        }
        fullName ??= item.productName;
      }
    }
    if (fullName == null) {
      _notify(StockWorkNoticeKind.error, text.notInClaim + barcode);
      return;
    }
    _notify(
      StockWorkNoticeKind.error,
      '$fullName은 더 받을 수 없습니다(남은 0개)',
    );
  }

  /// Opens the found claims, or stays in 「송장 대기」 (R17).
  void _open(List<ClaimWork> list) {
    final usable = [
      for (final claim in list)
        if (claim.failure == null) claim,
    ];
    if (usable.isEmpty) {
      _notify(StockWorkNoticeKind.error, text.unknownItems);
      return;
    }
    final left = usable.any(
      (claim) => claim.items.any((item) => item.remainingQty > 0),
    );
    if (!left) {
      _notify(StockWorkNoticeKind.error, text.allDone);
      return;
    }
    emit(state.copyWith(
      phase: ClaimWorkPhase.items,
      claims: list,
      entered: const {},
    ));
  }

  /// [송장 없이 반품 완료] on / off — 「반품 재입고」 · 「송장 대기」 only (R18).
  Future<void> toggleNoInvoice() async {
    if (kind != ClaimWorkKind.returnIntake ||
        state.phase != ClaimWorkPhase.invoice) {
      return;
    }
    if (state.noInvoice) {
      emit(state.copyWith(noInvoice: false));
      return;
    }
    emit(state.copyWith(noInvoice: true, listLoading: true));
    final result = await claimWorkUseCase.shippedOrders();
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => _notify(StockWorkNoticeKind.error, failure.message),
      (orders) => emit(state.copyWith(orders: orders)),
    );
    emit(state.copyWith(listLoading: false));
  }

  /// [고르기] on a shipped order (D25 ② · D27).
  Future<void> pickOrder(ShippedOrder order) async {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await claimWorkUseCase.claimsByOrder(order.orderId);
    if (isClosed) {
      return;
    }
    emit(state.copyWith(busy: false));
    result.fold(
      (failure) => _notify(StockWorkNoticeKind.error, failure.message),
      _open,
    );
  }

  /// [고르기] on an exchange — opens that one claim (R19).
  void pickExchange(ClaimWork claim) {
    _open([claim]);
  }

  /// Exchanges still to send — 「교환 발송」 only (D42).
  Future<void> loadExchanges() async {
    if (kind != ClaimWorkKind.exchangeShip) {
      return;
    }
    emit(state.copyWith(listLoading: true));
    final result = await claimWorkUseCase.openExchanges();
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => _notify(StockWorkNoticeKind.error, failure.message),
      (exchanges) => emit(state.copyWith(exchanges: exchanges)),
    );
    emit(state.copyWith(listLoading: false));
  }

  void changeEntered(String key, String text) {
    emit(state.copyWith(entered: {...state.entered, key: text}));
  }

  void changeMovedOn(String movedOn) {
    emit(state.copyWith(movedOn: movedOn));
  }

  /// Back to an empty 「송장 대기」 with 「송장 없이 반품 완료」 off (R18).
  void reset() {
    emit(state.copyWith(
      phase: ClaimWorkPhase.invoice,
      claims: const [],
      entered: const {},
      noInvoice: false,
    ));
  }

  /// [반품 재입고 저장] · [교환 발송 저장] — every field above 0 at once.
  Future<void> save() async {
    if (state.busy) {
      return;
    }
    final digits = RegExp(r'^\d+$');
    final bad = state.entered.values.map((v) => v.trim()).any(
          (v) => v.isNotEmpty && v != '0' && !digits.hasMatch(v),
        );
    if (bad) {
      _notify(
        StockWorkNoticeKind.input,
        '수량은 0 이상 정수만 입력할 수 있습니다.',
      );
      return;
    }
    final lines = <ClaimWorkLineRequest>[];
    for (final claim in state.claims) {
      if (claim.failure != null) {
        continue;
      }
      for (final item in claim.items) {
        final key = claimItemKey(claim.orderClaimId, item.productId);
        final count = int.tryParse(state.entered[key]?.trim() ?? '') ?? 0;
        if (count <= 0) {
          continue;
        }
        if (count > item.remainingQty) {
          _notify(
            StockWorkNoticeKind.error,
            '${item.productName}은 더 받을 수 없습니다'
            '(남은 ${item.remainingQty}개)',
          );
          return;
        }
        lines.add(ClaimWorkLineRequest(
          orderClaimId: claim.orderClaimId,
          productId: item.productId,
          quantity: count,
        ));
      }
    }
    if (lines.isEmpty) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = kind == ClaimWorkKind.returnIntake
        ? await claimWorkUseCase.returnWork(
            movedOn: state.movedOn,
            lines: lines,
            fallback: text.saveFail,
          )
        : await claimWorkUseCase.exchangeWork(
            movedOn: state.movedOn,
            lines: lines,
            fallback: text.saveFail,
          );
    if (isClosed) {
      return;
    }
    emit(state.copyWith(busy: false));
    await result.fold(
      (failure) async =>
          _notify(StockWorkNoticeKind.error, failure.message),
      (_) async {
        _notify(StockWorkNoticeKind.success, text.saved);
        reset();
        if (kind == ClaimWorkKind.exchangeShip) {
          await loadExchanges();
        }
      },
    );
  }
}
