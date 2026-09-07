import 'package:flutter/material.dart';

import '../../domain/entities/order_item.dart';

/// 칩 순서 고정 — 기존 둘은 자리를 지키고 새 둘을 뒤에 붙인다(PLAN 2609_27 D3).
const kOrderSearchFieldLabels = <OrderSearchField, String>{
  OrderSearchField.customer: '고객명',
  OrderSearchField.orderNo: '주문번호',
  OrderSearchField.product: '상품명',
  OrderSearchField.all: '전체',
};

/// hint 는 칩마다 바뀐다. 삼항 중첩 대신 맵 하나(PLAN 2609_27 D8).
const kOrderSearchHints = <OrderSearchField, String>{
  OrderSearchField.customer: '고객명 검색 (주문자·수취인)',
  OrderSearchField.orderNo: '주문번호 검색',
  OrderSearchField.product: '상품명 검색',
  OrderSearchField.all: '고객명·주문번호·상품명 검색',
};

/// 주문 검색 입력(대상 칩 4개 + 검색어 입력).
///
/// **용도**: 주문내역·출고관리 두 화면이 **같은**
/// 검색 UI 를 쓰기 위한 공용 위젯. 검색은 클라이언트 필터라 서버를 부르지 않는다.
/// **파일**: lib/features/order/presentation/widgets/order_search_bar.dart
///
/// **사용 예제**:
/// ```dart
/// OrderSearchBar(
///   controller: _searchController,
///   field: s.searchField,
///   term: s.searchTerm,
///   onFieldChanged: (f) => bloc.add(ChangeSearchField(field: f)),
///   onTermChanged: (t) => bloc.add(ChangeSearchTerm(term: t)),
/// )
/// ```
///
/// ⚠️ 판정은 `matchesOrderSearch`(도메인) 하나만 쓴다 — 화면에서 문자열 비교를 다시 만들지 말 것.
/// ⚠️ [controller] 는 화면(State)이 소유·dispose 한다. 위젯이 만들지 않는다.
/// ❌ 칩 목록·hint 를 화면마다 복사하지 말 것. 칩이 늘어나면 여기 한 곳만 고친다.
class OrderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final OrderSearchField field;
  final String term;
  final ValueChanged<OrderSearchField> onFieldChanged;
  final ValueChanged<String> onTermChanged;

  const OrderSearchBar({
    super.key,
    required this.controller,
    required this.field,
    required this.term,
    required this.onFieldChanged,
    required this.onTermChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: kOrderSearchFieldLabels.entries
                .map((e) => ChoiceChip(
                      label: Text(e.value),
                      selected: field == e.key,
                      onSelected: (_) => onFieldChanged(e.key),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onTermChanged,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search, size: 18),
            hintText: kOrderSearchHints[field],
            suffixIcon: term.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onTermChanged('');
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
