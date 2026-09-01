import '../../domain/entities/template_field.dart';

class TemplateFieldModel extends TemplateField {
  const TemplateFieldModel({
    required super.key,
    required super.label,
    required super.defaultValue,
  });

  factory TemplateFieldModel.fromJson(Map<String, dynamic> json) => TemplateFieldModel(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        defaultValue: json['defaultValue'] as String? ?? '',
      );
}
