import 'stock_balance.dart';

/// One line of the 「재고 조회」 amount box (FEATURE_2611_02 D26 · D34).
///
/// [key] = [allKey] for 「전체」, else `seller:{sellerId}` — `seller:0` is
/// 「판매자 미정」 (the model's sellerId for no seller). [total] adds the
/// rows' amounts; a row without one is left out and counted in
/// [unknownCount] = 「미기입 N줄」 (D24 · D25 · D36 · D37).
class StockAmountLine {
  /// The 「전체」 line.
  static const String allKey = 'ALL';

  final String key;
  final String label;
  final double total;
  final int unknownCount;

  const StockAmountLine({
    required this.key,
    required this.label,
    required this.total,
    required this.unknownCount,
  });

  /// The amount-box key of a row's seller.
  static String sellerKey(StockBalance balance) =>
      'seller:${balance.sellerId}';

  /// Whether a row belongs to the line [key] — 「전체」 takes every row.
  static bool contains(String key, StockBalance balance) =>
      key == allKey || key == sellerKey(balance);

  /// The box for the rows received (D26 · D34): 「전체」, then one line per
  /// seller in name order (code-unit order, as the server sorts the list),
  /// 「판매자 미정」 (sellerId 0) last.
  static List<StockAmountLine> of(List<StockBalance> balances) {
    StockAmountLine line(String key, String label) {
      final rows = balances.where((b) => contains(key, b)).toList();
      return StockAmountLine(
        key: key,
        label: label,
        total: rows.fold<double>(0, (sum, b) => sum + (b.amount ?? 0)),
        unknownCount: rows.where((b) => b.amount == null).length,
      );
    }

    final sellers = <String, StockBalance>{};
    for (final balance in balances) {
      sellers.putIfAbsent(sellerKey(balance), () => balance);
    }
    final ordered = sellers.values.toList()
      ..sort((a, b) {
        if (a.sellerId == 0 || b.sellerId == 0) {
          return a.sellerId == b.sellerId ? 0 : (a.sellerId == 0 ? 1 : -1);
        }
        return a.sellerName.compareTo(b.sellerName);
      });
    return [
      line(allKey, '전체'),
      for (final b in ordered) line(sellerKey(b), b.sellerName),
    ];
  }
}
