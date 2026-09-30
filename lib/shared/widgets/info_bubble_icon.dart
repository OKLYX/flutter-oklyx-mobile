import 'package:flutter/material.dart';

/// Mobile counterpart of the web hover-only hint (`title=`): tap the
/// exclamation icon to show a bubble (UX D30/D36).
///
/// **Purpose**: keeps the hint behind an icon and shows it for 5 s on tap.
/// **File**: lib/shared/widgets/info_bubble_icon.dart
///
/// **Usage**:
/// ```dart
/// Row(children: [const Text('마켓 등록 후 부여'), InfoBubbleIcon(message: hint)])
/// InfoBubbleIcon(message: reason, size: 14)
/// ```
///
/// ⚠️ Where the web also shows a decision hint as visible text (why a button
///    is disabled, why a value is empty), mobile shows that text too — the
///    icon never replaces it (D36).
/// ❌ Not for the name of an icon-only button (web `title="복사"`) — use
///    `IconButton.tooltip`.
/// ❌ Not for the full text of a truncated label (web `title={name}`) — mobile
///    renders the full text without truncation.
class InfoBubbleIcon extends StatelessWidget {
  final String message;
  final double size;

  const InfoBubbleIcon({required this.message, super.key, this.size = 16});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: message,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.error_outline,
            size: size,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
