class CreateCarrierRateParams {
  final int carrierId;
  final String type;
  final double cost;
  final String effectiveDate; // YYYY-MM-DD
  final bool isDefault;

  CreateCarrierRateParams({
    required this.carrierId,
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() => {
    'carrierId': carrierId,
    'type': type,
    'cost': cost,
    'effectiveDate': effectiveDate,
    'isDefault': isDefault,
  };
}
