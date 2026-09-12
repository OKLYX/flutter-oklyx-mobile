class Package {
  final int id;
  final String type;
  final double cost;
  final String effectiveDate;
  final bool isDefault;
  final double widthCm;
  final double lengthCm;
  final double heightCm;

  Package({
    required this.id,
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
    required this.widthCm,
    required this.lengthCm,
    required this.heightCm,
  });

  Package copyWith({
    int? id,
    String? type,
    double? cost,
    String? effectiveDate,
    bool? isDefault,
    double? widthCm,
    double? lengthCm,
    double? heightCm,
  }) {
    return Package(
      id: id ?? this.id,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      isDefault: isDefault ?? this.isDefault,
      widthCm: widthCm ?? this.widthCm,
      lengthCm: lengthCm ?? this.lengthCm,
      heightCm: heightCm ?? this.heightCm,
    );
  }
}

/// 상자 사이즈 표기 헬퍼. `22 × 19 × 9 cm` 형태로 만든다.
///
/// **용도**: 목록/상세/수정 세 화면이 같은 문자열을 쓰도록 한 곳에 둔다.
/// **규칙**: 셋 다 0 이면 '미지정' — 사이즈가 없던 시절에 만든 상자다
/// (0 백필, PLAN 2609_38 D4·D8).
///
/// **사용 예제**:
/// ```dart
/// Text('사이즈: ${package.sizeLabel}');            // 22 × 19 × 9 cm
/// if (package.isSizeUnset) { /* 옅은 색으로 표시 */ }
/// ```
extension PackageSizeLabel on Package {
  bool get isSizeUnset => widthCm == 0 && lengthCm == 0 && heightCm == 0;

  String get sizeLabel {
    if (isSizeUnset) {
      return '미지정';
    }
    String n(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    return '${n(widthCm)} × ${n(lengthCm)} × ${n(heightCm)} cm';
  }
}
