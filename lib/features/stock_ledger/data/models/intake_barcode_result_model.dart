import '../../domain/entities/stock_intake.dart';

/// `GET /api/admin/stock/intake/barcode` `data` (FEATURE_2611_33 D5).
///
/// `price` and `imageUrl` are not read (D8).
class IntakeBarcodeResultModel extends IntakeBarcodeResult {
  const IntakeBarcodeResultModel({
    required super.found,
    super.productId,
    super.productName,
  });

  factory IntakeBarcodeResultModel.fromJson(Map<String, dynamic> json) =>
      IntakeBarcodeResultModel(
        found: json['found'] as bool? ?? false,
        productId: (json['productId'] as num?)?.toInt(),
        productName: json['productName'] as String?,
      );
}
