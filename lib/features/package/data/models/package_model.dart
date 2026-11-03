import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

class PackageModel extends Package {
  PackageModel({
    required int id,
    required String type,
    required double cost,
    required bool isDefault,
    required double widthCm,
    required double lengthCm,
    required double heightCm,
    BoxKind boxKind = BoxKind.purchased,
  }) : super(
    id: id,
    type: type,
    cost: cost,
    isDefault: isDefault,
    widthCm: widthCm,
    lengthCm: lengthCm,
    heightCm: heightCm,
    boxKind: boxKind,
  );

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      type: json['type'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      isDefault: json['isDefault'] ?? false,
      widthCm: (json['widthCm'] ?? 0).toDouble(),
      lengthCm: (json['lengthCm'] ?? 0).toDouble(),
      heightCm: (json['heightCm'] ?? 0).toDouble(),
      // FEATURE_2611_06 D16: the server already sends it; missing = purchased.
      boxKind: BoxKind.parse(json['boxKind'] as String?),
    );
  }
}
