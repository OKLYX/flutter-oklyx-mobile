// Coupang required choice groups (`groupNumber`) — port of web
// `app/dashboard/master-products/[id]/components/choiceGroups.ts`
// (FEATURE_2611_08).
// File: lib/features/master_product/presentation/logic/choice_groups.dart
//
// The only place that computes choice groups and their guide texts. The
// save gates (`category_meta_validation.dart`) and both field widgets
// (`category_meta_fields.dart` · `category_meta_override_fields.dart`) call
// this. Rule = same as the server
// (`CoupangListingAdapter.validateRegistrable`): required attributes sharing
// one group number are satisfied by any one of them; a required attribute
// without a group number is required on its own. Optional attributes never
// join a group.
//
// Usage:
//   final groups = requiredChoiceGroups(attributes);
//   final missing = groups.any(
//       (g) => !isOptionGroup(g) && !isGroupFilled(g, (n) => values[n] ?? ''));
//   Text(choiceGroupGuide(groups.first));
//
// ❌ Do not infer groups from attribute names — only the Coupang group number
//    decides membership.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';

/// Web `ChoiceGroup`. [members] = the REQUIRED attributes with this number,
/// in schema order.
class ChoiceGroup {
  final String groupNumber;
  final List<CategoryAttribute> members;

  const ChoiceGroup({required this.groupNumber, required this.members});
}

/// The trimmed group number of a required attribute, `''` otherwise.
String requiredGroupNumber(CategoryAttribute a) =>
    a.required ? (a.groupNumber ?? '').trim() : '';

/// Required attributes grouped by number. Group order = order of each
/// group's first member in the schema.
List<ChoiceGroup> requiredChoiceGroups(List<CategoryAttribute> attributes) {
  final byNumber = <String, List<CategoryAttribute>>{};
  for (final a in attributes) {
    final number = requiredGroupNumber(a);
    if (number.isEmpty) {
      continue;
    }
    byNumber.putIfAbsent(number, () => []).add(a);
  }
  return [
    for (final e in byNumber.entries)
      ChoiceGroup(groupNumber: e.key, members: e.value),
  ];
}

/// Any member is option-owned → validated by the option gate only.
bool isOptionGroup(ChoiceGroup g) =>
    g.members.any((m) => isOptionField(m.name));

/// Any member has a non-empty value ([valueOf] returns the trimmed value).
bool isGroupFilled(ChoiceGroup g, String Function(String name) valueOf) =>
    g.members.any((m) => valueOf(m.name).isNotEmpty);

/// Guide line above a group box. In an option group, master-owned members
/// get the `(상품 기본 정보)` suffix.
String choiceGroupGuide(ChoiceGroup g) {
  final optionGroup = isOptionGroup(g);
  final names = g.members
      .map((m) => optionGroup && !isOptionField(m.name)
          ? '${m.name}(상품 기본 정보)'
          : m.name)
      .toList();
  return '${names.join(' · ')} 중 하나만 넣으면 됩니다';
}

/// Note under a master-owned member of an option group.
String optionGroupMasterNote(ChoiceGroup g) {
  final names =
      g.members.where((m) => isOptionField(m.name)).map((m) => m.name).toList();
  return '옵션에서 ${names.join(' · ')}을 넣으면 비워도 됩니다';
}
