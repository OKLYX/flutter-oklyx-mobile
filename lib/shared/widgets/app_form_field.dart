import 'package:flutter/material.dart';

/// Input row and read-only row of the four settings detail pages — commission
/// rate, category, carrier rate, package (FEATURE_2610_02 · N12 / N12-2).
///
/// **File**: lib/shared/widgets/app_form_field.dart
///
/// **Usage**:
/// ```dart
/// AppFormField('상자명', _nameController, (v) => bloc.add(NameChanged(v)),
///     error: state.nameError)
/// AppFormField('비용', _costController, onCost,
///     keyboardType: TextInputType.number)
/// const AppDetailField('상자명', '소형 박스')
/// ```
///
/// ⚠️ The label lives inside the field (floats onto the border when focused).
/// ⚠️ An error goes to the field's own error slot (`error:`), not to a text
///    below it. A hint or helper text the field already had goes to
///    `hintText:` / `helperText:`.
/// ❌ Do not copy `_FormField` / `_DetailField` into a page again.

/// Input row: label inside the field, 16 below.
class AppFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? error;
  final TextInputType keyboardType;
  final String? hintText;
  final String? helperText;

  const AppFormField(
    this.label,
    this.controller,
    this.onChanged, {
    super.key,
    this.error,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            helperText: helperText,
            errorText: error,
          ),
          onChanged: onChanged,
        ),
      );
}

/// Read-only row: small muted label (12) · bold value (16) · divider.
class AppDetailField extends StatelessWidget {
  final String label;
  final String value;

  const AppDetailField(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Divider(),
          ],
        ),
      );
}
