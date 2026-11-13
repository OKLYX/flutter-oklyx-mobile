import 'package:flutter/material.dart';

/// Kind of name shown by [NameText] — it decides the line limit.
enum NameKind { product, customer }

/// Shared text for a product name or a customer name in lists and cards.
///
/// **Purpose**: one place that truncates names — product names to 2 lines,
/// customer names to 1 line, with an ellipsis; optionally tap to expand.
/// **File**: lib/shared/widgets/name_text.dart
///
/// **Parameters**:
/// - [name]: the name to show; null or blank shows [emptyText].
/// - [kind]: [NameKind.product] (2 lines) or [NameKind.customer] (1 line).
/// - [emptyText]: shown when [name] is empty (default `-`).
/// - [expandable]: when true, a tap toggles between truncated and full text.
/// - [style]: text style of the name.
/// - [noTruncate]: when true, the full name with no line limit and no
///   expand (ignores [expandable]).
///
/// **Usage**:
/// ```dart
/// NameText(name: order.itemName, kind: NameKind.product)
/// NameText(name: 'Customer A', kind: NameKind.customer)
/// NameText(
///   name: row.name,
///   kind: NameKind.product,
///   expandable: true,
///   emptyText: '—',
/// )
/// ```
///
/// ⚠️ Only detail and sheet call sites of a reused widget turn [noTruncate]
///    on — then the full name, no expand (D31, D32).
/// ⚠️ The line limit is decided in this file only — call sites do not set
///    `maxLines` for a name.
/// ❌ Do not turn [expandable] on for a card that opens a detail on tap, a
///    pick list, a sheet, a detail screen, an input, a notification text or
///    an option name (D22, D23, D24, D26).
class NameText extends StatefulWidget {
  final String? name;
  final NameKind kind;
  final String emptyText;
  final bool expandable;
  final TextStyle? style;
  final bool noTruncate;

  const NameText({
    required this.name,
    required this.kind,
    super.key,
    this.emptyText = '-',
    this.expandable = false,
    this.style,
    this.noTruncate = false,
  });

  @override
  State<NameText> createState() => _NameTextState();
}

class _NameTextState extends State<NameText> {
  final ValueNotifier<bool> _expanded = ValueNotifier<bool>(false);

  int get _maxLines {
    switch (widget.kind) {
      case NameKind.product:
        return 2;
      case NameKind.customer:
        return 1;
    }
  }

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  Widget _truncated(String text) => Text(
        text,
        style: widget.style,
        maxLines: _maxLines,
        overflow: TextOverflow.ellipsis,
      );

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    if (name == null || name.trim().isEmpty) {
      if (widget.noTruncate) {
        return Text(widget.emptyText, style: widget.style);
      }
      return _truncated(widget.emptyText);
    }
    if (widget.noTruncate) {
      return Text(name, style: widget.style);
    }
    if (!widget.expandable) {
      return _truncated(name);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _expanded.value = !_expanded.value,
      child: ValueListenableBuilder<bool>(
        valueListenable: _expanded,
        builder: (context, expanded, _) =>
            expanded ? Text(name, style: widget.style) : _truncated(name),
      ),
    );
  }
}
