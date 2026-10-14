import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/elevenst_shipping.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/carrier_option.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/domain/usecases/shipping_label_usecase.dart';

/// 11st shipping fields — port of web `presentation/components/ElevenstShippingFields.tsx`
/// (FEATURE_2610_13 / D84 · D91 · D106), shared by the 11st channel default, the master and an 11st listing.
///
/// **Purpose**: the value is one string map of `elevenst.*` keys; the parent owns and saves it.
/// **File**: lib/features/master_product/presentation/widgets/elevenst_shipping_fields.dart
///
/// **Usage**:
/// ```dart
/// ElevenstShippingFields(level: ShippingOverrideLevel.account, value: _form,
///     onChanged: (next) => setState(() => _form = next), outbound: _outbound, returns: _returns)
/// ElevenstShippingFields(level: ShippingOverrideLevel.master, value: _elevenst,
///     onChanged: (next) => setState(() => _elevenst = next))
/// ElevenstShippingFields(level: ShippingOverrideLevel.listing, value: _form, onChanged: _set,
///     inherited: _baseline, outbound: _outbound, returns: _returns)
/// ```
///
/// ⚠️ A blank value = 「기본값 사용」 (master · listing). The account level is the base and inherits nothing.
/// ⚠️ The outbound and return/exchange addresses are 11st address numbers of one account — hidden on the master
///    level (D85).
/// ❌ Never mixed with the Coupang fields (`ShippingOverrideFields`) — there is no shared field (D105).
class ElevenstShippingFields extends StatefulWidget {
  final Map<String, String> value;
  final ValueChanged<Map<String, String>> onChanged;
  final ShippingOverrideLevel level;
  final bool disabled;
  final List<OutboundPlace> outbound;
  final List<ReturnCenter> returns;
  final bool placesLoading;

  /// Inherited baseline shown as 「기본값 사용 (현재: …)」 / hint on the master and listing levels.
  final Map<String, String>? inherited;

  const ElevenstShippingFields({
    required this.value,
    required this.onChanged,
    required this.level,
    super.key,
    this.disabled = false,
    this.outbound = const [],
    this.returns = const [],
    this.placesLoading = false,
    this.inherited,
  });

  @override
  State<ElevenstShippingFields> createState() => _ElevenstShippingFieldsState();
}

class _ElevenstShippingFieldsState extends State<ElevenstShippingFields> {
  List<CarrierOption> _carriers = const [];
  bool _carriersLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCarriers());
  }

  Future<void> _loadCarriers() async {
    final result = await getIt<ShippingLabelUseCase>()
        .getCarrierOptions(platform: 'ELEVENST');
    if (!mounted) {
      return;
    }
    setState(() {
      _carriers = result.fold((_) => const [], (options) => options);
      _carriersLoading = false;
    });
  }

  Map<String, String> get _base => widget.level == ShippingOverrideLevel.account
      ? const {}
      : (widget.inherited ?? const {});

  String _get(String key) => widget.value[key] ?? '';

  void _set(String key, String raw) {
    final next = Map<String, String>.of(widget.value);
    if (raw.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = raw;
    }
    widget.onChanged(next);
  }

  String? _labelOf(List<(String, String)> opts, String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }
    for (final o in opts) {
      if (o.$1 == code) {
        return o.$2;
      }
    }
    return code;
  }

  String _inheritOption(String? display) =>
      widget.level == ShippingOverrideLevel.account
          ? '선택하세요'
          : (display != null && display.isNotEmpty)
              ? '기본값 사용 (현재: $display)'
              : '기본값 사용';

  Widget _codeSelect(String label, String key, List<(String, String)> opts) {
    final current = _get(key);
    return _select(
      context,
      label: label,
      fieldKey: '$key-$current',
      value: opts.any((o) => o.$1 == current) ? current : '',
      items: [('', _inheritOption(_labelOf(opts, _base[key]))), ...opts],
      onChanged: widget.disabled ? null : (v) => _set(key, v),
    );
  }

  Widget _amount(String label, String key) => _ElevenstTextField(
        key: ValueKey(key),
        label: label,
        value: _get(key),
        enabled: !widget.disabled,
        hintText: _base[key],
        onChanged: (v) => _set(key, v),
      );

  Widget _place(String label, String key, List<(String, String)> places) {
    if (widget.placesLoading) {
      return _select(
        context,
        label: label,
        fieldKey: '$key-loading',
        value: '',
        items: const [('', '목록을 불러오는 중…')],
        onChanged: null,
      );
    }
    final current = _get(key);
    final inheritedName = _labelOf(places, _base[key]);
    return _select(
      context,
      label: label,
      fieldKey: '$key-$current',
      value: places.any((p) => p.$1 == current) ? current : '',
      items: [('', _inheritOption(inheritedName)), ...places],
      onChanged: widget.disabled ? null : (v) => _set(key, v),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      );

  Widget _hint(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );

  @override
  Widget build(BuildContext context) {
    final showPlaces = widget.level != ShippingOverrideLevel.master;
    // Fee type / pay type / method as they will apply (own value, else inherited).
    String effective(String key) =>
        _get(key).isNotEmpty ? _get(key) : (_base[key] ?? '');
    final feeType = effective(ElevenstKeys.feeType);
    final payType = effective(ElevenstKeys.payType);
    final method = effective(ElevenstKeys.method);

    final sections = <Widget>[
      if (showPlaces)
        _section('출고지 · 반품/교환지', [
          _place('출고지', ElevenstKeys.outboundSeq,
              [for (final p in widget.outbound) (p.code, p.name)]),
          _place('반품/교환지', ElevenstKeys.returnSeq,
              [for (final r in widget.returns) (r.code, r.name)]),
        ]),
      _section('배송', [
        _codeSelect('배송 가능 지역', ElevenstKeys.areaCode, kElevenstAreaOptions),
        _codeSelect('배송 방법', ElevenstKeys.method, kElevenstMethodOptions),
        if (method == '01' && _carriersLoading)
          _select(
            context,
            label: '택배사',
            fieldKey: 'courier-loading',
            value: '',
            items: const [('', '택배사를 불러오는 중…')],
            onChanged: null,
          ),
        if (method == '01' && !_carriersLoading)
          _codeSelect('택배사', ElevenstKeys.courier, [
            for (final c in _carriers)
              (
                c.deliveryCompanyCode,
                '${c.carrierName} (${c.deliveryCompanyCode})'
              ),
          ]),
        _codeSelect('묶음배송', ElevenstKeys.bundle, kElevenstBundleOptions),
      ]),
      _section('배송비', [
        _codeSelect('배송비 종류', ElevenstKeys.feeType, kElevenstFeeTypeOptions),
        _codeSelect('결제 방법', ElevenstKeys.payType, kElevenstPayTypeOptions),
        if (feeType == '02' || feeType == '03')
          _amount('배송비', ElevenstKeys.fee),
        if (feeType == '03') _amount('무료배송 기준 금액', ElevenstKeys.freeOver),
        if (feeType == '05') _amount('1개당 배송비', ElevenstKeys.perItemFee),
        if (feeType == '02' && payType == '02')
          _codeSelect(
              '착불 안내', ElevenstKeys.codNotice, kElevenstCodNoticeOptions),
        if (feeType == '07' || feeType == '08')
          _hint('금액은 11번가 셀러오피스에 설정한 값을 따릅니다.'),
        if (feeType == '04') _buildTiers(),
      ]),
      _section('추가 배송비 · 반품/교환', [
        _amount('제주 추가 배송비', ElevenstKeys.jejuFee),
        _amount('도서산간 추가 배송비', ElevenstKeys.islandFee),
        _amount('반품 배송비(편도)', ElevenstKeys.returnFee),
        _amount('교환 배송비(왕복)', ElevenstKeys.exchangeFee),
        _codeSelect('반품비 부과 방법', ElevenstKeys.returnFeeMethod,
            kElevenstReturnFeeMethodOptions),
        _hint('반품비 부과 방법을 비우면 11번가가 정합니다.'),
      ]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          sections[i],
        ],
      ],
    );
  }

  // D106: one row per tier — start · end (blank on the last row) · fee, at most 10 rows.
  Widget _buildTiers() {
    final tiers = tiersOf(widget.value);
    final message = tierError(widget.value);
    void setTiers(List<ElevenstTier> next) =>
        widget.onChanged(withTiers(widget.value, next));
    void update(int index, ElevenstTier tier) => setTiers(
        [...tiers.sublist(0, index), tier, ...tiers.sublist(index + 1)]);
    void add() {
      final last = tiers.isEmpty ? null : tiers.last;
      final end = last?.end.trim() ?? '';
      final start = last == null
          ? '1'
          : RegExp(r'^\d+$').hasMatch(end)
              ? '${int.parse(end) + 1}'
              : '';
      setTiers([...tiers, ElevenstTier(start: start, end: '', fee: '')]);
    }

    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('수량별 배송비 (최대 10구간)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (tiers.isEmpty &&
              widget.level != ShippingOverrideLevel.account) ...[
            const SizedBox(height: 4),
            _hint('구간을 넣지 않으면 기본값을 그대로 씁니다.'),
          ],
          for (var i = 0; i < tiers.length; i++) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ElevenstTextField(
                    key: ValueKey('tier-$i-start'),
                    label: '개 이상',
                    value: tiers[i].start,
                    enabled: !widget.disabled,
                    onChanged: (v) => update(i, tiers[i].copyWith(start: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: i < tiers.length - 1
                      ? _ElevenstTextField(
                          key: ValueKey('tier-$i-end'),
                          label: '개 이하',
                          value: tiers[i].end,
                          enabled: !widget.disabled,
                          onChanged: (v) =>
                              update(i, tiers[i].copyWith(end: v)),
                        )
                      : Text('상한 없음',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ElevenstTextField(
                    key: ValueKey('tier-$i-fee'),
                    label: '배송비(원)',
                    value: tiers[i].fee,
                    enabled: !widget.disabled,
                    onChanged: (v) => update(i, tiers[i].copyWith(fee: v)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: '삭제',
                  onPressed: widget.disabled
                      ? null
                      : () => setTiers([
                            for (var j = 0; j < tiers.length; j++)
                              if (j != i) tiers[j],
                          ]),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: widget.disabled || tiers.length >= kElevenstMaxTiers
                  ? null
                  : add,
              child: const Text('구간 추가'),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message, style: TextStyle(fontSize: 12, color: scheme.error)),
          ],
        ],
      ),
    );
  }
}

// Same `<select>` port as `ShippingOverrideFields` — [fieldKey] changes with the value so the field re-reads it.
Widget _select(
  BuildContext context, {
  required String fieldKey,
  required String value,
  required List<(String, String)> items,
  required ValueChanged<String>? onChanged,
  String? label,
}) =>
    DropdownButtonFormField<String>(
      key: ValueKey(fieldKey),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: TextStyle(
          fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
      selectedItemBuilder: (context) => [
        for (final item in items)
          Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
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

// Digits-only input whose value is owned by the parent: the controller syncs from [value] only when they differ.
class _ElevenstTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? label;
  final String? hintText;

  const _ElevenstTextField({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.label,
    this.hintText,
  });

  @override
  State<_ElevenstTextField> createState() => _ElevenstTextFieldState();
}

class _ElevenstTextFieldState extends State<_ElevenstTextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant _ElevenstTextField oldWidget) {
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
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: widget.onChanged,
      );
}
