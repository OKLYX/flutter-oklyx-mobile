import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/product_barcode_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import '../../domain/entities/stock_enums.dart';
import '../../domain/entities/stock_intake.dart';
import '../../domain/usecases/stock_intake_usecase.dart';

/// Label of the 「미정」 seller choice (FEATURE_2611_33 D4 ③ · R14).
const String kUndecidedSellerLabel = '미정';

/// Label of 「기초재고」 while no seller is picked (D4 ③ · R14).
const String kOpeningNeedsSellerLabel = '기초재고 (먼저 판매자를 고르세요)';

/// Toast kinds of the 「입고 작업」 screen (R10).
enum StockIntakeNoticeKind { success, error, input }

/// One toast. A new object every time so the same text shows again.
class StockIntakeNotice {
  final StockIntakeNoticeKind kind;
  final String message;

  /// Lots made by the save — handed to the fill flow (D4 ⑨).
  final List<int> lotIds;

  StockIntakeNotice(this.kind, this.message, {this.lotIds = const []});
}

/// One collected line (D4 ④ · ⑤ · ⑥).
class IntakeLine {
  /// Screen-local key, stable while the line lives.
  final int key;
  final int productId;
  final String productName;
  final String quantityText;

  /// Null = 「미정」.
  final int? sellerId;
  final StockReason reason;

  /// Seller or reason was set on this line (「따로 정함」).
  final bool custom;

  const IntakeLine({
    required this.key,
    required this.productId,
    required this.productName,
    required this.quantityText,
    required this.reason,
    required this.custom,
    this.sellerId,
  });

  IntakeLine copyWith({
    String? quantityText,
    int? sellerId,
    bool clearSellerId = false,
    StockReason? reason,
    bool? custom,
  }) =>
      IntakeLine(
        key: key,
        productId: productId,
        productName: productName,
        quantityText: quantityText ?? this.quantityText,
        sellerId: clearSellerId ? null : (sellerId ?? this.sellerId),
        reason: reason ?? this.reason,
        custom: custom ?? this.custom,
      );
}

/// Tabs of 「입고 작업」 (FEATURE_2611_34 D2).
enum IntakeTab { intake, returnIntake }

/// State of the 「입고 작업」 screen (FEATURE_2611_33 D4 · D5).
class StockIntakeState {
  final IntakeTab tab;
  final List<Seller> sellers;
  final String movedOn;
  final int? screenSellerId;
  final StockReason screenReason;
  final List<IntakeLine> lines;

  /// The barcode no product holds — shows the 「등록 안 된 바코드」 box.
  final String? unknownBarcode;

  /// Product picked in that box.
  final Product? picked;
  final bool busy;

  /// Grows on every unknown barcode, the same value too (R16).
  final int unknownScan;
  final StockIntakeNotice? notice;

  const StockIntakeState({
    required this.movedOn,
    this.tab = IntakeTab.intake,
    this.sellers = const [],
    this.screenSellerId,
    this.screenReason = StockReason.purchase,
    this.lines = const [],
    this.unknownBarcode,
    this.picked,
    this.busy = false,
    this.unknownScan = 0,
    this.notice,
  });

  /// The only seller of a one-seller account (D4 ②).
  Seller? get soleSeller => sellers.length == 1 ? sellers.first : null;

  /// Seller sent for [line] — the only seller wins (D4 ⑧).
  int? lineSellerOf(IntakeLine line) => soleSeller?.id ?? line.sellerId;

  StockIntakeState copyWith({
    IntakeTab? tab,
    List<Seller>? sellers,
    String? movedOn,
    int? screenSellerId,
    bool clearScreenSellerId = false,
    StockReason? screenReason,
    List<IntakeLine>? lines,
    String? unknownBarcode,
    bool clearUnknownBarcode = false,
    Product? picked,
    bool clearPicked = false,
    bool? busy,
    int? unknownScan,
    StockIntakeNotice? notice,
  }) =>
      StockIntakeState(
        tab: tab ?? this.tab,
        sellers: sellers ?? this.sellers,
        movedOn: movedOn ?? this.movedOn,
        screenSellerId: clearScreenSellerId
            ? null
            : (screenSellerId ?? this.screenSellerId),
        screenReason: screenReason ?? this.screenReason,
        lines: lines ?? this.lines,
        unknownBarcode: clearUnknownBarcode
            ? null
            : (unknownBarcode ?? this.unknownBarcode),
        picked: clearPicked ? null : (picked ?? this.picked),
        busy: busy ?? this.busy,
        unknownScan: unknownScan ?? this.unknownScan,
        notice: notice ?? this.notice,
      );
}

/// Cubit of the 「입고 작업」 screen (FEATURE_2611_33 D4 · D5 · D7).
///
/// **Purpose**: collects scanned products into lines and saves them at once.
/// **File**: stock_ledger/presentation/bloc/stock_intake_cubit.dart
///
/// - A scan adds 1 to the first line with the same product, screen seller and
///   screen reason, else appends a new line (D4 ④).
/// - Screen seller / reason follow into every line not set on its own (D4 ⑤).
/// - Every check and failure is a toast (D9).
/// ⚠️ Registered by `getIt` as a factory — a new one for every visit.
class StockIntakeCubit extends Cubit<StockIntakeState> {
  final StockIntakeUseCase stockIntakeUseCase;
  final ProductBarcodeUseCase productBarcodeUseCase;
  final GetSellersUseCase getSellersUseCase;
  int _nextKey = 1;

  StockIntakeCubit({
    required this.stockIntakeUseCase,
    required this.productBarcodeUseCase,
    required this.getSellersUseCase,
  }) : super(StockIntakeState(movedOn: toDateText(DateTime.now())));

  /// Loads the sellers; a failure leaves the list empty (no toast).
  Future<void> start() async {
    final result = await getSellersUseCase();
    final sellers = result.fold((_) => const <Seller>[], (list) => list);
    if (isClosed) {
      return;
    }
    emit(state.copyWith(
      sellers: sellers,
      screenSellerId: sellers.length == 1 ? sellers.first.id : null,
    ));
  }

  /// One barcode from the input field.
  Future<void> lookup(String value) async {
    final barcode = value.trim();
    if (barcode.isEmpty || state.busy) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await stockIntakeUseCase.lookupBarcode(barcode);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        notice: StockIntakeNotice(
          StockIntakeNoticeKind.error,
          failure.message,
        ),
      )),
      (found) {
        final productId = found.productId;
        if (found.found && productId != null) {
          _addProduct(productId, found.productName ?? '');
          emit(state.copyWith(clearUnknownBarcode: true));
          return;
        }
        emit(state.copyWith(
          unknownBarcode: barcode,
          clearPicked: true,
          unknownScan: state.unknownScan + 1,
        ));
      },
    );
    emit(state.copyWith(busy: false));
  }

  /// +1 on the matching line, else a new line at the end (D4 ④).
  void _addProduct(int productId, String productName) {
    final lines = [...state.lines];
    final index = lines.indexWhere(
      (line) =>
          line.productId == productId &&
          line.sellerId == state.screenSellerId &&
          line.reason == state.screenReason,
    );
    if (index >= 0) {
      final line = lines[index];
      final count = (int.tryParse(line.quantityText.trim()) ?? 0) + 1;
      lines[index] = line.copyWith(quantityText: '$count');
    } else {
      lines.add(IntakeLine(
        key: _nextKey++,
        productId: productId,
        productName: productName,
        quantityText: '1',
        sellerId: state.screenSellerId,
        reason: state.screenReason,
        custom: false,
      ));
    }
    emit(state.copyWith(lines: lines));
  }

  void changeMovedOn(String movedOn) {
    emit(state.copyWith(movedOn: movedOn));
  }

  /// 「입고」 · 「반품 재입고」 — the other tab keeps its lines (D2).
  void changeTab(IntakeTab tab) {
    emit(state.copyWith(tab: tab));
  }

  /// Screen seller / reason — lines not set on their own follow (D4 ⑤).
  void changeScreen({required int? sellerId, required StockReason reason}) {
    emit(state.copyWith(
      screenSellerId: sellerId,
      clearScreenSellerId: sellerId == null,
      screenReason: reason,
      lines: [
        for (final line in state.lines)
          if (line.custom)
            line
          else
            line.copyWith(
              sellerId: sellerId,
              clearSellerId: sellerId == null,
              reason: reason,
            ),
      ],
    ));
  }

  void changeLineSeller(int key, int? sellerId) {
    _updateLine(
      key,
      (line) => line.copyWith(
        sellerId: sellerId,
        clearSellerId: sellerId == null,
        custom: true,
      ),
    );
  }

  void changeLineReason(int key, StockReason reason) {
    _updateLine(key, (line) => line.copyWith(reason: reason, custom: true));
  }

  void changeLineQuantity(int key, String text) {
    _updateLine(key, (line) => line.copyWith(quantityText: text));
  }

  void removeLine(int key) {
    emit(state.copyWith(lines: [
      for (final line in state.lines)
        if (line.key != key) line,
    ]));
  }

  void pickProduct(Product product) {
    emit(state.copyWith(picked: product));
  }

  /// [이 상품에 바코드 저장] — true when saved and added as a line.
  Future<bool> saveBarcodeOnPicked({
    required String productName,
    required String priceText,
  }) async {
    final picked = state.picked;
    final barcode = state.unknownBarcode;
    if (picked == null || barcode == null) {
      return false;
    }
    final name = productName.trim();
    emit(state.copyWith(busy: true));
    final result = await productBarcodeUseCase.saveBarcode(
      productId: picked.id,
      barcodeId: barcode,
      productName: name.isEmpty ? null : name,
      price: int.tryParse(priceText.trim()),
    );
    return _afterBarcodeSave(result);
  }

  /// [새 상품으로 등록] — true when created and added as a line.
  Future<bool> createWithBarcode({
    required String productName,
    required String priceText,
  }) async {
    final barcode = state.unknownBarcode;
    if (barcode == null) {
      return false;
    }
    final name = productName.trim();
    if (name.isEmpty) {
      emit(state.copyWith(
        notice: StockIntakeNotice(
          StockIntakeNoticeKind.input,
          '상품 이름을 입력하세요.',
        ),
      ));
      return false;
    }
    emit(state.copyWith(busy: true));
    final result = await productBarcodeUseCase.create(
      productName: name,
      barcodeId: barcode,
      price: int.tryParse(priceText.trim()),
    );
    return _afterBarcodeSave(result);
  }

  /// [입고 저장] — every line in one request (D4 ⑧ · ⑨).
  Future<void> save() async {
    if (state.lines.isEmpty || state.busy) {
      return;
    }
    final quantities = [
      for (final line in state.lines) int.tryParse(line.quantityText.trim()),
    ];
    if (quantities.any((q) => q == null || q < 1)) {
      emit(state.copyWith(
        notice: StockIntakeNotice(
          StockIntakeNoticeKind.input,
          '수량은 1 이상 정수만 입력할 수 있습니다.',
        ),
      ));
      return;
    }
    final missing = [
      for (final line in state.lines)
        if (line.reason == StockReason.opening &&
            state.lineSellerOf(line) == null)
          line.productName,
    ];
    if (missing.isNotEmpty) {
      emit(state.copyWith(
        notice: StockIntakeNotice(
          StockIntakeNoticeKind.input,
          '기초재고는 판매자를 골라야 합니다: ${missing.join(', ')}',
        ),
      ));
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await stockIntakeUseCase.save(
      movedOn: state.movedOn,
      lines: [
        for (var i = 0; i < state.lines.length; i++)
          StockIntakeLine(
            productId: state.lines[i].productId,
            quantity: quantities[i]!,
            sellerId: state.lineSellerOf(state.lines[i]),
            reason: state.lines[i].reason,
          ),
      ],
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(
        notice: StockIntakeNotice(
          StockIntakeNoticeKind.error,
          failure.message,
        ),
      )),
      (lotIds) => emit(state.copyWith(
        lines: const [],
        notice: StockIntakeNotice(
          StockIntakeNoticeKind.success,
          '입고를 저장했습니다.',
          lotIds: lotIds,
        ),
      )),
    );
    emit(state.copyWith(busy: false));
  }

  /// Saved product = a line and the box closes; failure = a toast.
  bool _afterBarcodeSave(Either<Failure, Product> result) {
    if (isClosed) {
      return false;
    }
    final ok = result.fold(
      (failure) {
        emit(state.copyWith(
          notice: StockIntakeNotice(
            StockIntakeNoticeKind.error,
            failure.message,
          ),
        ));
        return false;
      },
      (saved) {
        _addProduct(saved.id, saved.productName);
        emit(state.copyWith(clearUnknownBarcode: true, clearPicked: true));
        return true;
      },
    );
    emit(state.copyWith(busy: false));
    return ok;
  }

  void _updateLine(int key, IntakeLine Function(IntakeLine line) change) {
    emit(state.copyWith(lines: [
      for (final line in state.lines)
        if (line.key == key) change(line) else line,
    ]));
  }
}
