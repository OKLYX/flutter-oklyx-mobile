/// Bought or recycled box (FEATURE_2611_06 / PLAN D16) — the server `BoxKind`,
/// the same labels as the web `BOX_KIND_LABEL`.
///
/// ⚠️ A missing or unknown code reads as [purchased] — the server's default.
enum BoxKind {
  purchased('PURCHASED', '구매 상자'),
  recycled('RECYCLED', '재활용 상자');

  /// The value the server sends and takes.
  final String code;

  /// The screen label.
  final String label;

  const BoxKind(this.code, this.label);

  static BoxKind parse(String? code) =>
      code == recycled.code ? recycled : purchased;
}

class Package {
  final int id;
  final String type;
  final double cost;
  final bool isDefault;
  final double widthCm;
  final double lengthCm;
  final double heightCm;

  /// Bought or recycled (FEATURE_2611_06 / D16).
  final BoxKind boxKind;

  Package({
    required this.id,
    required this.type,
    required this.cost,
    required this.isDefault,
    required this.widthCm,
    required this.lengthCm,
    required this.heightCm,
    this.boxKind = BoxKind.purchased,
  });

  Package copyWith({
    int? id,
    String? type,
    double? cost,
    bool? isDefault,
    double? widthCm,
    double? lengthCm,
    double? heightCm,
    BoxKind? boxKind,
  }) {
    return Package(
      id: id ?? this.id,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      isDefault: isDefault ?? this.isDefault,
      widthCm: widthCm ?? this.widthCm,
      lengthCm: lengthCm ?? this.lengthCm,
      heightCm: heightCm ?? this.heightCm,
      boxKind: boxKind ?? this.boxKind,
    );
  }
}

/// Box size label helper — `22 × 19 × 9 cm`.
///
/// **Purpose**: one place so the list / detail / edit screens of 「상자비」
/// and the box change sheet (FEATURE_2611_06 / D16) show the same text.
/// **Rule**: all three 0 → '미지정' — a box made before sizes existed
/// (backfilled with 0, PLAN 2609_38 D4 · D8).
///
/// **Usage**:
/// ```dart
/// Text('사이즈: ${package.sizeLabel}');            // 22 × 19 × 9 cm
/// if (package.isSizeUnset) { /* show it in a lighter color */ }
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
