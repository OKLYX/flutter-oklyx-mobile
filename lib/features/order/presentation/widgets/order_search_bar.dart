import 'package:flutter/material.dart';

import '../../domain/entities/order_item.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';

/// Fixed order of the search targets — the first two keep their places and
/// the two added later come after them (PLAN 2609_27 D3).
const kOrderSearchFieldLabels = <OrderSearchField, String>{
  OrderSearchField.customer: '고객명',
  OrderSearchField.orderNo: '주문번호',
  OrderSearchField.product: '상품명',
  OrderSearchField.all: '전체',
};

/// The hint follows the picked search target. One map instead of nested
/// ternaries (PLAN 2609_27 D8).
const kOrderSearchHints = <OrderSearchField, String>{
  OrderSearchField.customer: '고객명 검색 (주문자·수취인)',
  OrderSearchField.orderNo: '주문번호 검색',
  OrderSearchField.product: '상품명 검색',
  OrderSearchField.all: '고객명·주문번호·상품명 검색',
};

/// Order search input — the search target box (▾) and the search text in one
/// field (FEATURE_2610_03 · D131 ①).
///
/// **Purpose**: the one search UI shared by 「주문내역」 and 「출고관리」. The
/// search is a client filter — it does not call the server.
/// **File**: lib/features/order/presentation/widgets/order_search_bar.dart
///
/// **Usage**:
/// ```dart
/// OrderSearchBar(
///   controller: _searchController,
///   field: s.searchField,
///   onFieldChanged: (f) => bloc.add(ChangeSearchField(field: f)),
///   onTermChanged: (t) => bloc.add(ChangeSearchTerm(term: t)),
/// )
/// ```
///
/// ⚠️ Matching uses `matchesOrderSearch` (domain) only — do not rebuild the
///    string comparison in a page.
/// ⚠️ [controller] is owned and disposed by the page (State); this widget
///    does not create it.
/// ❌ Do not copy the target list or the hints into pages. When a target is
///    added, change only this file.
class OrderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final OrderSearchField field;
  final ValueChanged<OrderSearchField> onFieldChanged;
  final ValueChanged<String> onTermChanged;

  const OrderSearchBar({
    super.key,
    required this.controller,
    required this.field,
    required this.onFieldChanged,
    required this.onTermChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: controller,
      hintText: kOrderSearchHints[field]!,
      onChanged: onTermChanged,
      leading: Builder(
        builder: (boxContext) => InkWell(
          onTap: () async {
            final picked = await showAppFilterMenu<OrderSearchField>(
              boxContext,
              value: field,
              options: [
                for (final e in kOrderSearchFieldLabels.entries)
                  AppFilterOption(e.key, e.value),
              ],
            );
            if (picked != null) {
              onFieldChanged(picked.value);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kOrderSearchFieldLabels[field]!,
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
