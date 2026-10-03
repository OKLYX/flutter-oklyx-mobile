import 'package:flutter/material.dart';

/// Page body frame that owns the screen-edge padding of every page
/// (FEATURE_2610_02 · N1 / N1-2).
///
/// **Purpose**: left 16 · top 16 · right 16 · bottom = bottom nav height +
/// device bottom safe area + 24, computed here and nowhere else. The whole
/// body is one scroll — search rows, filter rows, tabs and action rows scroll
/// away together with the list. It also tells the widgets below it the page
/// content width ([contentWidthOf] — screen width − 16 − 16): in the `flat`
/// card shape a card of exactly that width grows to the screen edges
/// (FEATURE_2610_03 · D127).
/// **Rule**: the `body:` of every `ScaffoldWithNavBar` page is an
/// `AppPageBody` (the dashboard keeps its own body).
/// **File**: lib/shared/widgets/app_page_body.dart
///
/// **Usage**:
/// ```dart
/// // 1) Short pages — children are laid out full width, like `ListView`.
/// AppPageBody(children: [searchCard, const SizedBox(height: 12), ...rows])
///
/// // 2) Forms / detail pages that keep their own `Column`.
/// AppPageBody.scroll(child: Column(children: [...]))
///
/// // 3) Long lists — only visible rows are built.
/// AppPageBody.slivers(
///   controller: _scrollController,
///   slivers: [
///     SliverToBoxAdapter(child: searchCard),
///     SliverList.separated(
///       itemCount: items.length,
///       itemBuilder: (context, i) => AppCard.row(child: Text(items[i].name)),
///       separatorBuilder: (_, __) => const AppRowGap(),
///     ),
///   ],
/// )
/// ```
///
/// ⚠️ A bar pinned to the bottom of the screen sits above the nav bar with
///    `AppPageBody.navBarInset(context)`.
/// ⚠️ [extraBottom] is only for the keyboard height of the purchase list.
/// ❌ Never write `kBottomNavigationBarHeight` in a page.
/// ❌ Never pin a search row, filter row, tab row or action row above the
///    list — it goes inside this scroll.
class AppPageBody extends StatelessWidget {
  final List<Widget>? children;
  final Widget? child;
  final List<Widget>? slivers;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double extraBottom;

  const AppPageBody({
    required List<Widget> this.children,
    super.key,
    this.controller,
    this.physics,
    this.extraBottom = 0,
  })  : child = null,
        slivers = null;

  const AppPageBody.scroll({
    required Widget this.child,
    super.key,
    this.controller,
    this.physics,
    this.extraBottom = 0,
  })  : children = null,
        slivers = null;

  const AppPageBody.slivers({
    required List<Widget> this.slivers,
    super.key,
    this.controller,
    this.physics,
    this.extraBottom = 0,
  })  : children = null,
        child = null;

  /// Height covered by the overlaid bottom nav bar (+ device safe area).
  static double navBarInset(BuildContext context) =>
      kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom;

  /// Screen-edge padding of a page body.
  static EdgeInsets insets(BuildContext context, {double extraBottom = 0}) =>
      EdgeInsets.fromLTRB(16, 16, 16, navBarInset(context) + 24 + extraBottom);

  /// Page content width (body width − 16 − 16), or null outside a page body
  /// (sheet, dialog). Read by `AppCard` / `AppRowGap` (D127).
  static double? contentWidthOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_AppPageBodyScope>()
      ?.contentWidth;

  @override
  Widget build(BuildContext context) {
    final padding = insets(context, extraBottom: extraBottom);
    return LayoutBuilder(
      builder: (context, constraints) => _AppPageBodyScope(
        contentWidth: constraints.maxWidth - padding.horizontal,
        child: _scrollView(padding),
      ),
    );
  }

  Widget _scrollView(EdgeInsets padding) {
    final slivers = this.slivers;
    if (slivers != null) {
      return CustomScrollView(
        controller: controller,
        physics: physics,
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      );
    }
    final child = this.child;
    if (child != null) {
      return SingleChildScrollView(
        controller: controller,
        physics: physics,
        padding: padding,
        child: child,
      );
    }
    return ListView(
      controller: controller,
      physics: physics,
      padding: padding,
      children: children ?? const [],
    );
  }
}

/// Carries the page content width down to `AppCard` / `AppRowGap`.
class _AppPageBodyScope extends InheritedWidget {
  final double contentWidth;

  const _AppPageBodyScope({required this.contentWidth, required super.child});

  @override
  bool updateShouldNotify(_AppPageBodyScope oldWidget) =>
      contentWidth != oldWidget.contentWidth;
}
