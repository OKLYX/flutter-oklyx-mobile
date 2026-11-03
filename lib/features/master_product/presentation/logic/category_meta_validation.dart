// Pure required-field validation shared by the detail save gate and the
// create submit gate — port of web
// `app/dashboard/master-products/[id]/components/categoryMetaValidation.ts`
// (@09208a0).
// File: lib/features/master_product/presentation/logic/category_meta_validation.dart
//
// Option-owned physical fields are excluded from the master gate and
// validated per option only. Required attributes sharing a Coupang group
// number (`choice_groups.dart`) are satisfied by any one member; a group with
// an option-owned member is validated by the option gate only
// (FEATURE_2611_08).
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/choice_groups.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/notice_templates.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';

/// True when any MASTER-owned required field is still missing. Required
/// attributes without a group number are each required; a choice group whose
/// members are all master-owned is satisfied by any one filled member. Groups
/// with an option-owned member are left to [computeMissingOptionRequired].
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
  final masterNotices = notices.where((n) => !isOptionNotice(n)).toList();
  final group = resolveNoticeGroup(masterNotices, noticeValues, noticeGroup);
  final groupNotices =
      masterNotices.where((n) => noticeGroupName(n) == group).toList();
  final refAll = isNoticeRefAll(groupNotices, noticeValues);
  String valueOf(String name) => (attrValues[name] ?? '').trim();
  final missingAttr = !hideCategoryAttrs &&
      (attributes.any((a) =>
              !isOptionField(a.name) &&
              a.required &&
              requiredGroupNumber(a).isEmpty &&
              valueOf(a.name).isEmpty) ||
          requiredChoiceGroups(attributes)
              .any((g) => !isOptionGroup(g) && !isGroupFilled(g, valueOf)));
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

/// Web `attrCtx` object of [computeMissingOptionRequired]. Named field so the
/// master attribute values cannot be swapped with the option values (same
/// map type) by position.
class OptionAttrCtx {
  /// Blank option value = inherit → a master value also satisfies.
  final Map<String, String> masterAttrValues;

  const OptionAttrCtx({required this.masterAttrValues});
}

/// True when a schema-required OPTION-owned attribute or notice is still
/// missing for this option. Each attribute is judged by its option value,
/// falling back to the master value when blank ([attrCtx]). Ungrouped
/// required option-owned attributes are each required; a choice group with
/// an option-owned member is satisfied by any one member, master-owned
/// members included. ⚠️ [hideCategoryAttrs] skips attributes only — notices
/// are still validated.
bool computeMissingOptionRequired(
  List<CategoryAttribute> attributes,
  Map<String, String> optAttrValues, [
  // Web signature: positional optional boolean.
  // ignore: avoid_positional_boolean_parameters
  bool hideCategoryAttrs = false,
  OptionNoticeCtx? noticeCtx,
  OptionAttrCtx? attrCtx,
]) {
  String valueOf(String name) {
    final own = (optAttrValues[name] ?? '').trim();
    if (own.isNotEmpty) {
      return own;
    }
    return ((attrCtx?.masterAttrValues ?? const {})[name] ?? '').trim();
  }

  final missingAttrs = !hideCategoryAttrs &&
      (attributes.any((a) =>
              isOptionField(a.name) &&
              a.required &&
              requiredGroupNumber(a).isEmpty &&
              valueOf(a.name).isEmpty) ||
          requiredChoiceGroups(attributes)
              .any((g) => isOptionGroup(g) && !isGroupFilled(g, valueOf)));
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
