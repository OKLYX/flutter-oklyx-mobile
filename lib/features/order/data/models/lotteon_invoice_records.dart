import 'package:equatable/equatable.dart';

/// The LotteON shipping records of one product line of a delivery
/// (GET /api/orders/{orderItemId}/lotteon-invoice-records,
/// FEATURE_2611_23 / D19 ⑥-1 · ⑥-5).
///
/// **Purpose**: one product block of the 「송장 수정」 sheet.
///
/// ⚠️ [records] is empty when LotteON has no record for the line — the sheet
/// then shows a gray no-record line for it (R52).
class LotteonInvoiceRecords extends Equatable {
  final int orderItemId;
  final String productName;
  final List<LotteonInvoiceRecord> records;

  const LotteonInvoiceRecords({
    required this.orderItemId,
    required this.productName,
    required this.records,
  });

  factory LotteonInvoiceRecords.fromJson(Map<String, dynamic> json) =>
      LotteonInvoiceRecords(
        orderItemId: (json['orderItemId'] as num?)?.toInt() ?? 0,
        productName: json['productName']?.toString() ?? '',
        records: (json['records'] as List? ?? [])
            .map(
                (e) => LotteonInvoiceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [orderItemId, productName, records];
}

/// One LotteON shipping record (a 140 line) of a product line
/// (FEATURE_2611_23 / D19 ⑥-2 · ⑥-10).
///
/// ⚠️ [statusAt] is a KST wall-clock string — cut it as text, never turn it
/// into a date object (R52).
class LotteonInvoiceRecord extends Equatable {
  final String procSeq;
  final String? invoiceNumber;
  final String? carrierCode;
  final String? carrierName;
  final String statusCode;
  final String statusName;
  final String? statusAt;

  const LotteonInvoiceRecord({
    required this.procSeq,
    required this.statusCode,
    required this.statusName,
    this.invoiceNumber,
    this.carrierCode,
    this.carrierName,
    this.statusAt,
  });

  /// Only status 13 · 14 · 15 can be picked (D19 ⑥-10).
  bool get pickable =>
      statusCode == '13' || statusCode == '14' || statusCode == '15';

  factory LotteonInvoiceRecord.fromJson(Map<String, dynamic> json) =>
      LotteonInvoiceRecord(
        procSeq: json['procSeq']?.toString() ?? '',
        invoiceNumber: json['invoiceNumber']?.toString(),
        carrierCode: json['carrierCode']?.toString(),
        carrierName: json['carrierName']?.toString(),
        statusCode: json['statusCode']?.toString() ?? '',
        statusName: json['statusName']?.toString() ?? '',
        statusAt: json['statusAt']?.toString(),
      );

  @override
  List<Object?> get props => [
        procSeq,
        invoiceNumber,
        carrierCode,
        carrierName,
        statusCode,
        statusName,
        statusAt,
      ];
}
