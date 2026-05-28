class CommissionRate {
  final int id;
  final String platform;
  final int? categoryId;
  final double rate;
  final bool isDefault;

  CommissionRate({
    required this.id,
    required this.platform,
    this.categoryId,
    required this.rate,
    required this.isDefault,
  });

  CommissionRate copyWith({
    int? id,
    String? platform,
    int? categoryId,
    double? rate,
    bool? isDefault,
  }) {
    return CommissionRate(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      categoryId: categoryId ?? this.categoryId,
      rate: rate ?? this.rate,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionRate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          platform == other.platform;

  @override
  int get hashCode => id.hashCode ^ platform.hashCode;
}
