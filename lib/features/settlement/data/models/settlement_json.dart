// JSON -> settlement entities — the only file of this feature that knows JSON
// keys (keys = web `Settlement.ts` field names). Missing numbers read as null
// (unknown, not 0); missing counts read as 0, same as the web.
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';

typedef Json = Map<String, dynamic>;

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
int? _intN(Object? v) => (v as num?)?.toInt();
num? _numN(Object? v) => v as num?;
num _num(Object? v) => (v as num?) ?? 0;
String? _strN(Object? v) => v?.toString();
String _str(Object? v) => v?.toString() ?? '';
bool _bool(Object? v) => v == true;
List<String> _strList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];
List<T> _list<T>(Object? v, T Function(Json) parse) =>
    v is List ? v.whereType<Json>().map(parse).toList() : <T>[];

PayoutSummary payoutSummaryFromJson(Json j) => PayoutSummary(
      payoutId: _int(j['payoutId']),
      lineCount: _int(j['lineCount']),
      paymentCheckNeeded: _bool(j['paymentCheckNeeded']),
      accountId: _intN(j['accountId']),
      platform: _strN(j['platform']),
      accountAlias: _strN(j['accountAlias']),
      sellerId: _intN(j['sellerId']),
      sellerName: _strN(j['sellerName']),
      settlementType: _strN(j['settlementType']),
      revenueRecognitionMonth: _strN(j['revenueRecognitionMonth']),
      recognitionFrom: _strN(j['recognitionFrom']),
      recognitionTo: _strN(j['recognitionTo']),
      settlementDate: _strN(j['settlementDate']),
      finalSettlementDate: _strN(j['finalSettlementDate']),
      totalSale: _numN(j['totalSale']),
      serviceFee: _numN(j['serviceFee']),
      finalAmount: _numN(j['finalAmount']),
      status: _strN(j['status']),
      reconStatus: _strN(j['reconStatus']),
    );

AdjustmentView adjustmentViewFromJson(Json j) => AdjustmentView(
      type: _str(j['type']),
      amount: _numN(j['amount']),
      note: _strN(j['note']),
      guidance: _strN(j['guidance']),
    );

ReconLineView reconLineViewFromJson(Json j) => ReconLineView(
      label: _str(j['label']),
      unmatched: _bool(j['unmatched']),
      externalOrderId: _strN(j['externalOrderId']),
      platformOptionId: _strN(j['platformOptionId']),
      productName: _strN(j['productName']),
      recognitionDate: _strN(j['recognitionDate']),
      settlementDate: _strN(j['settlementDate']),
      settlementType: _strN(j['settlementType']),
      saleAmount: _numN(j['saleAmount']),
      serviceFee: _numN(j['serviceFee']),
      serviceFeeRatio: _numN(j['serviceFeeRatio']),
      settlementAmount: _numN(j['settlementAmount']),
      diff: _numN(j['diff']),
    );

LabelView labelViewFromJson(Json j) => LabelView(
      label: _str(j['label']),
      count: _int(j['count']),
      amount: _numN(j['amount']),
      detail: _strN(j['detail']),
    );

ReconReport reconReportFromJson(Json j) {
  final a = (j['blockA'] as Json?) ?? const <String, dynamic>{};
  final b = (j['blockB'] as Json?) ?? const <String, dynamic>{};
  final m = j['monthCheck'];
  return ReconReport(
    payout: payoutSummaryFromJson(
        (j['payout'] as Json?) ?? const <String, dynamic>{}),
    blockA: ReconBlockA(
      adjustments: _list(a['adjustments'], adjustmentViewFromJson),
      unmatchedCount: _int(a['unmatchedCount']),
      lineTotal: _numN(a['lineTotal']),
      adjustmentTotal: _numN(a['adjustmentTotal']),
      ourTotal: _numN(a['ourTotal']),
      finalAmount: _numN(a['finalAmount']),
      diff: _numN(a['diff']),
      tolerance: _numN(a['tolerance']),
      reconStatus: _strN(a['reconStatus']),
    ),
    blockB: ReconBlockB(
      labels: _list(b['labels'], labelViewFromJson),
      expected: _numN(b['expected']),
      actual: _numN(b['actual']),
      totalDiff: _numN(b['totalDiff']),
    ),
    monthCheck: m is Json
        ? MonthCheck(
            ourLineCount: _int(m['ourLineCount']),
            payoutCount: _int(m['payoutCount']),
            pendingPayoutCount: _int(m['pendingPayoutCount']),
            revenueRecognitionMonth: _strN(m['revenueRecognitionMonth']),
            ourLineTotal: _numN(m['ourLineTotal']),
            payoutTotal: _numN(m['payoutTotal']),
            diff: _numN(m['diff']),
          )
        : null,
  );
}

SettlementSyncResult settlementSyncResultFromJson(Json j) =>
    SettlementSyncResult(
      accounts: _int(j['accounts']),
      lines: _int(j['lines']),
      matched: _int(j['matched']),
      unmatched: _int(j['unmatched']),
      duplicates: _int(j['duplicates']),
      skipped: _bool(j['skipped']),
      failedAccounts: _strList(j['failedAccounts']),
      nextAvailableAt: _strN(j['nextAvailableAt']),
    );

PayoutSyncResult payoutSyncResultFromJson(Json j) => PayoutSyncResult(
      accounts: _int(j['accounts']),
      payouts: _int(j['payouts']),
      attributedLines: _int(j['attributedLines']),
      adjustments: _int(j['adjustments']),
      failedAccounts: _strList(j['failedAccounts']),
    );

SettlementSyncTarget settlementSyncTargetFromJson(Json j) =>
    SettlementSyncTarget(
      accountId: _int(j['accountId']),
      sellerId: _intN(j['sellerId']),
      sellerName: _strN(j['sellerName']),
      platform: _strN(j['platform']),
      accountAlias: _strN(j['accountAlias']),
      lastSettlementSyncAt: _strN(j['lastSettlementSyncAt']),
      lastPayoutSyncAt: _strN(j['lastPayoutSyncAt']),
      nextAvailableAt: _strN(j['nextAvailableAt']),
    );

SaleMonthSettlement saleMonthSettlementFromJson(Json j) => SaleMonthSettlement(
      saleMonth: _str(j['saleMonth']),
      paid: _bool(j['paid']),
      orders: _int(j['orders']),
      saleAmount: _num(j['saleAmount']),
      settlementAmount: _num(j['settlementAmount']),
      settlementDate: _strN(j['settlementDate']),
    );

FirstMonthQuestion firstMonthQuestionFromJson(Json j) => FirstMonthQuestion(
      linkId: _int(j['linkId']),
      accountId: _int(j['accountId']),
      firstMonth: _str(j['firstMonth']),
      askMonth: _str(j['askMonth']),
      accountAlias: _strN(j['accountAlias']),
      sellerName: _strN(j['sellerName']),
    );

SettlementMonthSummary settlementMonthSummaryFromJson(Json j) =>
    SettlementMonthSummary(
      total: _numN(j['total']),
      paid: _numN(j['paid']),
      remaining: _numN(j['remaining']),
    );

/// A JSON list of objects → entities.
List<T> listFromJson<T>(Object? v, T Function(Json) parse) => _list(v, parse);
