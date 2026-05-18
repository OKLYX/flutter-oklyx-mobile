class CreatePackageParams {
  final String type;
  final double cost;
  final String effectiveDate;
  final bool isDefault;

  CreatePackageParams({
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'cost': cost,
    'effectiveDate': effectiveDate,
    'isDefault': isDefault,
  };
}
