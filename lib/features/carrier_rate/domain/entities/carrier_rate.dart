class CarrierRate {
  final int id;
  final String carrier;
  final String type;
  final double cost;
  final String effectiveDate;
  final bool isDefault;

  CarrierRate({
    required this.id,
    required this.carrier,
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
  });

  CarrierRate copyWith({
    int? id,
    String? carrier,
    String? type,
    double? cost,
    String? effectiveDate,
    bool? isDefault,
  }) {
    return CarrierRate(
      id: id ?? this.id,
      carrier: carrier ?? this.carrier,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarrierRate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          carrier == other.carrier;

  @override
  int get hashCode => id.hashCode ^ carrier.hashCode;
}
