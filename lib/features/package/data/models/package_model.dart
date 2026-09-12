import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

class PackageModel extends Package {
  PackageModel({
    required int id,
    required String type,
    required double cost,
    required String effectiveDate,
    required bool isDefault,
    required double widthCm,
    required double lengthCm,
    required double heightCm,
  }) : super(
    id: id,
    type: type,
    cost: cost,
    effectiveDate: effectiveDate,
    isDefault: isDefault,
    widthCm: widthCm,
    lengthCm: lengthCm,
    heightCm: heightCm,
  );

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      type: json['type'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      effectiveDate: json['effectiveDate'] ?? 'N/A',
      isDefault: json['isDefault'] ?? false,
      widthCm: (json['widthCm'] ?? 0).toDouble(),
      lengthCm: (json['lengthCm'] ?? 0).toDouble(),
      heightCm: (json['heightCm'] ?? 0).toDouble(),
    );
  }
}
