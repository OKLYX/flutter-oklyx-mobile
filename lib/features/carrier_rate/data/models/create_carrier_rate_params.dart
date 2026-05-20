class CreateCarrierRateParams {
  final String carrier;
  final String type;
  final double cost;
  final String effectiveDate; // YYYY-MM-DD
  final bool isDefault;

  CreateCarrierRateParams({
    required this.carrier,
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() => {
    'carrier': carrier,
    'type': type,
    'cost': cost,
    'effectiveDate': effectiveDate,
    'isDefault': isDefault,
  };
}
