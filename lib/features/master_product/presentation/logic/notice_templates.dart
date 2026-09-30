// Product-info notice helpers ("상세페이지 참조" + notice group selection) —
// port of web `app/dashboard/master-products/[id]/components/noticeTemplates.ts`
// (@09208a0).
// File: lib/features/master_product/presentation/logic/notice_templates.dart
//
// Notice fields come from the backend `CategoryNotice` list; the value map is
// keyed by `notice.key`.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';

/// Web `NOTICE_REF_TEXT` — value used by "전체 상품 상세페이지 참조".
const String kNoticeRefText = '상품 상세페이지 참조';

/// Every notice value equals the reference text. Empty list → false.
bool isNoticeRefAll(List<CategoryNotice> notices, Map<String, String> values) =>
    notices.isNotEmpty && notices.every((n) => values[n.key] == kNoticeRefText);

/// A copy with every notice filled with the reference text ([checked]) or
/// cleared.
Map<String, String> applyNoticeRefAll(
  List<CategoryNotice> notices,
  Map<String, String> values,
  // Web signature: positional boolean.
  // ignore: avoid_positional_boolean_parameters
  bool checked,
) {
  final next = {...values};
  for (final n in notices) {
    next[n.key] = checked ? kNoticeRefText : '';
  }
  return next;
}

/// When none of [notices] has a value, fills them all with the reference
/// text; otherwise returns [values] unchanged.
Map<String, String> defaultNoticeRefAll(
  List<CategoryNotice> notices,
  Map<String, String> values,
) {
  final anyFilled = notices.any((n) => (values[n.key] ?? '').trim() != '');
  return anyFilled || notices.isEmpty
      ? values
      : applyNoticeRefAll(notices, values, true);
}

/// Web `NOTICE_GROUP_ETC` — a null groupName normalizes to this.
const String kNoticeGroupEtc = '기타';

/// Group name of a notice (null → [kNoticeGroupEtc]).
String noticeGroupName(CategoryNotice n) => n.groupName ?? kNoticeGroupEtc;

/// Distinct groups in first-seen order, [kNoticeGroupEtc] always last.
List<String> noticeGroupsOf(List<CategoryNotice> notices) {
  final seen = <String>[];
  for (final n in notices) {
    final g = noticeGroupName(n);
    if (!seen.contains(g)) {
      seen.add(g);
    }
  }
  // Web stable sort that only pushes 기타 to the end.
  return [
    ...seen.where((g) => g != kNoticeGroupEtc),
    ...seen.where((g) => g == kNoticeGroupEtc),
  ];
}

/// Effective group: ① [selected] if still valid → ② the group with the most
/// filled values (ties = earlier group) → ③ the first group. `''` when none.
String resolveNoticeGroup(
  List<CategoryNotice> notices,
  Map<String, String> values,
  String? selected,
) {
  final groups = noticeGroupsOf(notices);
  if (selected != null && groups.contains(selected)) {
    return selected;
  }
  int filledCount(String g) => notices
      .where(
          (n) => noticeGroupName(n) == g && (values[n.key] ?? '').trim() != '')
      .length;
  var best = '';
  var bestCount = 0;
  for (final g in groups) {
    final c = filledCount(g);
    if (c > bestCount) {
      best = g;
      bestCount = c;
    }
  }
  return bestCount > 0 ? best : (groups.isEmpty ? '' : groups[0]);
}

/// Key/value map of the selected group's notices only (keys absent from
/// [values] are skipped).
Map<String, String> noticesForGroup(
  List<CategoryNotice> notices,
  Map<String, String> values,
  String group,
) {
  final out = <String, String>{};
  for (final n in notices) {
    if (noticeGroupName(n) == group && values.containsKey(n.key)) {
      out[n.key] = values[n.key]!;
    }
  }
  return out;
}
