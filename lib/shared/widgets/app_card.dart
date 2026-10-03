import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';

/// Card shape of the whole app (FEATURE_2610_03 · D126 · D128).
///
/// One value picked in code — not a user setting, a server value or a build
/// option. Change this line and rebuild to compare the two shapes.
const AppCardStyle kAppCardStyle = AppCardStyle.flat;

/// The two card shapes [kAppCardStyle] can pick.
enum AppCardStyle {
  /// Card 16 from the screen edge with the card theme corners and shadow,
  /// 8 of space between list rows.
  floating,

  /// Card drawn to both screen edges with square corners and no shadow, one
  /// divider line between list rows, darker page background (D127 · D129).
  flat,
}

/// Card used by every page (FEATURE_2610_02 · N2 / N3 · FEATURE_2610_03 · D126).
///
/// **Purpose**: one card shape — outer margin 0 and a fixed inner padding.
/// The shape follows [kAppCardStyle]:
/// - `floating`: the card sits inside the page padding (16 from the screen
///   edge) with the card theme corners and shadow.
/// - `flat`: a card exactly as wide as the page body
///   ([AppPageBody.contentWidthOf]) grows 16 on each side to the screen edges,
///   with square corners and no shadow. A narrower card (several in a row,
///   inside another box) and a card outside a page body (sheet, dialog) keep
///   the `floating` shape (D127).
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
/// ⚠️ Cards have no outer margin. Between two rows of a page's main list put
///    `const AppRowGap()` (lists: `separatorBuilder`); between other cards keep
///    the gap the page already writes (D129 ③).
/// ⚠️ In `flat` the 16 a card grows on each side is drawn outside the page
///    body and does not take taps (D127).
/// ❌ Do not pass a custom padding — the three constructors are the only values.
/// ❌ Never write `Card(` in a page — the shape switch is read here only
///    (scripts/check_ui_rules.sh rule 7 · D140).
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
    final content = onTap == null ? body : InkWell(onTap: onTap, child: body);
    final floating = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    if (kAppCardStyle == AppCardStyle.floating) {
      return floating;
    }
    return _FullBleed(
      narrow: floating,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
        child: content,
      ),
    );
  }
}

/// Gap between two rows of a page's main list (FEATURE_2610_03 · D129 ①②).
///
/// **Purpose**: `floating` = 8 of empty space. `flat` = no space and one
/// divider line (thickness 1, `outlineVariant`) from screen edge to screen
/// edge.
/// **File**: lib/shared/widgets/app_card.dart
///
/// **Usage**:
/// ```dart
/// SliverList.separated(
///   itemCount: items.length,
///   itemBuilder: (context, i) => AppCard.row(child: Text(items[i].name)),
///   separatorBuilder: (_, __) => const AppRowGap(),
/// )
///
/// for (var i = 0; i < items.length; i++) ...[
///   if (i > 0) const AppRowGap(),
///   AppCard.row(child: Text(items[i].name)),
/// ]
/// ```
///
/// ❌ Not for the gap between other cards (search card ↔ list, info cards) —
///    keep the gap the page writes (D129 ③).
/// ❌ Not for rows inside a sheet, dialog or section (D107).
class AppRowGap extends StatelessWidget {
  const AppRowGap({super.key});

  @override
  Widget build(BuildContext context) {
    if (kAppCardStyle == AppCardStyle.floating) {
      return const SizedBox(height: 8);
    }
    final line = Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return _FullBleed(narrow: line, child: line);
  }
}

/// Draws [child] 16 wider on each side — to the screen edges — when it gets
/// exactly the page body width; otherwise draws [narrow] (D127 ②③).
class _FullBleed extends StatelessWidget {
  final Widget child;
  final Widget narrow;

  const _FullBleed({required this.child, required this.narrow});

  @override
  Widget build(BuildContext context) {
    final pageWidth = AppPageBody.contentWidthOf(context);
    if (pageWidth == null) {
      return narrow;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if ((constraints.maxWidth - pageWidth).abs() > 0.5) {
          return narrow;
        }
        // 16 + 16 = the left and right page padding of AppPageBody.insets.
        final width = pageWidth + 32;
        return OverflowBox(
          fit: OverflowBoxFit.deferToChild,
          minWidth: width,
          maxWidth: width,
          child: child,
        );
      },
    );
  }
}
