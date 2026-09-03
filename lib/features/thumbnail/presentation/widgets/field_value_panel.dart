import 'package:flutter/material.dart';

import '../../domain/entities/template_field.dart';

/// Generation panel: one labelled TextField per template field. Reserved keys
/// (brandName/productName) are marked "(자동)" since they auto-fill from the product.
///
/// Stateful so each field keeps a [TextEditingController] seeded once from the
/// initial values — parent rebuilds (e.g. spinner toggles) don't reset the text.
class FieldValuePanel extends StatefulWidget {
  final List<TemplateField> fields;
  final Map<String, String> initialValues;
  final void Function(String key, String value) onChanged;

  const FieldValuePanel({
    super.key,
    required this.fields,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<FieldValuePanel> createState() => _FieldValuePanelState();
}

class _FieldValuePanelState extends State<FieldValuePanel> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _controllers[field.key] =
          TextEditingController(text: widget.initialValues[field.key] ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in widget.fields) ...[
          Text(
            field.isReserved ? '${field.label} (자동)' : field.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controllers[field.key],
            onChanged: (value) => widget.onChanged(field.key, value),
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
