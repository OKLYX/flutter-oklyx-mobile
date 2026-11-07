import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/seller_card.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/get_seller_cards_usecase.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/usecases/retype_purchase_price_usecase.dart';

/// The 「카드로 알 수 없음」 value of the 「결제 카드」 field (FEATURE_2611_16
/// D12) — sent as no card.
const String kUnknownPurchasePriceCard = 'UNKNOWN';

/// State of the 「매입가 넣기」 sheet (FEATURE_2611_16 D2 · D3 · D7 · D12).
class PurchasePriceState {
  /// Visible cards of every seller — the sheet lists the target seller's.
  final List<SellerCard> cards;

  /// The receipt photo, null = amounts only (D2).
  final File? photo;

  /// A card id as text · [kUnknownPurchasePriceCard] · null = 「선택」.
  final String? cardChoice;

  /// 「단가」 picked per `recordId` (false = 「총액」).
  final Map<int, bool> unitMode;

  /// 「상품 기준가에 반영」 per `recordId` (D3, on at the start).
  final Map<int, bool> reflect;

  /// The save request is running.
  final bool busy;

  /// Error text inside the sheet, blank when none.
  final String error;

  /// The prices were applied — the sheet closes.
  final bool saved;

  const PurchasePriceState({
    this.cards = const [],
    this.photo,
    this.cardChoice,
    this.unitMode = const {},
    this.reflect = const {},
    this.busy = false,
    this.error = '',
    this.saved = false,
  });

  PurchasePriceState copyWith({
    List<SellerCard>? cards,
    File? photo,
    String? cardChoice,
    bool clearCardChoice = false,
    Map<int, bool>? unitMode,
    Map<int, bool>? reflect,
    bool? busy,
    String? error,
    bool? saved,
  }) =>
      PurchasePriceState(
        cards: cards ?? this.cards,
        photo: photo ?? this.photo,
        cardChoice: clearCardChoice ? null : (cardChoice ?? this.cardChoice),
        unitMode: unitMode ?? this.unitMode,
        reflect: reflect ?? this.reflect,
        busy: busy ?? this.busy,
        error: error ?? this.error,
        saved: saved ?? this.saved,
      );
}

/// Cubit of the 「매입가 넣기」 sheet (FEATURE_2611_16 D2 · D3 · D7 · D11 ·
/// D12).
///
/// **Purpose**: the photo, the card, 「총액」/「단가」, 「상품 기준가에 반영」,
/// the save checks and the save of the sheet opened from 「일별 입출고 내역」.
/// **File**: lib/features/stock_daily/presentation/bloc/purchase_price_cubit.dart
///
/// - Save checks stop at the first refusal (same texts as the web).
/// - A refused or failed save keeps the sheet open with the text inside.
/// ⚠️ GetIt factory — 시트마다 새 것 (a new one for every sheet).
class PurchasePriceCubit extends Cubit<PurchasePriceState> {
  final GetSellerCardsUseCase getSellerCardsUseCase;
  final RetypePurchasePriceUseCase retypePurchasePriceUseCase;

  PurchasePriceCubit({
    required this.getSellerCardsUseCase,
    required this.retypePurchasePriceUseCase,
  }) : super(const PurchasePriceState());

  /// Starts every line at 「총액」 with 「상품 기준가에 반영」 on and loads the
  /// cards (a failure = no cards).
  Future<void> open(List<PurchasePriceTarget> targets) async {
    emit(state.copyWith(
      unitMode: {for (final t in targets) t.recordId: false},
      reflect: {for (final t in targets) t.recordId: true},
    ));
    final result = await getSellerCardsUseCase();
    final cards = result.fold((_) => const <SellerCard>[], (list) => list);
    if (isClosed) {
      return;
    }
    emit(state.copyWith(cards: cards));
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

  /// 「총액」 (false) / 「단가」 (true) of one line.
  void setUnitMode(int recordId, {required bool unit}) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(unitMode: {...state.unitMode, recordId: unit}));
  }

  /// 「상품 기준가에 반영」 of one line.
  void setReflect(int recordId, {required bool value}) {
    if (state.busy) {
      return;
    }
    emit(state.copyWith(reflect: {...state.reflect, recordId: value}));
  }

  /// [저장] — [amounts] = the amount field text per `recordId`.
  Future<void> save({
    required String date,
    required List<PurchasePriceTarget> targets,
    required Map<int, String> amounts,
  }) async {
    if (state.busy) {
      return;
    }
    final values = <int, double?>{};
    for (final target in targets) {
      final text = (amounts[target.recordId] ?? '').trim();
      if (text.isEmpty) {
        values[target.recordId] = null;
        continue;
      }
      final value = double.tryParse(text);
      if (value == null || !value.isFinite || value < 0) {
        emit(state.copyWith(error: '금액은 0 이상 숫자만 입력할 수 있습니다.'));
        return;
      }
      values[target.recordId] = value;
    }
    final photo = state.photo;
    if (photo == null && values.values.every((value) => value == null)) {
      emit(state.copyWith(error: '바꿀 금액을 넣거나 영수증 사진을 올리세요.'));
      return;
    }
    final kind = purchasePricePhoto(targets);
    int? cardId;
    if (photo != null && kind is NewReceiptPhoto) {
      if (kind.sellerId == null) {
        emit(state.copyWith(error: photoOneSellerMessage));
        return;
      }
      final choice = state.cardChoice;
      if (choice == null) {
        emit(state.copyWith(error: '결제 카드를 고르세요.'));
        return;
      }
      cardId = choice == kUnknownPurchasePriceCard ? null : int.parse(choice);
    }
    final lines = [
      for (final target in targets)
        PurchasePriceLine(
          recordId: target.recordId,
          totalAmount: (state.unitMode[target.recordId] ?? false)
              ? null
              : values[target.recordId],
          unitPrice: (state.unitMode[target.recordId] ?? false)
              ? values[target.recordId]
              : null,
          reflectToBasePrice: state.reflect[target.recordId] ?? true,
        ),
    ];
    emit(state.copyWith(busy: true, error: ''));
    final result = await retypePurchasePriceUseCase(date, photo, cardId, lines);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, saved: true)),
    );
  }
}
