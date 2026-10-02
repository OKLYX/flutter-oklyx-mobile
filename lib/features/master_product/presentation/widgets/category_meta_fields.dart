import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/basic_unit.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/measure_attributes.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/notice_templates.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';

const String _groupEtc = '기타';

// Group notices by groupName, first-seen order; null → 기타 (always last).
List<MapEntry<String, List<CategoryNotice>>> _groupNotices(
    List<CategoryNotice> notices) {
  final map = <String, List<CategoryNotice>>{};
  for (final n in notices) {
    map.putIfAbsent(n.groupName ?? _groupEtc, () => []).add(n);
  }
  final entries = map.entries.toList();
  return [
    ...entries.where((e) => e.key != _groupEtc),
    ...entries.where((e) => e.key == _groupEtc),
  ];
}

/// Category required attributes / product-info notice inputs — render only
/// (no fetch/save). Port of web
/// `app/dashboard/master-products/[id]/components/CategoryMetaFields.tsx`
/// (@09208a0).
///
/// **Purpose**: the parent (detail container or create form) owns
/// [attrValues]/[noticeValues] and receives every edit through the callbacks.
/// Master-owned fields only (option-owned volume/weight/quantity are edited
/// per option). Weight/volume pairs render as "axis pick + one value".
/// Validation lives in `logic/category_meta_validation.dart`, not here.
/// **File**: lib/features/master_product/presentation/widgets/category_meta_fields.dart
///
/// **Usage**:
/// ```dart
/// CategoryMetaFields(
///   attributes: _attrs, notices: _notices,
///   attrValues: _attrValues, noticeValues: _noticeValues,
///   onAttrChange: (name, v) => setState(() => _attrValues = {..._attrValues, name: v}),
///   onNoticeChange: (key, v) => setState(() => _noticeValues = {..._noticeValues, key: v}),
///   onNoticeValuesChange: (next) => setState(() => _noticeValues = next),
///   onMeasureUnit: _clearOtherSide,
///   onlyRequired: _onlyRequired,
///   onOnlyRequiredChange: (v) => setState(() => _onlyRequired = v),
///   noticeGroup: _group, onNoticeGroupChange: (g) => setState(() => _group = g),
/// )
/// ```
///
/// ⚠️ [onMeasureUnit] must clear the other side's value in the parent.
/// ❌ Do not add a save button or validation here.
class CategoryMetaFields extends StatefulWidget {
  final List<CategoryAttribute> attributes;
  final List<CategoryNotice> notices;
  final Map<String, String> attrValues;
  final Map<String, String> noticeValues;
  final void Function(String name, String value) onAttrChange;
  final void Function(String key, String value) onNoticeChange;

  /// Bulk replace of the notice map ("전체 상세페이지 참조").
  final ValueChanged<Map<String, String>> onNoticeValuesChange;
  final void Function(MeasurePair pair, String unit) onMeasureUnit;
  final bool onlyRequired;
  final ValueChanged<bool> onOnlyRequiredChange;
  final bool disabled;

  /// No selected channel requires category attributes → hide the attribute
  /// part (values kept).
  final bool hideCategoryAttrs;

  /// Selected notice group; null = the effective group.
  final String? noticeGroup;
  final ValueChanged<String>? onNoticeGroupChange;

  const CategoryMetaFields({
    required this.attributes,
    required this.notices,
    required this.attrValues,
    required this.noticeValues,
    required this.onAttrChange,
    required this.onNoticeChange,
    required this.onNoticeValuesChange,
    required this.onMeasureUnit,
    required this.onlyRequired,
    required this.onOnlyRequiredChange,
    super.key,
    this.disabled = false,
    this.hideCategoryAttrs = false,
    this.noticeGroup,
    this.onNoticeGroupChange,
  });

  @override
  State<CategoryMetaFields> createState() => _CategoryMetaFieldsState();
}

class _CategoryMetaFieldsState extends State<CategoryMetaFields> {
  // Display-only unit pick per pair; the value lives in the parent.
  final Map<String, String> _measureUnit = {};

  // Explicit choice wins, else inferred from existing values.
  String _unitOf(MeasurePair p) =>
      _measureUnit[p.base] ?? derivedUnit(p, widget.attrValues);

  void _pickMeasureUnit(MeasurePair p, String unit) {
    setState(() => _measureUnit[p.base] = unit);
    widget.onMeasureUnit(p, unit);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = widget.disabled;
    final noticeValues = widget.noticeValues;

    final masterAttributes =
        widget.attributes.where((a) => !isOptionField(a.name)).toList();
    final masterNotices =
        widget.notices.where((n) => !isOptionNotice(n)).toList();
    final noticeGroupNames = noticeGroupsOf(masterNotices);
    final activeNoticeGroup =
        resolveNoticeGroup(masterNotices, noticeValues, widget.noticeGroup);
    final activeGroupNotices = masterNotices
        .where((n) => noticeGroupName(n) == activeNoticeGroup)
        .toList();
    final refAll = isNoticeRefAll(activeGroupNotices, noticeValues);
    final paired = pairMeasureAttributes(masterAttributes);
    final pairs = paired.pairs;
    final singles = paired.singles;

    final requiredCount = (widget.hideCategoryAttrs
            ? 0
            : singles.where((a) => a.required).length +
                pairs.where(isPairRequired).length) +
        activeGroupNotices.where((n) => n.required).length;
    final visibleSingles = widget.onlyRequired
        ? singles.where((a) => a.required).toList()
        : singles;
    final visiblePairs =
        widget.onlyRequired ? pairs.where(isPairRequired).toList() : pairs;
    final visibleNotices = widget.onlyRequired
        ? activeGroupNotices.where((n) => n.required).toList()
        : activeGroupNotices;
    final noticeGroups = _groupNotices(visibleNotices);

    final grayBoxText = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리 필수속성 / 상품정보제공고시',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        CheckboxListTile(
          value: widget.onlyRequired,
          onChanged: (v) => widget.onOnlyRequiredChange(v ?? false),
          title: Text.rich(
            TextSpan(
              text: '필수 항목만 보기',
              children: [
                if (requiredCount > 0)
                  TextSpan(
                    text: '($requiredCount)',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        if (widget.hideCategoryAttrs)
          _grayBox(
            context,
            Text(
              '혼합구성(여러 상품) 상품은 쿠팡에 수량/용량/중량 등 속성을 보내지 않습니다(옵션명으로 표현).',
              style: grayBoxText,
            ),
          )
        else if (visibleSingles.isNotEmpty || visiblePairs.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in visiblePairs) ...[
                _buildPair(context, p),
                const SizedBox(height: 12),
              ],
              for (final a in visibleSingles) ...[
                _buildSingle(context, a),
                const SizedBox(height: 12),
              ],
            ],
          ),
        const SizedBox(height: 4),
        Divider(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: 12),
        const Text(
          '상품정보제공고시',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        if (noticeGroupNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          _select(
            context,
            fieldKey: 'notice-group-$activeNoticeGroup',
            value: activeNoticeGroup,
            items: [for (final g in noticeGroupNames) (g, g)],
            onChanged: disabled || widget.onNoticeGroupChange == null
                ? null
                : (v) => widget.onNoticeGroupChange!(v),
          ),
        ],
        if (activeGroupNotices.isNotEmpty)
          CheckboxListTile(
            value: refAll,
            onChanged: disabled
                ? null
                : (v) => widget.onNoticeValuesChange(applyNoticeRefAll(
                    activeGroupNotices, noticeValues, v ?? false)),
            title: const Text('전체 상품 상세페이지 참조', style: TextStyle(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: 12),
        if (masterNotices.isEmpty)
          _grayBox(
            context,
            Text('이 카테고리에는 입력할 상품정보제공고시 항목이 없습니다.', style: grayBoxText),
          )
        else if (noticeGroups.isEmpty)
          _grayBox(
            context,
            Text(
              '이 품목군에는 필수 항목이 없습니다. 「필수 항목만 보기」를 끄면 선택 항목을 입력할 수 있습니다.',
              style: grayBoxText,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in noticeGroups) ...[
                Text(
                  group.key,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (final n in group.value) ...[
                  _MetaTextField(
                    key: ValueKey('notice-${n.key}'),
                    label: _fieldLabel(context, n.label, required: n.required),
                    value: noticeValues[n.key] ?? '',
                    enabled: !disabled && !refAll,
                    onChanged: (v) => widget.onNoticeChange(n.key, v),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildPair(BuildContext context, MeasurePair p) {
    final scheme = Theme.of(context).colorScheme;
    final unit = _unitOf(p);
    final activeName = unit == '용량' ? p.volume.name : p.weight.name;
    // Unselected → null (no weight fallback for the unit hint).
    final activeAttr = unit == '용량'
        ? p.volume
        : unit == '중량'
            ? p.weight
            : null;
    final unitHint = unitPlaceholder(activeAttr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: p.base.isNotEmpty ? p.base : '중량/용량',
            children: [
              if (isPairRequired(p))
                TextSpan(text: ' *', style: TextStyle(color: scheme.error)),
              TextSpan(
                text: ' (중량·용량 중 택1)',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 96,
              child: _select(
                context,
                fieldKey: 'pair-${p.base}-$unit',
                value: unit,
                items: const [('', '구분'), ('중량', '중량'), ('용량', '용량')],
                onChanged:
                    widget.disabled ? null : (v) => _pickMeasureUnit(p, v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetaTextField(
                key: ValueKey('pair-value-${p.base}'),
                value: unit.isNotEmpty
                    ? (widget.attrValues[activeName] ?? '')
                    : '',
                enabled: !widget.disabled && unit.isNotEmpty,
                hintText: unit.isNotEmpty
                    ? (unitHint.isNotEmpty ? unitHint : '값 입력')
                    : '구분 먼저 선택',
                onChanged: (v) => widget.onAttrChange(activeName, v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingle(BuildContext context, CategoryAttribute a) {
    final scheme = Theme.of(context).colorScheme;
    final suffix = unitSuffix(a);
    final current = widget.attrValues[a.name] ?? '';
    final hint = unitPlaceholder(a);
    final label = Text.rich(
      TextSpan(
        text: a.name,
        children: [
          if (suffix.isNotEmpty)
            TextSpan(
              text: ' $suffix',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (a.required)
            TextSpan(text: ' *', style: TextStyle(color: scheme.error)),
        ],
      ),
    );
    if (a.inputType == 'SELECT') {
      return _select(
        context,
        label: label,
        fieldKey: 'attr-${a.name}-$current',
        value: a.options.contains(current) ? current : '',
        items: [('', '선택'), for (final o in a.options) (o, o)],
        onChanged:
            widget.disabled ? null : (v) => widget.onAttrChange(a.name, v),
      );
    }
    return _MetaTextField(
      key: ValueKey('attr-${a.name}'),
      label: label,
      value: current,
      enabled: !widget.disabled,
      keyboardType: a.inputType == 'NUMBER'
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      hintText: hint.isNotEmpty ? hint : null,
      onChanged: (v) => widget.onAttrChange(a.name, v),
    );
  }
}

Widget _fieldLabel(BuildContext context, String text,
    {required bool required}) {
  final scheme = Theme.of(context).colorScheme;
  return Text.rich(
    TextSpan(
      text: text,
      children: [
        if (required)
          TextSpan(text: ' *', style: TextStyle(color: scheme.error)),
      ],
    ),
  );
}

Widget _grayBox(BuildContext context, Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );

// Web `<select>` (R8). [fieldKey] must change with [value] so the form field
// re-reads its initial value when the parent changes it.
Widget _select(
  BuildContext context, {
  required String fieldKey,
  required String value,
  required List<(String, String)> items,
  required ValueChanged<String>? onChanged,
  Widget? label,
}) =>
    DropdownButtonFormField<String>(
      key: ValueKey(fieldKey),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        label: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: TextStyle(
          fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item.$1, child: Text(item.$2)),
      ],
      onChanged: onChanged == null
          ? null
          : (v) {
              if (v != null) {
                onChanged(v);
              }
            },
    );

// Text input whose value is owned by the parent (R22): the controller syncs
// from [value] only when they differ, keeping cursor and IME composition.
class _MetaTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? hintText;
  final Widget? label;
  final TextInputType? keyboardType;

  const _MetaTextField({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.hintText,
    this.label,
    this.keyboardType,
  });

  @override
  State<_MetaTextField> createState() => _MetaTextFieldState();
}

class _MetaTextFieldState extends State<_MetaTextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant _MetaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          label: widget.label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          hintText: widget.hintText,
        ),
        onChanged: widget.onChanged,
      );
}
