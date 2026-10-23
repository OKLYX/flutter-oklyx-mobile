/// 「매출」 entities (FEATURE_2610_20 / D18 · D26) — the mobile twin of the web
/// `SalesSummary.ts` and `PackingSavingsEntity.ts`. Field names = the server
/// JSON names.
///
/// 🔴 Two axes are mixed: `grossSales` · `discount` · `estFee` · `estNetProfit`
/// are sale-date sums of the period; `pendingPayout` is the recognition-date
/// total regardless of the period — every screen labels it 「기간 무관 · 미지급 잔액」.
/// 🔴 `estNetProfit == null` (`costBasisReady == false`) means "not known yet"
/// — never draw it as 0.
library;

/// One seller row — `GET /api/admin/sales/summary`.
class SellerSales {
  final int sellerId;
  final String sellerName;
  final num grossSales;
  final num discount;
  final num netQty;
  final num holdQty;
  final num estFee;
  final num? estNetProfit;
  final bool costBasisReady;
  final num pendingPayout;

  /// Monthly fixed cost of the seller's channels in the period — already taken
  /// out of [estNetProfit].
  final num fixedCost;

  const SellerSales({
    required this.sellerId,
    required this.sellerName,
    required this.grossSales,
    required this.discount,
    required this.netQty,
    required this.holdQty,
    required this.estFee,
    required this.estNetProfit,
    required this.costBasisReady,
    required this.pendingPayout,
    required this.fixedCost,
  });
}

/// One channel (account) row — `GET /api/admin/sales/by-channel`.
class ChannelSales {
  final int accountId;
  final String? accountAlias;
  final String? platform;
  final int? sellerId;
  final String? sellerName;
  final num grossSales;
  final num discount;
  final num netQty;
  final num holdQty;
  final num estFee;
  final num? estNetProfit;
  final bool costBasisReady;
  final num cancelQty;
  final num refundedAmount;
  final num pendingRefundAmount;
  final num pendingPayout;

  /// Cash basis (paid in the period) — channel only.
  final num paidAmount;
  final String? lastSettlementSyncAt;
  final num fixedCost;

  /// Months in the period the fixed cost was charged; 0 = below the threshold
  /// or no setting.
  final int fixedCostMonths;

  const ChannelSales({
    required this.accountId,
    required this.accountAlias,
    required this.platform,
    required this.sellerId,
    required this.sellerName,
    required this.grossSales,
    required this.discount,
    required this.netQty,
    required this.holdQty,
    required this.estFee,
    required this.estNetProfit,
    required this.costBasisReady,
    required this.cancelQty,
    required this.refundedAmount,
    required this.pendingRefundAmount,
    required this.pendingPayout,
    required this.paidAmount,
    required this.lastSettlementSyncAt,
    required this.fixedCost,
    required this.fixedCostMonths,
  });
}

/// One order line of a channel — `GET /api/admin/sales/lines`. Amounts are the
/// server's.
class SalesLine {
  final int orderLineId;
  final int accountId;
  final String? orderedAt;
  final String externalOrderId;
  final String? itemName;

  /// null = the order is not linked to a channel option (kept — hiding it
  /// breaks the totals).
  final String? masterProductName;
  final num orderQty;
  final num cancelQty;
  final num holdQty;
  final num netQty;
  final num unitPrice;
  final num grossSales;
  final num discount;

  const SalesLine({
    required this.orderLineId,
    required this.accountId,
    required this.orderedAt,
    required this.externalOrderId,
    required this.itemName,
    required this.masterProductName,
    required this.orderQty,
    required this.cancelQty,
    required this.holdQty,
    required this.netQty,
    required this.unitPrice,
    required this.grossSales,
    required this.discount,
  });
}

/// One product row — `GET /api/admin/sales/by-product`.
class ProductProfit {
  final int? masterProductId;
  final String masterProductName;
  final int? accountId;
  final String? accountAlias;
  final num netQty;
  final num grossSales;
  final num discount;
  final num estFee;
  final num? estNetProfit;
  final bool costBasisReady;

  /// Orders not linked to a channel option — shown, never hidden.
  final bool uncategorized;

  const ProductProfit({
    required this.masterProductId,
    required this.masterProductName,
    required this.accountId,
    required this.accountAlias,
    required this.netQty,
    required this.grossSales,
    required this.discount,
    required this.estFee,
    required this.estNetProfit,
    required this.costBasisReady,
    required this.uncategorized,
  });
}

/// Packing savings of the period — `GET /api/admin/packing/savings/summary`
/// (packing-date axis).
class SavingsSummary {
  final int parcelCount;
  final num boxSaving;
  final num deliverySaving;
  final num totalSaving;
  final int recycledParcelCount;
  final num recycledSaving;
  final int consolidatedParcelCount;
  final num consolidatedSaving;
  final int missingBasisCount;
  final int negativeParcelCount;
  final int missingShippingFeeCount;

  const SavingsSummary({
    required this.parcelCount,
    required this.boxSaving,
    required this.deliverySaving,
    required this.totalSaving,
    required this.recycledParcelCount,
    required this.recycledSaving,
    required this.consolidatedParcelCount,
    required this.consolidatedSaving,
    required this.missingBasisCount,
    required this.negativeParcelCount,
    required this.missingShippingFeeCount,
  });
}

/// Savings of one master option — `GET /api/admin/packing/savings/options`.
class OptionSaving {
  final int? masterProductId;
  final String? masterProductName;
  final int? masterOptionId;
  final String? masterOptionName;
  final int parcelCount;
  final num boxSaving;
  final num deliverySaving;
  final num totalSaving;

  const OptionSaving({
    required this.masterProductId,
    required this.masterProductName,
    required this.masterOptionId,
    required this.masterOptionName,
    required this.parcelCount,
    required this.boxSaving,
    required this.deliverySaving,
    required this.totalSaving,
  });
}

/// Savings of one box — `GET /api/admin/packing/savings/boxes`.
class BoxSaving {
  final int packageId;
  final String type;

  /// `PURCHASED` · `RECYCLED`.
  final String? boxKind;
  final num widthCm;
  final num lengthCm;
  final num heightCm;
  final String? imageUrl;
  final int parcelCount;
  final num boxSaving;
  final num deliverySaving;
  final num totalSaving;

  const BoxSaving({
    required this.packageId,
    required this.type,
    required this.boxKind,
    required this.widthCm,
    required this.lengthCm,
    required this.heightCm,
    required this.imageUrl,
    required this.parcelCount,
    required this.boxSaving,
    required this.deliverySaving,
    required this.totalSaving,
  });
}

/// Option savings folded per master (web `groupSavingsByMaster`).
class MasterSaving {
  final int masterProductId;
  final num totalSaving;
  final int parcelCount;
  final List<OptionSaving> options;

  const MasterSaving({
    required this.masterProductId,
    required this.totalSaving,
    required this.parcelCount,
    required this.options,
  });
}

/// Folds option savings per master in the server order; rows without a master
/// are left out.
Map<int, MasterSaving> groupSavingsByMaster(List<OptionSaving> rows) {
  final grouped = <int, MasterSaving>{};
  for (final row in rows) {
    final id = row.masterProductId;
    if (id == null) {
      continue;
    }
    final found = grouped[id];
    grouped[id] = MasterSaving(
      masterProductId: id,
      totalSaving: (found?.totalSaving ?? 0) + row.totalSaving,
      parcelCount: (found?.parcelCount ?? 0) + row.parcelCount,
      options: [...?found?.options, row],
    );
  }
  return grouped;
}

/// One sale date of the dashboard sales chart — `GET /api/admin/sales/daily`
/// (FEATURE_2610_29 / D22). One row per date of the period, zeros included.
class DailySales {
  /// `yyyy-MM-dd` sale date.
  final String date;

  /// Same amount as [SellerSales.grossSales] (before discount).
  final num grossSales;

  /// Orders of that date in that amount.
  final int orderCount;

  const DailySales({
    required this.date,
    required this.grossSales,
    required this.orderCount,
  });
}
