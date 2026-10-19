import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

/// Sort keys of 「상품별 매출」 (web `ProductProfitSortKey`).
enum ProductProfitSortKey { netQty, grossSales, estNetProfit }

/// State of 「상품별 매출」 (FEATURE_2610_20 / D26) — the web `ProductProfitContainer`
/// state.
class ProductProfitState extends Equatable {
  final String from;
  final String to;
  final int? sellerId;
  final bool crossChannel;
  final List<Seller> sellers;
  final bool loading;

  /// 403 → 「관리자만 볼 수 있습니다.」 (D20).
  final bool forbidden;
  final String error;
  final List<ProductProfit> rows;
  final ProductProfitSortKey sortKey;
  final bool sortDescending;
  final List<OptionSaving> optionSavings;
  final int? expandedSavingsMasterId;

  const ProductProfitState({
    required this.from,
    required this.to,
    this.sellerId,
    this.crossChannel = true,
    this.sellers = const [],
    this.loading = false,
    this.forbidden = false,
    this.error = '',
    this.rows = const [],
    this.sortKey = ProductProfitSortKey.estNetProfit,
    this.sortDescending = true,
    this.optionSavings = const [],
    this.expandedSavingsMasterId,
  });

  bool get invalidRange =>
      from.isNotEmpty && to.isNotEmpty && from.compareTo(to) > 0;

  /// Every row has a cost basis — otherwise a profit sort falls back to sales.
  bool get costBasisReady =>
      rows.isNotEmpty && rows.every((r) => r.costBasisReady);

  Map<int, MasterSaving> get savingsByMaster =>
      groupSavingsByMaster(optionSavings);

  /// Rows in the chosen order; uncategorized rows always last (web
  /// `sortedRows`).
  List<ProductProfit> get sortedRows {
    final key = sortKey == ProductProfitSortKey.estNetProfit && !costBasisReady
        ? ProductProfitSortKey.grossSales
        : sortKey;
    num value(ProductProfit row) => switch (key) {
          ProductProfitSortKey.netQty => row.netQty,
          ProductProfitSortKey.grossSales => row.grossSales,
          ProductProfitSortKey.estNetProfit => row.estNetProfit ?? 0,
        };
    return [...rows]..sort((a, b) {
        if (a.uncategorized != b.uncategorized) {
          return a.uncategorized ? 1 : -1;
        }
        final diff = value(a).compareTo(value(b));
        return sortDescending ? -diff : diff;
      });
  }

  ProductProfitState copyWith({
    String? from,
    String? to,
    int? sellerId,
    bool clearSeller = false,
    bool? crossChannel,
    List<Seller>? sellers,
    bool? loading,
    bool? forbidden,
    String? error,
    List<ProductProfit>? rows,
    ProductProfitSortKey? sortKey,
    bool? sortDescending,
    List<OptionSaving>? optionSavings,
    int? expandedSavingsMasterId,
    bool clearExpanded = false,
  }) =>
      ProductProfitState(
        from: from ?? this.from,
        to: to ?? this.to,
        sellerId: clearSeller ? null : (sellerId ?? this.sellerId),
        crossChannel: crossChannel ?? this.crossChannel,
        sellers: sellers ?? this.sellers,
        loading: loading ?? this.loading,
        forbidden: forbidden ?? this.forbidden,
        error: error ?? this.error,
        rows: rows ?? this.rows,
        sortKey: sortKey ?? this.sortKey,
        sortDescending: sortDescending ?? this.sortDescending,
        optionSavings: optionSavings ?? this.optionSavings,
        expandedSavingsMasterId: clearExpanded
            ? null
            : (expandedSavingsMasterId ?? this.expandedSavingsMasterId),
      );

  @override
  List<Object?> get props => [
        from,
        to,
        sellerId,
        crossChannel,
        sellers,
        loading,
        forbidden,
        error,
        rows,
        sortKey,
        sortDescending,
        optionSavings,
        expandedSavingsMasterId,
      ];
}
