import 'package:flutter/material.dart';

/// Search field of the list-page search areas (FEATURE_2610_03 · D136).
///
/// **Purpose**: one shape for the text search field at the top of a list
/// page — height 40, 🔍 in front (no tap action), no label, the hint always
/// visible, ✕ to clear while there is text. An optional [leading] (the search
/// target box of the order pages — D131 ①) sits inside the same border, left
/// of the 🔍, with a thin line between them.
/// **File**: lib/shared/widgets/app_search_field.dart
///
/// **Usage**:
/// ```dart
/// // Filter while typing.
/// AppSearchField(
///   controller: _searchController,
///   hintText: '판매자명 검색...',
///   onChanged: (value) => bloc.add(SearchSellers(query: value)),
/// )
///
/// // Commit with the keyboard search key only.
/// AppSearchField(
///   controller: _searchController,
///   hintText: '이름 · 상품ID · 옵션ID',
///   textInputAction: TextInputAction.search,
///   onSubmitted: (_) => _search(),
/// )
/// ```
///
/// ⚠️ ✕ clears the text and calls [onChanged] with '' — the same as erasing
///    the text by typing.
/// ⚠️ The page keeps deciding when the server is called (D134): pass the
///    `onChanged` / `onSubmitted` / `textInputAction` the page already had.
/// ❌ Only for the search areas at the top of list pages (D130). Inputs in
///    forms, sheets, dialogs and master sections keep the theme input.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? leading;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppSearchField({
    required this.controller,
    required this.hintText,
    super.key,
    this.leading,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        enabled: enabled,
        textInputAction: textInputAction,
        textAlignVertical: TextAlignVertical.center,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          constraints: const BoxConstraints.tightFor(height: 40),
          contentPadding: const EdgeInsets.only(right: 12),
          hintText: hintText,
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                Container(
                  width: 1,
                  height: 24,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.search, size: 18),
              ),
            ],
          ),
          prefixIconConstraints: const BoxConstraints(minHeight: 40),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '검색어 지우기',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: enabled ? _clear : null,
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
      ),
    );
  }

  void _clear() {
    controller.clear();
    onChanged?.call('');
  }
}
