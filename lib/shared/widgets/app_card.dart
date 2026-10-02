import 'package:flutter/material.dart';

/// Card used by every page (FEATURE_2610_02 · N2 / N3).
///
/// **Purpose**: one card shape — outer margin 0 (cards sit 16 from the screen
/// edge, the page padding) and a fixed inner padding.
/// **File**: lib/shared/widgets/app_card.dart
///
/// **Usage**:
/// ```dart
/// // Search box / info card — inner padding 16.
/// AppCard(child: Column(children: [...]))
///
/// // One row of a page's main list — inner padding 12, tap to open.
/// AppCard.row(onTap: _open, child: Row(children: [...]))
///
/// // Card whose content draws edge to edge (tab bar, dividers) — the content
/// // keeps its own padding.
/// AppCard.flush(child: Column(children: [...]))
/// ```
///
/// ⚠️ Cards have no outer margin — put `const SizedBox(height: 8)` between two
///    cards (list rows: `separatorBuilder`).
/// ❌ Do not pass a custom padding — the three constructors are the only values.
/// ❌ Rows inside a sheet, dialog or section are not page list rows — leave
///    them as they are.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const AppCard({required this.child, super.key})
      : padding = const EdgeInsets.all(16),
        onTap = null;

  const AppCard.row({required this.child, super.key, this.onTap})
      : padding = const EdgeInsets.all(12);

  const AppCard.flush({required this.child, super.key})
      : padding = EdgeInsets.zero,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
