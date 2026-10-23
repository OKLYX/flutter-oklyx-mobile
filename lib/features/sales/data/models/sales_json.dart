// JSON -> sales entities — the only file of this feature that knows JSON keys
// (keys = web `SalesSummary.ts` · `PackingSavingsEntity.ts` field names). A
// missing profit reads as null (unknown, not 0); other missing numbers read as
// 0.
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';

typedef Json = Map<String, dynamic>;

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
int? _intN(Object? v) => (v as num?)?.toInt();
num _num(Object? v) => (v as num?) ?? 0;
num? _numN(Object? v) => v as num?;
String _str(Object? v) => v?.toString() ?? '';
String? _strN(Object? v) => v?.toString();
bool _bool(Object? v) => v == true;

/// Envelope list → entities; a non-list reads as empty.
List<T> listFromJson<T>(Object? v, T Function(Json) parse) =>
    v is List ? v.whereType<Json>().map(parse).toList() : <T>[];

SellerSales sellerSalesFromJson(Json j) => SellerSales(
      sellerId: _int(j['sellerId']),
      sellerName: _str(j['sellerName']),
      grossSales: _num(j['grossSales']),
      discount: _num(j['discount']),
      netQty: _num(j['netQty']),
      holdQty: _num(j['holdQty']),
      estFee: _num(j['estFee']),
      estNetProfit: _numN(j['estNetProfit']),
      costBasisReady: _bool(j['costBasisReady']),
      pendingPayout: _num(j['pendingPayout']),
      fixedCost: _num(j['fixedCost']),
    );

ChannelSales channelSalesFromJson(Json j) => ChannelSales(
      accountId: _int(j['accountId']),
      accountAlias: _strN(j['accountAlias']),
      platform: _strN(j['platform']),
      sellerId: _intN(j['sellerId']),
      sellerName: _strN(j['sellerName']),
      grossSales: _num(j['grossSales']),
      discount: _num(j['discount']),
      netQty: _num(j['netQty']),
      holdQty: _num(j['holdQty']),
      estFee: _num(j['estFee']),
      estNetProfit: _numN(j['estNetProfit']),
      costBasisReady: _bool(j['costBasisReady']),
      cancelQty: _num(j['cancelQty']),
      refundedAmount: _num(j['refundedAmount']),
      pendingRefundAmount: _num(j['pendingRefundAmount']),
      pendingPayout: _num(j['pendingPayout']),
      paidAmount: _num(j['paidAmount']),
      lastSettlementSyncAt: _strN(j['lastSettlementSyncAt']),
      fixedCost: _num(j['fixedCost']),
      fixedCostMonths: _int(j['fixedCostMonths']),
    );

SalesLine salesLineFromJson(Json j) => SalesLine(
      orderLineId: _int(j['orderLineId']),
      accountId: _int(j['accountId']),
      orderedAt: _strN(j['orderedAt']),
      externalOrderId: _str(j['externalOrderId']),
      itemName: _strN(j['itemName']),
      masterProductName: _strN(j['masterProductName']),
      orderQty: _num(j['orderQty']),
      cancelQty: _num(j['cancelQty']),
      holdQty: _num(j['holdQty']),
      netQty: _num(j['netQty']),
      unitPrice: _num(j['unitPrice']),
      grossSales: _num(j['grossSales']),
      discount: _num(j['discount']),
    );

ProductProfit productProfitFromJson(Json j) => ProductProfit(
      masterProductId: _intN(j['masterProductId']),
      masterProductName: _str(j['masterProductName']),
      accountId: _intN(j['accountId']),
      accountAlias: _strN(j['accountAlias']),
      netQty: _num(j['netQty']),
      grossSales: _num(j['grossSales']),
      discount: _num(j['discount']),
      estFee: _num(j['estFee']),
      estNetProfit: _numN(j['estNetProfit']),
      costBasisReady: _bool(j['costBasisReady']),
      uncategorized: _bool(j['uncategorized']),
    );

SavingsSummary savingsSummaryFromJson(Json j) => SavingsSummary(
      parcelCount: _int(j['parcelCount']),
      boxSaving: _num(j['boxSaving']),
      deliverySaving: _num(j['deliverySaving']),
      totalSaving: _num(j['totalSaving']),
      recycledParcelCount: _int(j['recycledParcelCount']),
      recycledSaving: _num(j['recycledSaving']),
      consolidatedParcelCount: _int(j['consolidatedParcelCount']),
      consolidatedSaving: _num(j['consolidatedSaving']),
      missingBasisCount: _int(j['missingBasisCount']),
      negativeParcelCount: _int(j['negativeParcelCount']),
      missingShippingFeeCount: _int(j['missingShippingFeeCount']),
    );

OptionSaving optionSavingFromJson(Json j) => OptionSaving(
      masterProductId: _intN(j['masterProductId']),
      masterProductName: _strN(j['masterProductName']),
      masterOptionId: _intN(j['masterOptionId']),
      masterOptionName: _strN(j['masterOptionName']),
      parcelCount: _int(j['parcelCount']),
      boxSaving: _num(j['boxSaving']),
      deliverySaving: _num(j['deliverySaving']),
      totalSaving: _num(j['totalSaving']),
    );

BoxSaving boxSavingFromJson(Json j) => BoxSaving(
      packageId: _int(j['packageId']),
      type: _str(j['type']),
      boxKind: _strN(j['boxKind']),
      widthCm: _num(j['widthCm']),
      lengthCm: _num(j['lengthCm']),
      heightCm: _num(j['heightCm']),
      imageUrl: _strN(j['imageUrl']),
      parcelCount: _int(j['parcelCount']),
      boxSaving: _num(j['boxSaving']),
      deliverySaving: _num(j['deliverySaving']),
      totalSaving: _num(j['totalSaving']),
    );

DailySales dailySalesFromJson(Json j) => DailySales(
      date: _str(j['date']),
      grossSales: _num(j['grossSales']),
      orderCount: _int(j['orderCount']),
    );
