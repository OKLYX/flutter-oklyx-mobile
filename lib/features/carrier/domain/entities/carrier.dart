/// 택배사 마스터 엔티티.
///
/// 요율(carrier_rate) 과는 완전히 별개인 택배사 자체의 마스터 정보.
class Carrier {
  final int id;
  final String name;
  final bool isActive;

  Carrier({
    required this.id,
    required this.name,
    required this.isActive,
  });

  Carrier copyWith({
    int? id,
    String? name,
    bool? isActive,
  }) {
    return Carrier(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Carrier && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
