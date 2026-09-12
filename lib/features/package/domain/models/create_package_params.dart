class CreatePackageParams {
  final String type;
  final double cost;
  final String effectiveDate;
  final bool isDefault;
  final double widthCm;
  final double lengthCm;
  final double heightCm;

  CreatePackageParams({
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
    required this.widthCm,
    required this.lengthCm,
    required this.heightCm,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'cost': cost,
    'effectiveDate': effectiveDate,
    'isDefault': isDefault,
    'widthCm': widthCm,
    'lengthCm': lengthCm,
    'heightCm': heightCm,
  };
}
