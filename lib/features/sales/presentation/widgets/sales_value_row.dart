import 'package:flutter/material.dart';

/// One 「label · value」 line of the 「매출」 cards (FEATURE_2610_20 / D26) — the
/// mobile form of one web table cell. [hint] = the web cell `title`, shown on
/// long press.
class SalesValueRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final String? hint;
  final bool bold;
  final Color? valueColor;

  const SalesValueRow({
    required this.label,
    required this.value,
    super.key,
    this.sub,
    this.hint,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
        fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                if (sub != null) Text(sub!, style: muted),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
    final message = hint;
    return message == null ? row : Tooltip(message: message, child: row);
  }
}
