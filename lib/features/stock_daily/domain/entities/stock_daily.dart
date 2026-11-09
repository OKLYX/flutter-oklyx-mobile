import 'package:intl/intl.dart';

/// 「일별 입출고 내역」 (FEATURE_2610_19 D119 · D123 · D124 · D128 · D130 ·
/// D147). An `amount` of null is 「미기입」, never drawn as 0.
class StockDaily {
  final String date;

  /// 「영수증 미등록 N건」 (D147); 0 = the line is hidden.
  final int unregisteredProductCount;
  final List<UnregisteredProduct> unregistered;
  final List<StockDailyRow> rows;

  const StockDaily({
    required this.date,
    required this.unregisteredProductCount,
    required this.unregistered,
    required this.rows,
  });
}

/// One product of the day a receipt can still be assigned to (D121 ①).
class UnregisteredProduct {
  final int productId;
  final String productName;
  final int remainingQty;

  const UnregisteredProduct({
    required this.productId,
    required this.productName,
    required this.remainingQty,
  });
}

/// One ledger row of the day.
///
/// [sellerChangeable] = a decided incoming row without a receipt — a
/// 「판매자 바꾸기」 target (FEATURE_2611_01 D15). [recordId] = the purchase
/// record 「매입가 넣기」 retypes (FEATURE_2611_16 D1 · D17), null = not a
/// target. [shares] = every assigned share of an undecided intake row, each a
/// line of its own (D8). [amount] of an undecided intake row = its shares'
/// amounts + what is left × the undecided unit price (D8).
///
/// FEATURE_2611_17: [unitPrices] = the unit prices behind [amount] with their
/// counts (D1 · D16), null when [amount] is null · [priceFromBase] = a part of
/// [amount] has a unit price filled from the registered price, shown with
/// 「미기입」 (D22) · [openingPriceEditable] = an opening-stock row the row
/// sheet may price (D5 · D17).
///
/// FEATURE_2611_21: [sourceMovementId] · [sourceMovedOn] = the lot an outgoing
/// row came from and its day, null without a lot (D18 · D22) ·
/// [sourcePriceEditable] = that lot has a value to fix (D20) · [dateEdits] =
/// the row's day corrections, newest first (D24).
class StockDailyRow {
  final int movementId;
  final String movementType;
  final String? reason;
  final int productId;
  final String productName;
  final int quantity;
  final int? sellerId;
  final String? sellerName;
  final List<String> owners;
  final int? undecidedLeft;
  final String? orderNumber;
  final List<String> tags;
  final double? amount;
  final bool sellerChangeable;
  final int? recordId;
  final ReceiptKind? receiptKind;
  final int? receiptId;
  final List<StockDailyShare> shares;
  final List<UnitCount>? unitPrices;
  final bool priceFromBase;
  final bool openingPriceEditable;
  final int? sourceMovementId;
  final String? sourceMovedOn;
  final bool sourcePriceEditable;
  final List<StockDateEdit> dateEdits;

  const StockDailyRow({
    required this.movementId,
    required this.movementType,
    required this.reason,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    required this.owners,
    required this.undecidedLeft,
    required this.orderNumber,
    required this.tags,
    required this.amount,
    required this.sellerChangeable,
    required this.recordId,
    required this.receiptKind,
    required this.receiptId,
    required this.shares,
    required this.unitPrices,
    required this.priceFromBase,
    required this.openingPriceEditable,
    required this.sourceMovementId,
    required this.sourceMovedOn,
    required this.sourcePriceEditable,
    required this.dateEdits,
  });

  /// The row sheet target of this row, or null when the row has no sheet
  /// (FEATURE_2611_17 D12 · D24 — an undecided row has none); a row without
  /// one opens the 「날짜 바꾸기」 sheet instead (FEATURE_2611_21 D9). The same
  /// rule as the web `rowEditTarget`.
  RowEditTarget? get editTarget {
    final seller = sellerId;
    final name = sellerName;
    if (undecidedLeft != null || seller == null || name == null) {
      return null;
    }
    final price = recordId != null
        ? RowEditPrice.purchase
        : (openingPriceEditable ? RowEditPrice.opening : null);
    if (!sellerChangeable && price == null) {
      return null;
    }
    final kind = receiptKind;
    return RowEditTarget(
      movementId: movementId,
      shareRecordId: null,
      productName: productName,
      quantity: quantity,
      sellerId: seller,
      sellerName: name,
      amount: amount,
      sellerEditable: sellerChangeable,
      price: price,
      receipt: recordId != null && kind != null ? kind.editField : null,
      receiptId: receiptId,
      dateField: recordId != null && kind == ReceiptKind.receipt
          ? RowEditDate.locked
          : RowEditDate.edit,
      dateEdits: dateEdits,
    );
  }

  /// The 「매입가 넣기」 target of this decided row, or null (D1 · D17).
  PurchasePriceTarget? get priceTarget {
    final id = recordId;
    final kind = receiptKind;
    final seller = sellerId;
    final name = sellerName;
    if (id == null || kind == null || seller == null || name == null) {
      return null;
    }
    return PurchasePriceTarget(
      recordId: id,
      productName: productName,
      quantity: quantity,
      sellerId: seller,
      sellerName: name,
      amount: amount,
      receiptKind: kind,
      receiptId: receiptId,
    );
  }
}

/// Which receipt a purchase is a line of (FEATURE_2611_16 D8 · D13 · D18),
/// with the share-line word of D8.
enum ReceiptKind {
  noReceipt('NO_RECEIPT', '영수증 없음'),
  receiptLater('RECEIPT_LATER', '영수증 나중에'),
  receipt('RECEIPT', '영수증');

  final String code;
  final String label;

  const ReceiptKind(this.code, this.label);

  /// The receipt field of the row sheet for this kind (FEATURE_2611_17 D6 ·
  /// D19 · D23).
  RowEditReceipt get editField => switch (this) {
        ReceiptKind.noReceipt => RowEditReceipt.pick,
        ReceiptKind.receiptLater => RowEditReceipt.laterPhoto,
        ReceiptKind.receipt => RowEditReceipt.fixed,
      };

  /// FEATURE_2611_17 D29: 「영수증 없음」 or 「영수증 나중에」 — a purchase with
  /// no receipt photo yet.
  bool get isPending => this != ReceiptKind.receipt;

  static ReceiptKind? fromCode(String? code) {
    for (final kind in values) {
      if (kind.code == code) {
        return kind;
      }
    }
    return null;
  }
}

/// One share of an undecided intake row (FEATURE_2611_16 D8) — always a
/// 「매입가 넣기」 target; [sellerChangeable] = a 「영수증 없음」 share, a
/// 「판매자 바꾸기」 target (FEATURE_2611_01 D15).
class StockDailyShare {
  final int recordId;
  final int sellerId;
  final String sellerName;
  final int quantity;
  final double? amount;
  final ReceiptKind receiptKind;
  final int? receiptId;
  final bool sellerChangeable;

  /// The share's unit price, null = 「미기입」 (FEATURE_2611_17 D2).
  final double? unitPrice;

  /// The unit price was filled from the registered price (D22).
  final bool priceFromBase;

  const StockDailyShare({
    required this.recordId,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.amount,
    required this.receiptKind,
    required this.receiptId,
    required this.sellerChangeable,
    required this.unitPrice,
    required this.priceFromBase,
  });

  /// The share line (D8 · FEATURE_2611_17 D2 · D22), e.g.
  /// 「└ ○○ 3개 · 영수증 없음 · 12,000원 · 단가 4,000원」, then 「 · 미기입」 for
  /// a price filled from the registered price.
  String get lineText {
    final base = '└ $sellerName $quantity개 · ${receiptKind.label} · '
        '${formatShareAmount(amount)} · 단가 ${formatShareAmount(unitPrice)}';
    return priceFromBase ? '$base · $priceFromBaseLabel' : base;
  }

  /// The row sheet target of this share of [row] (FEATURE_2611_17 D10).
  RowEditTarget editTargetOf(StockDailyRow row) => RowEditTarget(
        movementId: null,
        shareRecordId: recordId,
        productName: row.productName,
        quantity: quantity,
        sellerId: sellerId,
        sellerName: sellerName,
        amount: amount,
        sellerEditable: sellerChangeable,
        price: RowEditPrice.purchase,
        receipt: receiptKind.editField,
        receiptId: receiptId,
        dateField: null,
        dateEdits: const [],
      );

  /// The 「매입가 넣기」 target of this share of [row].
  PurchasePriceTarget priceTargetOf(StockDailyRow row) => PurchasePriceTarget(
        recordId: recordId,
        productName: row.productName,
        quantity: quantity,
        sellerId: sellerId,
        sellerName: sellerName,
        amount: amount,
        receiptKind: receiptKind,
        receiptId: receiptId,
      );
}

/// A share line's amount as D8 writes it (「12,000원」), or 「미기입」 for null.
String formatShareAmount(double? amount) => amount == null
    ? '미기입'
    : '${NumberFormat('#,##0', 'ko_KR').format(amount)}원';

/// One unit price of a row and how many pieces carry it (FEATURE_2611_17 D16).
class UnitCount {
  final double unitPrice;
  final int quantity;

  const UnitCount({required this.unitPrice, required this.quantity});
}

/// The mark next to a unit price and amount filled from the registered price
/// (FEATURE_2611_17 D22).
const String priceFromBaseLabel = '미기입';

/// One day correction of a daily row (FEATURE_2611_21 D7 · D24) —
/// [editedAt] = KST wall clock as stored · [editedBy] = the login email, null
/// = written outside a request.
class StockDateEdit {
  final String editedAt;
  final String? editedBy;
  final String oldMovedOn;
  final String newMovedOn;

  const StockDateEdit({
    required this.editedAt,
    required this.editedBy,
    required this.oldMovedOn,
    required this.newMovedOn,
  });
}

/// The mark of a row whose day was corrected (FEATURE_2611_21 D24).
const String dateEditedLabel = '날짜 고침';

/// The fixed texts of the day correction (FEATURE_2611_21 D9 · D13 · D20) —
/// the server sends the same refusals. The same texts as the web.
const String receiptRowDateMessage = '영수증에 묶인 입고는 날짜를 옮길 수 없습니다.';
const String receiptShareDateMessage = '영수증에 묶인 몫이 있어 날짜를 옮길 수 없습니다.';
const String noSourceMessage = '어느 입고에서 나갔는지 기록이 없어 값을 고칠 곳이 없습니다.';
const String sourceFixedMessage = '이 입고는 값을 고칠 수 없습니다.';

/// 「11월 3일」 of a yyyy-MM-dd day (FEATURE_2611_21 D34 「○월 ○일」).
String monthDayText(String day) {
  final parts = day.split('-');
  return '${int.parse(parts[1])}월 ${int.parse(parts[2])}일';
}

/// The notice after a day was moved (FEATURE_2611_21 D9):
/// 「11월 3일로 옮겼습니다.」.
String movedMessage(String day) => '${monthDayText(day)}로 옮겼습니다.';

/// The button of an outgoing row with a lot (FEATURE_2611_21 D17 · D21):
/// 「11월 3일 입고로 이동」.
String goToIntakeLabel(String day) => '${monthDayText(day)} 입고로 이동';

/// The 「단가」 text (FEATURE_2611_17 D1 · D16): one price 「4,000원」 · several
/// 「4,000원×3 · 5,000원×2」 · null 「미기입」. The same rule as the web
/// `unitPriceText`.
String unitPriceText(List<UnitCount>? unitPrices) {
  if (unitPrices == null || unitPrices.isEmpty) {
    return '미기입';
  }
  if (unitPrices.length == 1) {
    return formatShareAmount(unitPrices.first.unitPrice);
  }
  return unitPrices
      .map((u) => '${formatShareAmount(u.unitPrice)}×${u.quantity}')
      .join(' · ');
}

/// The chip of the daily list (FEATURE_2611_17 D4), in menu order.
enum DailyChip {
  all('전체'),
  incoming('입고'),
  outgoing('출고');

  final String label;

  const DailyChip(this.label);
}

/// The two check boxes next to the chip (FEATURE_2611_17 D24 · D29).
const String undecidedBoxLabel = '판매자 미정 상품';
const String receiptPendingBoxLabel = '영수증 미등록 상품';

/// The list message when rows exist but none passes the chip and boxes
/// (FEATURE_2611_17 D28).
const String noMatchMessage = '조건에 맞는 줄이 없습니다.';

/// One row of the list with the shares shown under it (FEATURE_2611_17 D11 ·
/// D30).
class VisibleDailyRow {
  final StockDailyRow row;
  final List<StockDailyShare> shares;

  const VisibleDailyRow(this.row, this.shares);
}

/// The rows the list shows (FEATURE_2611_17 D4 · D11 · D24 · D28 · D29 · D30)
/// — the same rule as the web `visibleDailyRows`: the chip 「입고」 =
/// `STOCK_IN` · 「출고」 = `STOCK_OUT`; no box → every row with its shares;
/// 「판매자 미정 상품」 → an undecided row with a quantity left, all shares;
/// 「영수증 미등록 상품」 → a decided purchase row of 「영수증 없음」 /
/// 「영수증 나중에」 and an undecided row with such shares (those shares only);
/// both → a row in by either box.
List<VisibleDailyRow> visibleDailyRows(
  List<StockDailyRow> rows,
  DailyChip chip, {
  required bool undecidedBox,
  required bool receiptBox,
}) {
  final result = <VisibleDailyRow>[];
  for (final row in rows) {
    if (chip == DailyChip.incoming && row.movementType != 'STOCK_IN') {
      continue;
    }
    if (chip == DailyChip.outgoing && row.movementType != 'STOCK_OUT') {
      continue;
    }
    if (!undecidedBox && !receiptBox) {
      result.add(VisibleDailyRow(row, row.shares));
      continue;
    }
    if (undecidedBox && (row.undecidedLeft ?? 0) > 0) {
      result.add(VisibleDailyRow(row, row.shares));
      continue;
    }
    if (!receiptBox) {
      continue;
    }
    final shares = row.shares.where((s) => s.receiptKind.isPending).toList();
    if (shares.isNotEmpty) {
      result.add(VisibleDailyRow(row, shares));
    } else if (row.recordId != null && (row.receiptKind?.isPending ?? false)) {
      result.add(VisibleDailyRow(row, const []));
    }
  }
  return result;
}

/// The price field of the row sheet (FEATURE_2611_17 D17 · D18): a purchase
/// (total or unit price + 「상품 기준가에 반영」) or an opening-stock row (total
/// or unit price).
enum RowEditPrice { purchase, opening }

/// The receipt field of the row sheet (FEATURE_2611_17 D6 · D19 · D23): pick =
/// that day's receipt or a new photo · laterPhoto = a photo for the
/// 「영수증 나중에」 receipt · fixed = the receipt as text.
enum RowEditReceipt { pick, laterPhoto, fixed }

/// The 「날짜」 field on top of the row sheet (FEATURE_2611_21 D9): edit = a
/// row · locked = a purchase on a receipt with its photo (off, with
/// [receiptRowDateMessage]).
enum RowEditDate { edit, locked }

/// What the row sheet can change for one row or share (FEATURE_2611_17 D5 ·
/// D10 · D12 · D17 ~ D20 · D24) — the web `RowEditTarget`. [price] null = no
/// price field · [receipt] null = no receipt field (D20) · [dateField] null =
/// no 「날짜」 field, a share (FEATURE_2611_21 D13) · [dateEdits] = the row's
/// day corrections (D24).
class RowEditTarget {
  final int? movementId;
  final int? shareRecordId;
  final String productName;
  final int quantity;
  final int sellerId;
  final String sellerName;

  /// 「지금 금액」, null = 「미기입」.
  final double? amount;
  final bool sellerEditable;
  final RowEditPrice? price;
  final RowEditReceipt? receipt;
  final int? receiptId;
  final RowEditDate? dateField;
  final List<StockDateEdit> dateEdits;

  const RowEditTarget({
    required this.movementId,
    required this.shareRecordId,
    required this.productName,
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.sellerEditable,
    required this.price,
    required this.receipt,
    required this.receiptId,
    required this.dateField,
    required this.dateEdits,
  });
}

/// One receipt of the day as the receipt list sends it
/// (`GET /api/admin/purchase-receipts`, FEATURE_2610_18 D94).
class DayReceipt {
  final int id;
  final int payerSellerId;
  final String payerSellerName;
  final String? cardAlias;
  final String? firstProductName;
  final int productCount;
  final bool hasPhoto;

  const DayReceipt({
    required this.id,
    required this.payerSellerId,
    required this.payerSellerName,
    required this.cardAlias,
    required this.firstProductName,
    required this.productCount,
    required this.hasPhoto,
  });
}

/// The receipts the row sheet offers (FEATURE_2611_17 D23): that day's
/// receipts with their photo — [sellerId]'s first, then the others', each in
/// the order received.
List<DayReceipt> dayReceiptChoices(List<DayReceipt> receipts, int sellerId) {
  final withPhoto = receipts.where((r) => r.hasPhoto).toList();
  return [
    ...withPhoto.where((r) => r.payerSellerId == sellerId),
    ...withPhoto.where((r) => r.payerSellerId != sellerId),
  ];
}

/// One receipt choice (D23), e.g.
/// 「{결제 판매자} · {첫 상품} 외 N개 · {카드 별칭 | 카드 없음}」.
String receiptChoiceLabel(DayReceipt receipt) {
  final more =
      receipt.productCount > 1 ? ' 외 ${receipt.productCount - 1}개' : '';
  return '${receipt.payerSellerName} · ${receipt.firstProductName ?? '상품 없음'}'
      '$more · ${receipt.cardAlias ?? '카드 없음'}';
}

/// The notice before a receipt of another payer is picked (D23).
String sellerSwitchMessage(String fromSeller, String toSeller) =>
    '판매자가 $fromSeller → $toSeller 로 바뀝니다.';

/// The row sheet's one save (FEATURE_2611_17 D5) — the web
/// `DailyRowEditRequest`: exactly one of [movementId] / [shareRecordId];
/// null fields are not sent (the value stays). [newMovedOn] = the row's new
/// day (FEATURE_2611_21 D9), never for a share.
class DailyRowEdit {
  final int? movementId;
  final int? shareRecordId;
  final int? sellerId;
  final double? totalAmount;
  final double? unitPrice;
  final bool? reflectToBasePrice;
  final int? receiptId;
  final int? cardId;
  final String? newMovedOn;

  const DailyRowEdit({
    this.movementId,
    this.shareRecordId,
    this.sellerId,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice,
    this.receiptId,
    this.cardId,
    this.newMovedOn,
  });
}

/// One checked 「매입가 넣기」 target — a decided row's purchase record or a
/// share (FEATURE_2611_16 D7). [amount] = 「지금 금액」, null = 「미기입」.
class PurchasePriceTarget {
  final int recordId;
  final String productName;
  final int quantity;
  final int sellerId;
  final String sellerName;
  final double? amount;
  final ReceiptKind receiptKind;
  final int? receiptId;

  const PurchasePriceTarget({
    required this.recordId,
    required this.productName,
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.receiptKind,
    required this.receiptId,
  });
}

/// One checked line sent by 「매입가 넣기」 (FEATURE_2611_16 D3 · D7): both
/// amounts null = the amount stays (D7); otherwise only one of them.
class PurchasePriceLine {
  final int recordId;
  final double? totalAmount;
  final double? unitPrice;
  final bool reflectToBasePrice;

  const PurchasePriceLine({
    required this.recordId,
    this.totalAmount,
    this.unitPrice,
    this.reflectToBasePrice = true,
  });
}

/// The save refusal of D11 — a photo with two or more sellers (the server
/// sends the same text).
const String photoOneSellerMessage = '사진을 넣으면 같은 판매자 입고만 묶을 수 있습니다.';

/// What the 「영수증 사진」 field can do for the checked targets (D2 · D11 ·
/// D13 · D18) — see [purchasePricePhoto].
sealed class PurchasePricePhoto {
  const PurchasePricePhoto();
}

/// A new receipt; [sellerId] = the one seller, null for two or more (D11
/// refuses the save with a photo).
class NewReceiptPhoto extends PurchasePricePhoto {
  final int? sellerId;

  const NewReceiptPhoto(this.sellerId);
}

/// The waiting 「영수증 나중에」 receipt gets the photo (D13).
class LaterReceiptPhoto extends PurchasePricePhoto {
  final int receiptId;

  const LaterReceiptPhoto(this.receiptId);
}

/// No photo field — [message] says why (D13 · D18).
class BlockedPhoto extends PurchasePricePhoto {
  final String message;

  const BlockedPhoto(this.message);
}

/// Checked in this order: a receipt with its photo among the targets →
/// blocked (D18) · 「영수증 나중에」 lines only, one receipt → that receipt
/// (D13) · any other mix with 「영수증 나중에」 lines → blocked (D13) ·
/// otherwise a new receipt (D2 · D11). The same rule as the web
/// `purchasePricePhoto`.
PurchasePricePhoto purchasePricePhoto(List<PurchasePriceTarget> targets) {
  if (targets.any((t) => t.receiptKind == ReceiptKind.receipt)) {
    return const BlockedPhoto('사진 있는 영수증 입고가 있어 사진을 올릴 수 없습니다.');
  }
  final later =
      targets.where((t) => t.receiptKind == ReceiptKind.receiptLater).toList();
  if (later.isNotEmpty) {
    final receiptIds = later.map((t) => t.receiptId).toSet();
    final receiptId = later.first.receiptId;
    if (later.length == targets.length &&
        receiptIds.length == 1 &&
        receiptId != null) {
      return LaterReceiptPhoto(receiptId);
    }
    return const BlockedPhoto(
        '사진은 같은 영수증의 「영수증 나중에」 입고만 체크했을 때 올릴 수 있습니다.');
  }
  final sellerIds = targets.map((t) => t.sellerId).toSet();
  return NewReceiptPhoto(sellerIds.length == 1 ? targets.first.sellerId : null);
}
