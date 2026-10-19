// Settlement ledger entities — the mobile port of the web
// `src/domain/entities/Settlement.ts` (FEATURE_2610_20 / D18 · D22). Amounts
// are the server's numbers as they are; the one sum a screen makes is the
// month subtotal of 「판매월 기준」 (the web `SaleMonthTable` does the same).

/// One payout. `GET /api/admin/settlement/payouts` · `/payouts/by-recognition`.
class PayoutSummary {
  final int payoutId;
  final int? accountId;
  final String? platform;
  final String? accountAlias;
  final int? sellerId;
  final String? sellerName;

  /// WEEKLY · MONTHLY · ADDITIONAL · RESERVE · DAILY · UNKNOWN.
  final String? settlementType;
  final String? revenueRecognitionMonth;
  final String? recognitionFrom;
  final String? recognitionTo;

  /// Payout (scheduled) date — 11st = the remittance date.
  final String? settlementDate;

  /// The date the money arrived — only an 11st payout marked 「지급 완료」 has it
  /// (D38). Show `finalSettlementDate ?? settlementDate`.
  final String? finalSettlementDate;
  final num? totalSale;
  final num? serviceFee;
  final num? finalAmount;

  /// SCHEDULED · PAID · UNKNOWN.
  final String? status;

  /// PENDING · RECONCILED · UNRECONCILED · AMOUNT_ONLY · NO_TOTAL (11st, D29).
  final String? reconStatus;
  final int lineCount;

  /// D40: an overdue 11st payout still scheduled — shown as 「입금 확인 필요」.
  final bool paymentCheckNeeded;

  const PayoutSummary({
    required this.payoutId,
    required this.lineCount,
    required this.paymentCheckNeeded,
    this.accountId,
    this.platform,
    this.accountAlias,
    this.sellerId,
    this.sellerName,
    this.settlementType,
    this.revenueRecognitionMonth,
    this.recognitionFrom,
    this.recognitionTo,
    this.settlementDate,
    this.finalSettlementDate,
    this.totalSale,
    this.serviceFee,
    this.finalAmount,
    this.status,
    this.reconStatus,
  });
}

/// One payout-level adjustment. [guidance] is the server's text — shown as it
/// is (D13).
class AdjustmentView {
  final String type;
  final num? amount;
  final String? note;
  final String? guidance;

  const AdjustmentView(
      {required this.type, this.amount, this.note, this.guidance});
}

/// One line of the amount check report.
class ReconLineView {
  final String? externalOrderId;
  final String? platformOptionId;
  final String? productName;
  final String? recognitionDate;
  final String? settlementDate;
  final String? settlementType;
  final num? saleAmount;
  final num? serviceFee;
  final num? serviceFeeRatio;
  final num? settlementAmount;
  final num? diff;
  final String label;
  final bool unmatched;

  const ReconLineView({
    required this.label,
    required this.unmatched,
    this.externalOrderId,
    this.platformOptionId,
    this.productName,
    this.recognitionDate,
    this.settlementDate,
    this.settlementType,
    this.saleAmount,
    this.serviceFee,
    this.serviceFeeRatio,
    this.settlementAmount,
    this.diff,
  });
}

/// One cause label of report ① — `Σ amount == totalDiff`.
class LabelView {
  final String label;
  final num? amount;
  final int count;
  final String? detail;

  const LabelView(
      {required this.label, required this.count, this.amount, this.detail});
}

/// Block A — `Σ lines + Σ adjustments == paid amount`. [ourTotal] null = not
/// compared.
class ReconBlockA {
  final num? lineTotal;
  final List<AdjustmentView> adjustments;
  final num? adjustmentTotal;
  final num? ourTotal;
  final num? finalAmount;
  final num? diff;
  final num? tolerance;
  final int unmatchedCount;
  final String? reconStatus;

  const ReconBlockA({
    required this.adjustments,
    required this.unmatchedCount,
    this.lineTotal,
    this.adjustmentTotal,
    this.ourTotal,
    this.finalAmount,
    this.diff,
    this.tolerance,
    this.reconStatus,
  });
}

/// Block B — cause labels.
class ReconBlockB {
  final num? expected;
  final num? actual;
  final num? totalDiff;
  final List<LabelView> labels;

  const ReconBlockB(
      {required this.labels, this.expected, this.actual, this.totalDiff});
}

/// Recognition-month reference row — only for payouts that cannot be compared
/// (AMOUNT_ONLY).
class MonthCheck {
  final String? revenueRecognitionMonth;
  final num? ourLineTotal;
  final int ourLineCount;
  final num? payoutTotal;
  final num? diff;
  final int payoutCount;
  final int pendingPayoutCount;

  const MonthCheck({
    required this.ourLineCount,
    required this.payoutCount,
    required this.pendingPayoutCount,
    this.revenueRecognitionMonth,
    this.ourLineTotal,
    this.payoutTotal,
    this.diff,
  });
}

/// `GET /api/admin/settlement/payouts/{id}/report`.
class ReconReport {
  final PayoutSummary payout;
  final ReconBlockA blockA;
  final ReconBlockB blockB;
  final MonthCheck? monthCheck;

  const ReconReport(
      {required this.payout,
      required this.blockA,
      required this.blockB,
      this.monthCheck});
}

/// Revenue load result. [skipped] = within the minimum interval, not an error.
class SettlementSyncResult {
  final int accounts;
  final int lines;
  final int matched;
  final int unmatched;
  final int duplicates;
  final bool skipped;
  final String? nextAvailableAt;
  final List<String> failedAccounts;

  const SettlementSyncResult({
    required this.accounts,
    required this.lines,
    required this.matched,
    required this.unmatched,
    required this.duplicates,
    required this.skipped,
    required this.failedAccounts,
    this.nextAvailableAt,
  });
}

/// Payout load result.
class PayoutSyncResult {
  final int accounts;
  final int payouts;
  final int attributedLines;
  final int adjustments;
  final List<String> failedAccounts;

  const PayoutSyncResult({
    required this.accounts,
    required this.payouts,
    required this.attributedLines,
    required this.adjustments,
    required this.failedAccounts,
  });
}

/// One sync target channel — the channel choices and the "last refresh" text.
class SettlementSyncTarget {
  final int accountId;
  final int? sellerId;
  final String? sellerName;
  final String? platform;
  final String? accountAlias;
  final String? lastSettlementSyncAt;
  final String? lastPayoutSyncAt;
  final String? nextAvailableAt;

  const SettlementSyncTarget({
    required this.accountId,
    this.sellerId,
    this.sellerName,
    this.platform,
    this.accountAlias,
    this.lastSettlementSyncAt,
    this.lastPayoutSyncAt,
    this.nextAvailableAt,
  });
}

/// Sale month × payout date. `GET /api/admin/settlement/by-sale-month`.
class SaleMonthSettlement {
  final String saleMonth;
  final String? settlementDate;
  final bool paid;
  final int orders;
  final num saleAmount;
  final num settlementAmount;

  const SaleMonthSettlement({
    required this.saleMonth,
    required this.paid,
    required this.orders,
    required this.saleAmount,
    required this.settlementAmount,
    this.settlementDate,
  });
}

/// One 11st server-fee link waiting for the first-month answer (D45 ⑦).
class FirstMonthQuestion {
  final int linkId;
  final int accountId;
  final String? accountAlias;
  final String? sellerName;
  final String firstMonth;

  /// The month asked about = M0's previous month, `yyyy-MM`.
  final String askMonth;

  const FirstMonthQuestion({
    required this.linkId,
    required this.accountId,
    required this.firstMonth,
    required this.askMonth,
    this.accountAlias,
    this.sellerName,
  });
}
