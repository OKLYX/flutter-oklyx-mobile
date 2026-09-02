import 'package:equatable/equatable.dart';

/// A user-defined input field of the default thumbnail template (bind target for
/// text elements). Mirrors backend `TemplateField`.
///
/// `brandName` / `productName` are reserved keys — the generation panel auto-fills
/// them from the product (brand / product name) and labels them "(자동)".
class TemplateField extends Equatable {
  final String key;
  final String label;
  final String defaultValue;

  const TemplateField({
    required this.key,
    required this.label,
    required this.defaultValue,
  });

  static const String reservedBrandName = 'brandName';
  static const String reservedProductName = 'productName';

  bool get isReserved => key == reservedBrandName || key == reservedProductName;

  @override
  List<Object?> get props => [key, label, defaultValue];
}
