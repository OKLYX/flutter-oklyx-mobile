import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

class CreatePackageParams {
  final String type;
  final double cost;
  final bool isDefault;
  final double widthCm;
  final double lengthCm;
  final double heightCm;

  /// Sent as `boxKind` (FEATURE_2611_06 / D16). Callers that do not pass it
  /// register a purchased box, as before.
  final BoxKind boxKind;

  CreatePackageParams({
    required this.type,
    required this.cost,
    required this.isDefault,
    required this.widthCm,
    required this.lengthCm,
    required this.heightCm,
    this.boxKind = BoxKind.purchased,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'cost': cost,
    'isDefault': isDefault,
    'widthCm': widthCm,
    'lengthCm': lengthCm,
    'heightCm': heightCm,
    'boxKind': boxKind.code,
  };
}
