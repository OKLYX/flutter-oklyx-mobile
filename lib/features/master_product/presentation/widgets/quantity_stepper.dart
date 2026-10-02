import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

/// Quantity input (stepper) — port of web
/// `presentation/components/QuantityStepper.tsx` (@09208a0).
///
/// **Purpose**: fields that take an integer ≥ [min] (component quantity etc.).
/// ▲▼ next to the field bump the value by [step] and clamp it to
/// `[min, max]`.
/// **File**: lib/features/master_product/presentation/widgets/quantity_stepper.dart
///
/// **String contract**: [value] is a `String` — it is never converted while
/// typing. A blank string is passed up as-is; the caller validates and parses
/// once, right before submit. Only digits can be typed (no sign/decimal), so
/// the caller's `int.parse` of a non-blank value never fails.
///
/// **▲▼**: a blank value starts at [min]. ▼ is disabled at or below [min],
/// ▲ at or above [max].
///
/// **Usage**:
/// ```dart
/// QuantityStepper(value: _qty, onChanged: (next) => setState(() => _qty = next))
/// QuantityStepper(value: _qty, onChanged: _setQty, disabled: _busy, width: 72)
/// QuantityStepper(value: _stock, onChanged: _setStock, min: 0, title: hint)
/// ```
///
/// ⚠️ Pass [min] explicitly where `0` is meaningful (stock).
/// ❌ Do not wrap it in another controller-holding widget — the controller
///    lives here and syncs from [value] only when they differ.
class QuantityStepper extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final int min;
  final int? max;
  final int step;
  final bool disabled;

  /// Hint shown behind an (!) icon after the stepper (web `title=`).
  final String? title;
  final double width;

  const QuantityStepper({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 1,
    this.max,
    this.step = 1,
    this.disabled = false,
    this.title,
    this.width = 96,
  });

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  num? get _current {
    final trimmed = widget.value.trim();
    return trimmed.isEmpty ? null : num.tryParse(trimmed);
  }

  num _clamp(num n) {
    final lower = n < widget.min ? widget.min : n;
    final max = widget.max;
    return max != null && lower > max ? max : lower;
  }

  // Blank → start from min.
  void _bump(int delta) {
    final current = _current;
    final next = current == null ? widget.min : _clamp(current + delta);
    widget.onChanged(next.toString());
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final atMin = current != null && current <= widget.min;
    final max = widget.max;
    final atMax = max != null && current != null && current >= max;
    final title = widget.title;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          child: TextField(
            controller: _controller,
            enabled: !widget.disabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: widget.onChanged,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_drop_up),
              iconSize: 20,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 20),
              onPressed:
                  widget.disabled || atMax ? null : () => _bump(widget.step),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 20,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 20),
              onPressed:
                  widget.disabled || atMin ? null : () => _bump(-widget.step),
            ),
          ],
        ),
        if (title != null) InfoBubbleIcon(message: title),
      ],
    );
  }
}
