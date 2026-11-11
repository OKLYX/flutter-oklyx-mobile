import 'stock_daily.dart';

/// One row of the 「채울까요?」 sheet (FEATURE_2611_22 D19 · D23) — an order
/// outbound row without a lot. [checkedQuantity] 0 = not checked at first.
class FillRow {
  final int movementId;
  final String orderNumber;
  final String movedOn;
  final String sellerName;
  final int emptyQuantity;
  final int checkedQuantity;

  const FillRow({
    required this.movementId,
    required this.orderNumber,
    required this.movedOn,
    required this.sellerName,
    required this.emptyQuantity,
    required this.checkedQuantity,
  });
}

/// One saved lot of a sheet with every row in D17 order (D32).
/// [sellerName] null = 「영수증 미등록」.
class FillCandidateLot {
  final int lotId;
  final String movedOn;
  final String? sellerName;
  final int quantity;
  final List<FillRow> rows;

  const FillCandidateLot({
    required this.lotId,
    required this.movedOn,
    required this.sellerName,
    required this.quantity,
    required this.rows,
  });
}

/// One product's 「채울까요?」 sheet (D30 · D31): N = [rowCount],
/// M = [emptyQuantity].
class FillCandidate {
  final int productId;
  final String productName;
  final int rowCount;
  final int emptyQuantity;
  final List<FillCandidateLot> lots;

  const FillCandidate({
    required this.productId,
    required this.productName,
    required this.rowCount,
    required this.emptyQuantity,
    required this.lots,
  });
}

/// One lot [입고로 채우기] offers (D15). [sellerName] null = 「영수증 미등록」.
class FillLot {
  final int lotId;
  final String movedOn;
  final String? sellerName;
  final int quantity;

  const FillLot({
    required this.lotId,
    required this.movedOn,
    required this.sellerName,
    required this.quantity,
  });
}

/// One lot of a [채우기] request and the rows it fills (D3 · D23 · D32), in
/// the order they are applied.
class FillRequestLot {
  final int lotId;
  final List<FillRequestLine> lines;

  const FillRequestLot({required this.lotId, required this.lines});
}

/// One row of [FillRequestLot] and its pieces (1 or more).
class FillRequestLine {
  final int movementId;
  final int quantity;

  const FillRequestLine({required this.movementId, required this.quantity});
}

/// The fixed texts of filling a row later (FEATURE_2611_22 D27) — the same
/// texts as the web; the server sends the same refusals.
const String fillButtonLabel = '입고로 채우기';
const String noFillLotMessage = '채울 수 있는 입고가 없습니다.';

/// The mark of a row that got its lot later (D9 · D27):
/// 「11월 7일 입고로 나중에 채움」.
String filledLaterLabel(String day) => '${monthDayText(day)} 입고로 나중에 채움';

/// The head of the 「채울까요?」 sheet (D27 · D30):
/// 「입고 기록 없이 나간 출고 2건(5개)이 있습니다. 이 입고로 채울까요?」.
String fillWindowHead(int rowCount, int emptyQuantity) =>
    '입고 기록 없이 나간 출고 $rowCount건($emptyQuantity개)이 있습니다. 이 입고로 채울까요?';

/// A lot's label in both sheets (D15 · D19): 「11월 7일 입고 · A상사 · 4개」, an
/// undecided lot 「… · 영수증 미등록 · …」. The same text as the web.
String fillLotLabel(String movedOn, String? sellerName, int quantity) =>
    '${monthDayText(movedOn)} 입고 · ${sellerName ?? '영수증 미등록'} · $quantity개';
