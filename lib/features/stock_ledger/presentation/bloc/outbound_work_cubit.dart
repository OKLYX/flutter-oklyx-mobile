import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../seller/domain/entities/seller.dart';
import '../../../seller/domain/usecases/get_sellers_usecase.dart';
import '../../../settlement/presentation/utils/settlement_format.dart';
import '../../domain/entities/stock_enums.dart';
import '../../domain/entities/stock_work.dart';
import '../../domain/usecases/outbound_work_usecase.dart';
import '../../domain/usecases/stock_intake_usecase.dart';

/// Toast kinds of the stock work screens (FEATURE_2611_34 R21).
enum StockWorkNoticeKind { success, error, input }

/// One toast of the stock work screens (FEATURE_2611_34 R21).
///
/// **Purpose**: the cubit hands one message to the page, which shows it as
/// a success, error or input-notice toast by [kind].
/// **File**: stock_ledger/presentation/bloc/outbound_work_cubit.dart
/// **Used by**: 「출고 작업」 (this file), and the 「입고 작업」
/// 「반품 재입고」 tab and the 「출고 작업」 「교환 발송」 tab.
///
/// ```dart
/// emit(state.copyWith(
///   notice: StockWorkNotice(StockWorkNoticeKind.input, '…'),
/// ));
/// ```
///
/// ⚠️ Make a new object every time — the page listens with
/// `p.notice != c.notice`, so the same text shows again only that way.
/// ❌ Do not keep and re-emit an old notice object.
class StockWorkNotice {
  final StockWorkNoticeKind kind;
  final String message;

  StockWorkNotice(this.kind, this.message);
}

/// Tabs of 「출고 작업」 (FEATURE_2611_34 D3).
enum OutboundWorkTab { disposal, supplierReturn, exchangeShip }

/// One collected line of 「출고 작업」 (FEATURE_2611_34 D9 · D11 · D13).
class OutboundWorkLine {
  /// Screen-local key, stable while the line lives.
  final int key;
  final int productId;
  final String productName;
  final String quantityText;
  final int sellerId;
  final StockReason reason;

  /// Kept only while [reason] is [StockReason.etc] (R25).
  final String reasonNote;

  /// Seller or reason was set on this line (「따로 정함」).
  final bool custom;

  const OutboundWorkLine({
    required this.key,
    required this.productId,
    required this.productName,
    required this.quantityText,
    required this.sellerId,
    required this.reason,
    required this.reasonNote,
    required this.custom,
  });

  OutboundWorkLine copyWith({
    String? quantityText,
    int? sellerId,
    StockReason? reason,
    String? reasonNote,
    bool? custom,
  }) =>
      OutboundWorkLine(
        key: key,
        productId: productId,
        productName: productName,
        quantityText: quantityText ?? this.quantityText,
        sellerId: sellerId ?? this.sellerId,
        reason: reason ?? this.reason,
        reasonNote: reasonNote ?? this.reasonNote,
        custom: custom ?? this.custom,
      );
}

/// Values of one tab — kept apart per tab (FEATURE_2611_34 R12).
class OutboundBasket {
  final String movedOn;
  final int? screenSellerId;
  final StockReason screenReason;
  final List<OutboundWorkLine> lines;

  const OutboundBasket({
    required this.movedOn,
    required this.screenReason,
    this.screenSellerId,
    this.lines = const [],
  });

  OutboundBasket copyWith({
    String? movedOn,
    int? screenSellerId,
    bool clearScreenSellerId = false,
    StockReason? screenReason,
    List<OutboundWorkLine>? lines,
  }) =>
      OutboundBasket(
        movedOn: movedOn ?? this.movedOn,
        screenSellerId: clearScreenSellerId
            ? null
            : (screenSellerId ?? this.screenSellerId),
        screenReason: screenReason ?? this.screenReason,
        lines: lines ?? this.lines,
      );
}

/// State of the 「출고 작업」 screen (FEATURE_2611_34 D3 · D9 · D11).
class OutboundWorkState {
  final OutboundWorkTab tab;
  final List<Seller> sellers;
  final OutboundBasket disposal;
  final OutboundBasket supplierReturn;
  final bool busy;
  final StockWorkNotice? notice;

  const OutboundWorkState({
    required this.disposal,
    required this.supplierReturn,
    this.tab = OutboundWorkTab.disposal,
    this.sellers = const [],
    this.busy = false,
    this.notice,
  });

  /// The only seller of a one-seller account (D9).
  Seller? get soleSeller => sellers.length == 1 ? sellers.first : null;

  OutboundBasket basketOf(OutboundWorkTab tab) => switch (tab) {
        OutboundWorkTab.disposal => disposal,
        OutboundWorkTab.supplierReturn => supplierReturn,
        OutboundWorkTab.exchangeShip =>
          throw StateError('「교환 발송」 has no basket'),
      };

  OutboundWorkState copyWith({
    OutboundWorkTab? tab,
    List<Seller>? sellers,
    OutboundBasket? disposal,
    OutboundBasket? supplierReturn,
    bool? busy,
    StockWorkNotice? notice,
  }) =>
      OutboundWorkState(
        tab: tab ?? this.tab,
        sellers: sellers ?? this.sellers,
        disposal: disposal ?? this.disposal,
        supplierReturn: supplierReturn ?? this.supplierReturn,
        busy: busy ?? this.busy,
        notice: notice ?? this.notice,
      );
}

/// Cubit of the 「출고 작업」 screen (FEATURE_2611_34 D3 · D9 ~ D15).
///
/// **Purpose**: collects scanned products into the lines of the current tab
/// and saves that tab's lines at once.
/// **File**: stock_ledger/presentation/bloc/outbound_work_cubit.dart
///
/// - Every change touches only the current tab's basket (R12).
/// - A scan adds 1 to the first line with the same product, screen seller
///   and screen reason, else appends a new line (R24).
/// - No scan before a screen seller is picked (D9).
/// ⚠️ Registered by `getIt` as a factory — a new one for every visit.
class OutboundWorkCubit extends Cubit<OutboundWorkState> {
  final OutboundWorkUseCase outboundWorkUseCase;

  /// Barcode lookup of 「입고 작업」, reused as is (R26).
  final StockIntakeUseCase stockIntakeUseCase;
  final GetSellersUseCase getSellersUseCase;
  int _nextKey = 1;

  OutboundWorkCubit({
    required this.outboundWorkUseCase,
    required this.stockIntakeUseCase,
    required this.getSellersUseCase,
  }) : super(OutboundWorkState(
          disposal: OutboundBasket(
            movedOn: toDateText(DateTime.now()),
            screenReason: StockReason.damaged,
          ),
          supplierReturn: OutboundBasket(
            movedOn: toDateText(DateTime.now()),
            screenReason: StockReason.supplierReturn,
          ),
        ));

  OutboundBasket get _basket => state.basketOf(state.tab);

  /// Replaces one tab's basket only (R12) — the current tab unless [tab].
  void _emitBasket(OutboundBasket basket, {OutboundWorkTab? tab}) {
    emit(switch (tab ?? state.tab) {
      OutboundWorkTab.disposal => state.copyWith(disposal: basket),
      OutboundWorkTab.supplierReturn =>
        state.copyWith(supplierReturn: basket),
      OutboundWorkTab.exchangeShip =>
        throw StateError('「교환 발송」 has no basket'),
    });
  }

  /// Loads the sellers; a failure leaves the list empty (no toast).
  Future<void> start() async {
    final result = await getSellersUseCase();
    final sellers = result.fold((_) => const <Seller>[], (list) => list);
    if (isClosed) {
      return;
    }
    final sole = sellers.length == 1 ? sellers.first.id : null;
    emit(state.copyWith(
      sellers: sellers,
      disposal: state.disposal.copyWith(screenSellerId: sole),
      supplierReturn: state.supplierReturn.copyWith(screenSellerId: sole),
    ));
  }

  void changeTab(OutboundWorkTab tab) {
    emit(state.copyWith(tab: tab));
  }

  /// One barcode from the input field.
  Future<void> scan(String value) async {
    if (state.tab == OutboundWorkTab.exchangeShip) {
      return;
    }
    final barcode = value.trim();
    if (barcode.isEmpty || state.busy) {
      return;
    }
    // The tab the scan was made on — the tab bar stays usable while busy.
    final tab = state.tab;
    if (state.basketOf(tab).screenSellerId == null) {
      emit(state.copyWith(
        notice: StockWorkNotice(
          StockWorkNoticeKind.input,
          '먼저 판매자를 고르세요',
        ),
      ));
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await stockIntakeUseCase.lookupBarcode(barcode);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        notice: StockWorkNotice(StockWorkNoticeKind.error, failure.message),
      )),
      (found) {
        final productId = found.productId;
        if (found.found && productId != null) {
          _add(tab, productId, found.productName ?? '');
          return;
        }
        emit(state.copyWith(
          notice: StockWorkNotice(
            StockWorkNoticeKind.error,
            '등록 안 된 바코드: $barcode',
          ),
        ));
      },
    );
    emit(state.copyWith(busy: false));
  }

  /// +1 on the matching line, else a new line at the end (R24).
  void _add(OutboundWorkTab tab, int productId, String productName) {
    final basket = state.basketOf(tab);
    final sellerId = basket.screenSellerId;
    if (sellerId == null) {
      return;
    }
    final lines = [...basket.lines];
    final index = lines.indexWhere(
      (line) =>
          line.productId == productId &&
          line.sellerId == sellerId &&
          line.reason == basket.screenReason,
    );
    if (index >= 0) {
      final line = lines[index];
      final count = (int.tryParse(line.quantityText.trim()) ?? 0) + 1;
      lines[index] = line.copyWith(quantityText: '$count');
    } else {
      lines.add(OutboundWorkLine(
        key: _nextKey++,
        productId: productId,
        productName: productName,
        quantityText: '1',
        sellerId: sellerId,
        reason: basket.screenReason,
        reasonNote: '',
        custom: false,
      ));
    }
    _emitBasket(basket.copyWith(lines: lines), tab: tab);
  }

  void changeMovedOn(String movedOn) {
    _emitBasket(_basket.copyWith(movedOn: movedOn));
  }

  /// Screen seller / reason — lines not set on their own follow (D11).
  void changeScreen({required int? sellerId, required StockReason reason}) {
    final basket = _basket;
    _emitBasket(basket.copyWith(
      screenSellerId: sellerId,
      clearScreenSellerId: sellerId == null,
      screenReason: reason,
      lines: [
        for (final line in basket.lines)
          if (line.custom)
            line
          else
            line.copyWith(
              sellerId: sellerId,
              reason: reason,
              reasonNote: reason == StockReason.etc ? null : '',
            ),
      ],
    ));
  }

  void changeLineSeller(int key, int sellerId) {
    _updateLine(
      key,
      (line) => line.copyWith(sellerId: sellerId, custom: true),
    );
  }

  void changeLineReason(int key, StockReason reason) {
    _updateLine(
      key,
      (line) => line.copyWith(
        reason: reason,
        reasonNote: reason == StockReason.etc ? null : '',
        custom: true,
      ),
    );
  }

  void changeLineNote(int key, String text) {
    _updateLine(key, (line) => line.copyWith(reasonNote: text));
  }

  void changeLineQuantity(int key, String text) {
    _updateLine(key, (line) => line.copyWith(quantityText: text));
  }

  void removeLine(int key) {
    final basket = _basket;
    _emitBasket(basket.copyWith(lines: [
      for (final line in basket.lines)
        if (line.key != key) line,
    ]));
  }

  /// [폐기 저장] · [매입처 반품 저장] — the tab's lines in one request.
  Future<void> save() async {
    if (state.tab == OutboundWorkTab.exchangeShip) {
      return;
    }
    final tab = state.tab;
    final basket = state.basketOf(tab);
    if (basket.lines.isEmpty || state.busy) {
      return;
    }
    final quantities = [
      for (final line in basket.lines) int.tryParse(line.quantityText.trim()),
    ];
    if (quantities.any((q) => q == null || q < 1)) {
      emit(state.copyWith(
        notice: StockWorkNotice(
          StockWorkNoticeKind.input,
          '수량은 1 이상 정수만 입력할 수 있습니다.',
        ),
      ));
      return;
    }
    final missing = [
      for (final line in basket.lines)
        if (line.reason == StockReason.etc && line.reasonNote.trim().isEmpty)
          line.productName,
    ];
    if (missing.isNotEmpty) {
      emit(state.copyWith(
        notice: StockWorkNotice(
          StockWorkNoticeKind.input,
          '기타 사유는 설명을 입력해야 합니다: ${missing.join(', ')}',
        ),
      ));
      return;
    }
    final disposal = tab == OutboundWorkTab.disposal;
    emit(state.copyWith(busy: true));
    final result = await outboundWorkUseCase.save(
      movedOn: basket.movedOn,
      lines: [
        for (var i = 0; i < basket.lines.length; i++)
          OutboundWorkLineRequest(
            productId: basket.lines[i].productId,
            sellerId: basket.lines[i].sellerId,
            reason: basket.lines[i].reason,
            reasonNote: basket.lines[i].reason == StockReason.etc
                ? basket.lines[i].reasonNote.trim()
                : null,
            quantity: quantities[i]!,
          ),
      ],
      fallback: disposal
          ? '폐기를 저장하지 못했습니다.'
          : '매입처 반품을 저장하지 못했습니다.',
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        notice: StockWorkNotice(StockWorkNoticeKind.error, failure.message),
      )),
      (_) {
        final cleared = state.basketOf(tab).copyWith(lines: const []);
        emit(state.copyWith(
          disposal: disposal ? cleared : null,
          supplierReturn: disposal ? null : cleared,
          notice: StockWorkNotice(
            StockWorkNoticeKind.success,
            disposal ? '폐기를 저장했습니다.' : '매입처 반품을 저장했습니다.',
          ),
        ));
      },
    );
    emit(state.copyWith(busy: false));
  }

  void _updateLine(
    int key,
    OutboundWorkLine Function(OutboundWorkLine line) change,
  ) {
    final basket = _basket;
    _emitBasket(basket.copyWith(lines: [
      for (final line in basket.lines)
        if (line.key == key) change(line) else line,
    ]));
  }
}
