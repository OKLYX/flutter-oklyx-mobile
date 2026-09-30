// Pure required-field validation shared by the detail save gate and the
// create submit gate — port of web
// `app/dashboard/master-products/[id]/components/categoryMetaValidation.ts`
// (@09208a0).
// File: lib/features/master_product/presentation/logic/category_meta_validation.dart
//
// Option-owned physical fields are excluded from the master gate and
// validated per option only.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/measure_attributes.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/notice_templates.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';

bool _pairFilled(MeasurePair p, Map<String, String> values) {
  final u = derivedUnit(p, values);
  final name = u == '용량'
      ? p.volume.name
      : u == '중량'
          ? p.weight.name
          : '';
  return name.isNotEmpty && (values[name] ?? '').trim().isNotEmpty;
}

/// True when any MASTER-owned required field is still missing. A
/// weight/volume pair is satisfied by the chosen side (one-of).
bool computeMissingRequired(
  List<CategoryAttribute> attributes,
  Map<String, String> attrValues,
  List<CategoryNotice> notices,
  Map<String, String> noticeValues, [
  // Web signature: positional optional boolean.
  // ignore: avoid_positional_boolean_parameters
  bool hideCategoryAttrs = false,
  String? noticeGroup,
]) {
  final masterAttributes =
      attributes.where((a) => !isOptionField(a.name)).toList();
  final paired = pairMeasureAttributes(masterAttributes);
  final masterNotices = notices.where((n) => !isOptionNotice(n)).toList();
  final group = resolveNoticeGroup(masterNotices, noticeValues, noticeGroup);
  final groupNotices =
      masterNotices.where((n) => noticeGroupName(n) == group).toList();
  final refAll = isNoticeRefAll(groupNotices, noticeValues);
  final missingAttr = !hideCategoryAttrs &&
      (paired.singles.any(
              (a) => a.required && (attrValues[a.name] ?? '').trim().isEmpty) ||
          paired.pairs
              .any((p) => isPairRequired(p) && !_pairFilled(p, attrValues)));
  return missingAttr ||
      (!refAll &&
          groupNotices.any(
              (n) => n.required && (noticeValues[n.key] ?? '').trim().isEmpty));
}

/// The notice group actually sent on save (effective group, fallbacks
/// applied). ⚠️ May be `''` for schemas without groups.
String submitNoticeGroup(
  List<CategoryNotice> notices,
  Map<String, String> noticeValues,
  String? noticeGroup,
) =>
    resolveNoticeGroup(
      notices.where((n) => !isOptionNotice(n)).toList(),
      noticeValues,
      noticeGroup,
    );

/// Notices to save/send = the selected group's master-owned notices only.
Map<String, String> noticesToSubmit(
  List<CategoryNotice> notices,
  Map<String, String> noticeValues,
  String? noticeGroup,
) {
  final masterNotices = notices.where((n) => !isOptionNotice(n)).toList();
  final group = submitNoticeGroup(notices, noticeValues, noticeGroup);
  return noticesForGroup(masterNotices, noticeValues, group);
}

/// Web `noticeCtx` object of [computeMissingOptionRequired]. Named fields so
/// the two value maps cannot be swapped by position.
class OptionNoticeCtx {
  final List<CategoryNotice> notices;
  final Map<String, String> optNoticeValues;

  /// Blank option value = inherit → a master value also satisfies.
  final Map<String, String>? masterNoticeValues;

  /// Effective group ([submitNoticeGroup] result).
  final String? noticeGroup;

  const OptionNoticeCtx({
    required this.notices,
    required this.optNoticeValues,
    required this.noticeGroup,
    this.masterNoticeValues,
  });
}

/// True when a schema-required OPTION-owned attribute or notice is still
/// missing for this option. ⚠️ [hideCategoryAttrs] skips attributes only —
/// notices are still validated.
bool computeMissingOptionRequired(
  List<CategoryAttribute> attributes,
  Map<String, String> optAttrValues, [
  // Web signature: positional optional boolean.
  // ignore: avoid_positional_boolean_parameters
  bool hideCategoryAttrs = false,
  OptionNoticeCtx? noticeCtx,
]) {
  final optionAttributes =
      attributes.where((a) => isOptionField(a.name)).toList();
  final paired = pairMeasureAttributes(optionAttributes);
  final missingAttrs = !hideCategoryAttrs &&
      (paired.singles.any((a) =>
              a.required && (optAttrValues[a.name] ?? '').trim().isEmpty) ||
          paired.pairs
              .any((p) => isPairRequired(p) && !_pairFilled(p, optAttrValues)));
  final missingNotices = noticeCtx != null &&
      noticeCtx.notices
          .where(isOptionNotice)
          .where((n) =>
              (noticeCtx.noticeGroup ?? '').isEmpty ||
              noticeGroupName(n) == noticeCtx.noticeGroup)
          .any((n) =>
              n.required &&
              (noticeCtx.optNoticeValues[n.key] ?? '').trim().isEmpty &&
              // ⚠️ Master fallback is required (diffOverride drops values
              // equal to the master).
              ((noticeCtx.masterNoticeValues ?? const {})[n.key] ?? '')
                  .trim()
                  .isEmpty);
  return missingAttrs || missingNotices;
}
