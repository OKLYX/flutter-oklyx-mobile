class Package {
  final int id;
  final String type;
  final double cost;
  final String effectiveDate;
  final bool isDefault;

  Package({
    required this.id,
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
  });

  Package copyWith({
    int? id,
    String? type,
    double? cost,
    String? effectiveDate,
    bool? isDefault,
  }) {
    return Package(
      id: id ?? this.id,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
