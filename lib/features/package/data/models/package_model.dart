import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

class PackageModel extends Package {
  PackageModel({
    required int id,
    required String type,
    required double cost,
    required String effectiveDate,
    required bool isDefault,
  }) : super(
    id: id,
    type: type,
    cost: cost,
    effectiveDate: effectiveDate,
    isDefault: isDefault,
  );

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      type: json['type'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      effectiveDate: json['effectiveDate'] ?? 'N/A',
      isDefault: json['isDefault'] ?? false,
    );
  }
}
