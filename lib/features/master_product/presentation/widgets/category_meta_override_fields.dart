import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/basic_unit.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/measure_attributes.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/net_content_unit.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/notice_templates.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_notice_compose.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

// One attribute cell: a weight/volume pair (one-of) or a single attribute.
class _AttrCell {
  final MeasurePair? pair;
  final CategoryAttribute? single;

  const _AttrCell.pair(MeasurePair p)
      : pair = p,
        single = null;
  const _AttrCell.single(CategoryAttribute a)
      : pair = null,
        single = a;
}

/// Per-option category field inputs — render only. Port of web
/// `app/dashboard/master-products/[id]/components/CategoryMetaOverrideFields.tsx`
/// (@09208a0).
///
/// **Purpose**: renders only option-owned fields (per-unit volume/weight,
/// quantity) and the option-owned notices of the selected group. Required
/// fields always show; "상세입력" also shows the optional ones below them.
/// Measure values are entered as number + unit and stored joined (`320g`).
/// **File**: lib/features/master_product/presentation/widgets/category_meta_override_fields.dart
///
/// **Usage**:
/// ```dart
/// CategoryMetaOverrideFields(
///   attributes: _attrs, notices: _notices,
///   attrValues: _optAttrs, noticeValues: _optNotices,
///   onAttrChange: (name, v) => setState(() => _optAttrs = {..._optAttrs, name: v}),
///   onNoticeChange: (key, v) => setState(() => _optNotices = {..._optNotices, key: v}),
///   onMeasureUnit: _clearOtherSide,
///   noticeGroup: _effectiveGroup,
/// )
/// ```
///
/// ⚠️ Total-quantity attributes and auto-composed measure notices are
///    read-only here (filled from the component quantities).
/// ❌ No save button or validation here — the option form does both.
class CategoryMetaOverrideFields extends StatefulWidget {
  final List<CategoryAttribute> attributes;
  final List<CategoryNotice> notices;
  final Map<String, String> attrValues;
  final Map<String, String> noticeValues;
  final void Function(String name, String value) onAttrChange;
  final void Function(String key, String value) onNoticeChange;
  final void Function(MeasurePair pair, String unit) onMeasureUnit;
  final bool disabled;
  final bool hideCategoryAttrs;
  final String? noticeGroup;

  const CategoryMetaOverrideFields({
    required this.attributes,
    required this.notices,
    required this.attrValues,
    required this.noticeValues,
    required this.onAttrChange,
    required this.onNoticeChange,
    required this.onMeasureUnit,
    super.key,
    this.disabled = false,
    this.hideCategoryAttrs = false,
    this.noticeGroup,
  });

  @override
  State<CategoryMetaOverrideFields> createState() =>
      _CategoryMetaOverrideFieldsState();
}

class _CategoryMetaOverrideFieldsState
    extends State<CategoryMetaOverrideFields> {
  // Display-only unit pick per pair; the value lives in the parent.
  final Map<String, String> _measureUnit = {};
  // In-progress typing (`23.`) of a measure number field, display only.
  final Map<String, String> _amountDraft = {};
  // 상세입력: required only by default; checked = optional fields too.
  bool _showAll = false;

  String _unitOf(MeasurePair p) =>
      _measureUnit[p.base] ?? derivedUnit(p, widget.attrValues);

  void _pickMeasureUnit(MeasurePair p, String unit) {
    setState(() => _measureUnit[p.base] = unit);
    widget.onMeasureUnit(p, unit);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hide = widget.hideCategoryAttrs;

    final optionAttributes = hide
        ? <CategoryAttribute>[]
        : widget.attributes.where((a) => isOptionField(a.name)).toList();
    final paired = pairMeasureAttributes(optionAttributes);
    final pairs = paired.pairs;
    final singles = paired.singles;
    final requiredPairs = pairs.where(isPairRequired).toList();
    final optionalPairs = pairs.where((p) => !isPairRequired(p)).toList();
    final requiredSingles = singles.where((a) => a.required).toList();
    final optionalSingles = singles.where((a) => !a.required).toList();
    final allOptionNotices = widget.notices.where(isOptionNotice).toList();
    final group = widget.noticeGroup;
    final noticeFields = group != null && group.isNotEmpty
        ? allOptionNotices.where((n) => noticeGroupName(n) == group).toList()
        : allOptionNotices;
    final requiredNoticeFields = noticeFields.where((n) => n.required).toList();
    final optionalNoticeFields =
        noticeFields.where((n) => !n.required).toList();
    final visibleNoticeFields = _showAll ? noticeFields : requiredNoticeFields;

    final requiredCells = [
      for (final p in requiredPairs) _AttrCell.pair(p),
      for (final a in requiredSingles) _AttrCell.single(a),
    ];
    final optionalCells = _showAll
        ? [
            for (final p in optionalPairs) _AttrCell.pair(p),
            for (final a in optionalSingles) _AttrCell.single(a),
          ]
        : <_AttrCell>[];

    final hasNoticeFields = visibleNoticeFields.isNotEmpty;
    final autoMeasureNotice = !hide && hasMeasureAttr(widget.attributes);
    final hasAnyOption =
        pairs.isNotEmpty || singles.isNotEmpty || noticeFields.isNotEmpty;
    final hasOptional = optionalPairs.isNotEmpty ||
        optionalSingles.isNotEmpty ||
        optionalNoticeFields.isNotEmpty;

    final grayBoxText = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);
    final children = <Widget>[
      if (hide)
        _grayBox(
          context,
          Text(
            '혼합구성(여러 상품) 상품은 쿠팡에 수량/용량/중량 등 속성을 보내지 않습니다(옵션명으로 표현).',
            style: grayBoxText,
          ),
        ),
      if (hasOptional)
        CheckboxListTile(
          value: _showAll,
          onChanged: widget.disabled
              ? null
              : (v) => setState(() => _showAll = v ?? false),
          title: const Text('상세입력 (선택 항목 포함)', style: TextStyle(fontSize: 12)),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      if (requiredCells.isNotEmpty) _cellColumn(context, requiredCells),
      if (optionalCells.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              '상세 항목 (선택)',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _cellColumn(context, optionalCells),
          ],
        ),
      if (hasNoticeFields)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              '상품정보제공고시 (옵션 소유)',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < visibleNoticeFields.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildNotice(context, visibleNoticeFields[i], autoMeasureNotice),
            ],
          ],
        ),
      if (!hide && !hasAnyOption)
        _grayBox(
          context,
          Text('이 카테고리에는 옵션별로 설정할 항목이 없습니다.', style: grayBoxText),
        )
      else if (!hide &&
          !_showAll &&
          requiredCells.isEmpty &&
          requiredNoticeFields.isEmpty)
        _grayBox(
          context,
          Text('필수 항목이 없습니다. 상세입력을 체크하면 선택 항목이 표시됩니다.', style: grayBoxText),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          children[i],
        ],
      ],
    );
  }

  Widget _cellColumn(BuildContext context, List<_AttrCell> cells) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildCell(context, cells[i]),
          ],
        ],
      );

  Widget _buildNotice(
      BuildContext context, CategoryNotice n, bool autoMeasure) {
    final scheme = Theme.of(context).colorScheme;
    final auto = autoMeasure && isMeasureNotice(n.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetaTextField(
                key: ValueKey('notice-${n.key}'),
                label: Text.rich(
                  TextSpan(
                    text: n.label,
                    children: [
                      if (n.required)
                        TextSpan(
                            text: ' *', style: TextStyle(color: scheme.error)),
                      if (auto)
                        TextSpan(
                          text: ' (개당·수량에서 자동)',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                value: widget.noticeValues[n.key] ?? '',
                enabled: !widget.disabled && !auto,
                hintText: auto ? '개당 값을 입력하면 자동으로 채워집니다' : '값 입력',
                onChanged: (v) => widget.onNoticeChange(n.key, v),
              ),
            ),
            if (auto)
              const InfoBubbleIcon(
                message: '개당 용량/중량과 수량으로 자동 조합됩니다. 값을 바꾸려면 위 항목을 수정하세요.',
              ),
          ],
        ),
      ],
    );
  }

  // Number field + unit select; unsplittable legacy values fall back to raw
  // text so the screen never hides a stored value.
  List<Widget> _measureInput(
    BuildContext context,
    String name,
    String axis,
    CategoryAttribute? attr,
  ) {
    final raw = widget.attrValues[name] ?? '';
    final split = splitMeasured(raw);
    final units = kMeasureUnitsByAxis[axis] ?? const <String>[];
    if (!split.parsed) {
      return [
        Expanded(
          child: _MetaTextField(
            key: ValueKey('measure-raw-$name'),
            value: raw,
            enabled: !widget.disabled,
            onChanged: (v) => widget.onAttrChange(name, v),
          ),
        ),
        const InfoBubbleIcon(
          message: '숫자와 단위로 나눌 수 없는 값입니다. 숫자만 남기면 단위를 선택할 수 있습니다.',
        ),
      ];
    }
    // No unit in the value → the category base unit when it is in the list.
    final fallback = (attr?.basicUnit ?? '').trim().toLowerCase();
    final selected = split.unit.isNotEmpty
        ? split.unit
        : (units.contains(fallback) ? fallback : '');
    // The draft only counts while it is "same number + trailing dot".
    final draft = _amountDraft[name];
    final shownAmount = draft != null && normalizeAmount(draft) == split.amount
        ? draft
        : split.amount;
    return [
      Expanded(
        child: _MetaTextField(
          key: ValueKey('measure-amount-$name'),
          value: shownAmount,
          enabled: !widget.disabled,
          hintText: '숫자만 (예: 200, 23.9)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Anything but digits/decimal point is ignored (value kept).
          inputFormatters: [
            TextInputFormatter.withFunction(
              (oldValue, newValue) =>
                  isAmountInput(newValue.text) ? newValue : oldValue,
            ),
          ],
          onChanged: (next) {
            setState(() => _amountDraft[name] = next);
            widget.onAttrChange(
                name, joinMeasured(normalizeAmount(next), selected));
          },
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 80,
        child: _select(
          context,
          fieldKey: 'measure-unit-$name-$selected',
          value: units.contains(selected) ? selected : '',
          items: [('', '단위'), for (final u in units) (u, u)],
          onChanged: widget.disabled
              ? null
              : (v) => widget.onAttrChange(name, joinMeasured(split.amount, v)),
        ),
      ),
    ];
  }

  Widget _buildCell(BuildContext context, _AttrCell cell) {
    final scheme = Theme.of(context).colorScheme;
    final p = cell.pair;
    if (p != null) {
      final unit = _unitOf(p);
      final activeName = unit == '용량' ? p.volume.name : p.weight.name;
      final activeAttr = unit == '용량'
          ? p.volume
          : unit == '중량'
              ? p.weight
              : null;
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
              if (unit == '중량' || unit == '용량')
                ..._measureInput(context, activeName, unit, activeAttr)
              else
                const Expanded(
                  child: TextField(
                    enabled: false,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      hintText: '구분 먼저 선택',
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    final a = cell.single!;
    // Total quantity comes from the component quantities — read-only here.
    final autoQty = isTotalQuantityName(a.name);
    final suffix = unitSuffix(a);
    final current = widget.attrValues[a.name] ?? '';
    final axis = axisOfAttrName(a.name);
    final hint = unitPlaceholder(a);
    Widget control;
    if (a.inputType == 'SELECT') {
      control = _select(
        context,
        fieldKey: 'attr-${a.name}-$current',
        value: a.options.contains(current) ? current : '',
        items: [('', '선택'), for (final o in a.options) (o, o)],
        onChanged:
            widget.disabled ? null : (v) => widget.onAttrChange(a.name, v),
      );
    } else if (axis.isNotEmpty) {
      // An unpaired measure attribute also takes number + unit.
      control = Row(children: _measureInput(context, a.name, axis, a));
    } else {
      control = Row(
        children: [
          Expanded(
            child: _MetaTextField(
              key: ValueKey('attr-${a.name}'),
              value: current,
              enabled: !widget.disabled && !autoQty,
              keyboardType: a.inputType == 'NUMBER'
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : null,
              hintText: autoQty
                  ? '위 구성상품 수량에서 자동'
                  : (hint.isNotEmpty ? hint : '값 입력'),
              onChanged: (v) => widget.onAttrChange(a.name, v),
            ),
          ),
          if (autoQty)
            const InfoBubbleIcon(
              message: '구성상품 수량 합으로 자동 계산됩니다. 위 구성상품 수량을 수정하세요.',
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
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
              if (autoQty)
                TextSpan(
                  text: ' (구성상품 수량에서 자동)',
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
        control,
      ],
    );
  }
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

// Web `<select>` (R8). [fieldKey] changes with [value] so the form field
// re-reads its initial value when the parent changes it.
Widget _select(
  BuildContext context, {
  required String fieldKey,
  required String value,
  required List<(String, String)> items,
  required ValueChanged<String>? onChanged,
}) =>
    DropdownButtonFormField<String>(
      key: ValueKey(fieldKey),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
  final List<TextInputFormatter>? inputFormatters;

  const _MetaTextField({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.hintText,
    this.label,
    this.keyboardType,
    this.inputFormatters,
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
        inputFormatters: widget.inputFormatters,
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
