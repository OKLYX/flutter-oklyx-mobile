import 'package:flutter_oklyn_mobile/features/product/domain/entities/barcode_scan_result.dart';

class BarcodeScanResultModel extends BarcodeScanResult {
  const BarcodeScanResultModel({super.barcode, super.format});

  factory BarcodeScanResultModel.fromJson(Map<String, dynamic> json) =>
      BarcodeScanResultModel(
        barcode: json['barcode'] as String?,
        format: json['format'] as String?,
      );
}
