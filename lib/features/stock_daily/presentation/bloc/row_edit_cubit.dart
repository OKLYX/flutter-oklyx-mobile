import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/seller_card.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/get_seller_cards_usecase.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/usecases/edit_daily_row_usecase.dart';
import '../../domain/usecases/get_day_receipts_usecase.dart';
import 'purchase_price_cubit.dart';

/// The 「영수증 없음」 choice of the 「영수증」 field (FEATURE_2611_17 D6).
const String kNoRowEditReceipt = 'NONE';

/// The 「새 영수증 사진 올리기」 choice of the 「영수증」 field (D6).
const String kNewRowEditReceipt = 'NEW';

/// State of the 「입고 정보 수정」 sheet (FEATURE_2611_17 D5 · D6 · D18 · D21 ·
/// D23).
class RowEditState {
  /// Visible cards of every seller — the sheet lists the current seller's.
  final List<SellerCard> cards;

  /// That day's receipts (D23), empty when the load failed.
  final List<DayReceipt> receipts;

  /// The seller picked in the sheet, null until the sheet is opened.
  final int? sellerId;

  /// 「단가」 picked (false = 「총액」).
  final bool unitMode;

  /// 「상품 기준가에 반영」 (D18, on at the start).
  final bool reflect;

  /// [kNoRowEditReceipt] · [kNewRowEditReceipt] · a receipt id as text.
  final String receiptChoice;

  /// The receipt photo, null = none picked.
  final File? photo;

  /// A card id as text · [kUnknownPurchasePriceCard] · null = 「선택」.
  final String? cardChoice;

  /// The save request is running.
  final bool busy;

  /// Error text inside the sheet, blank when none.
  final String error;

  /// The row was saved — the sheet closes.
  final bool saved;

  const RowEditState({
    this.cards = const [],
    this.receipts = const [],
    this.sellerId,
    this.unitMode = false,
    this.reflect = true,
    this.receiptChoice = kNoRowEditReceipt,
    this.photo,
    this.cardChoice,
    this.busy = false,
    this.error = '',
    this.saved = false,
  });

  /// The day receipt picked in the 「영수증」 field, or null.
  DayReceipt? get pickedReceipt {
    final id = int.tryParse(receiptChoice);
    if (id == null) {
      return null;
    }
    for (final receipt in receipts) {
      if (receipt.id == id) {
        return receipt;
      }
    }
    return null;
  }

  RowEditState copyWith({
    List<SellerCard>? cards,
    List<DayReceipt>? receipts,
    int? sellerId,
    bool? unitMode,
    bool? reflect,
    String? receiptChoice,
    File? photo,
    String? cardChoice,
    bool clearCardChoice = false,
    bool? busy,
    String? error,
    bool? saved,
  }) =>
      RowEditState(
        cards: cards ?? this.cards,
        receipts: receipts ?? this.receipts,
        sellerId: sellerId ?? this.sellerId,
        unitMode: unitMode ?? this.unitMode,
        reflect: reflect ?? this.reflect,
        receiptChoice: receiptChoice ?? this.receiptChoice,
        photo: photo ?? this.photo,
        cardChoice: clearCardChoice ? null : (cardChoice ?? this.cardChoice),
        busy: busy ?? this.busy,
        error: error ?? this.error,
        saved: saved ?? this.saved,
      );
}

/// Cubit of the 「입고 정보 수정」 sheet (FEATURE_2611_17 D5 · D6 · D18 · D21 ·
/// D23).
///
/// **Purpose**: the seller, 「총액」/「단가」, 「상품 기준가에 반영」, the receipt
/// choice, the photo, the card, the save checks and the one save of the row
/// sheet opened from 「일별 입출고 내역」.
/// **File**: lib/features/stock_daily/presentation/bloc/row_edit_cubit.dart
///
/// - Save checks stop at the first refusal (same texts and order as the web).
/// - A refused or failed save keeps the sheet open with the text inside.
/// ⚠️ GetIt factory — 시트마다 새 것 (a new one for every sheet).
class RowEditCubit extends Cubit<RowEditState> {
  final GetSellerCardsUseCase getSellerCardsUseCase;
  final GetDayReceiptsUseCase getDayReceiptsUseCase;
  final EditDailyRowUseCase editDailyRowUseCase;

  RowEditCubit({
    required this.getSellerCardsUseCase,
    required this.getDayReceiptsUseCase,
    required this.editDailyRowUseCase,
  }) : super(const RowEditState());

  /// Starts at the target seller and loads the cards and that day's receipts
  /// (a failure = an empty list).
  Future<void> open(RowEditTarget target, String date) async {
    emit(state.copyWith(sellerId: target.sellerId));
    final cardResult = await getSellerCardsUseCase();
    final cards = cardResult.fold((_) => const <SellerCard>[], (list) => list);
    final receiptResult = await getDayReceiptsUseCase(date);
    final receipts =
        receiptResult.fold((_) => const <DayReceipt>[], (list) => list);
    if (isClosed) {
      return;
    }
    emit(state.copyWith(cards: cards, receipts: receipts));
  }

  /// 「판매자」 was picked — the card choice clears and a picked receipt of
  /// another payer goes back to 「영수증 없음」 (D21).
  void setSeller(int sellerId) {
    if (state.busy) {
      return;
    }
    final picked = state.pickedReceipt;
    final keep = picked == null || picked.payerSellerId == sellerId;
    emit(state.copyWith(
      sellerId: sellerId,
      clearCardChoice: true,
      receiptChoice: keep ? null : kNoRowEditReceipt,
    ));
  }

  /// 「영수증」 was picked — a receipt of another payer also switches the
  /// seller to that payer and clears the card (D23; the sheet confirms
  /// first).
  void pickReceipt(String choice) {
    if (state.busy) {
      return;
    }
    final next = state.copyWith(receiptChoice: choice, error: '');
    final picked = next.pickedReceipt;
    if (picked != null && picked.payerSellerId != state.sellerId) {
      emit(
          next.copyWith(sellerId: picked.payerSellerId, clearCardChoice: true));
      return;
    }
    emit(next);
  }

  /// A photo was taken or picked.
  void setPhoto(File photo) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(photo: photo, error: ''));
  }

  /// 「결제 카드」 was picked.
  void pickCard(String? choice) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(cardChoice: choice, clearCardChoice: choice == null));
  }

  /// 「총액」 (false) / 「단가」 (true).
  void setUnitMode({required bool unit}) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(unitMode: unit));
  }

  /// 「상품 기준가에 반영」.
  void setReflect({required bool value}) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(reflect: value));
  }

  /// [저장] — [amount] = the amount field text (blank = the price stays).
  Future<void> save({
    required String date,
    required RowEditTarget target,
    required String amount,
  }) async {
    if (state.busy) {
      return;
    }
    final text = amount.trim();
    double? value;
    if (text.isNotEmpty) {
      value = double.tryParse(text);
      if (value == null || !value.isFinite || value < 0) {
        emit(state.copyWith(error: '금액은 0 이상 숫자만 입력할 수 있습니다.'));
        return;
      }
    }
    final newReceipt = target.receipt == RowEditReceipt.pick &&
        state.receiptChoice == kNewRowEditReceipt;
    final photo = newReceipt || target.receipt == RowEditReceipt.laterPhoto
        ? state.photo
        : null;
    if (newReceipt && photo == null) {
      emit(state.copyWith(error: '영수증 사진을 고르세요.'));
      return;
    }
    int? cardId;
    if (newReceipt) {
      final choice = state.cardChoice;
      if (choice == null) {
        emit(state.copyWith(error: '결제 카드를 고르세요.'));
        return;
      }
      cardId = choice == kUnknownPurchasePriceCard ? null : int.parse(choice);
    }
    final receiptId =
        target.receipt == RowEditReceipt.pick ? state.pickedReceipt?.id : null;
    final sellerId = state.sellerId;
    final sellerChanged = target.sellerEditable &&
        sellerId != null &&
        sellerId != target.sellerId;
    if (!sellerChanged && value == null && photo == null && receiptId == null) {
      emit(state.copyWith(error: '바꿀 내용이 없습니다.'));
      return;
    }
    final movementId = target.movementId;
    final edit = DailyRowEdit(
      movementId: movementId,
      shareRecordId: movementId == null ? target.shareRecordId : null,
      sellerId: sellerChanged ? sellerId : null,
      totalAmount: state.unitMode ? null : value,
      unitPrice: state.unitMode ? value : null,
      reflectToBasePrice:
          target.price == RowEditPrice.purchase ? state.reflect : null,
      receiptId: receiptId,
      cardId: cardId,
    );
    emit(state.copyWith(busy: true, error: ''));
    final result = await editDailyRowUseCase(date, photo, edit);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, saved: true)),
    );
  }
}
