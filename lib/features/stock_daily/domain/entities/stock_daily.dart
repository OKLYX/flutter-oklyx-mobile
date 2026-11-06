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
  });

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

  const StockDailyShare({
    required this.recordId,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.amount,
    required this.receiptKind,
    required this.receiptId,
    required this.sellerChangeable,
  });

  /// The share line (D8): 「└ ○○ 3개 · 영수증 없음 · 12,000원」.
  String get lineText => '└ $sellerName $quantity개 · ${receiptKind.label} · '
      '${formatShareAmount(amount)}';

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
