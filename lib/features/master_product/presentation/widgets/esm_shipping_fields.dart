import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/esm_shipping.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';

/// Gmarket · Auction (ESM) shipping fields — port of web
/// `presentation/components/EsmShippingFields.tsx` (FEATURE_2610_26 / D35 ·
/// D36 · D37), shared by the ESM channel layer and an ESM listing.
///
/// **Purpose**: the value is one string map of the six `esm.*` input keys; the
/// parent owns and saves it. Every choice comes from ESM+ (the seller makes
/// them there, D35); only the one-way return fee is typed.
/// **File**: lib/features/master_product/presentation/widgets/esm_shipping_fields.dart
///
/// **Usage**:
/// ```dart
/// EsmShippingFields(level: ShippingOverrideLevel.account, value: _form,
///     onChanged: (next) => setState(() => _form = next),
///     outbound: _outbound, returns: _returns, dispatches: _dispatches,
///     companies: _companies, loadBundles: _loadBundles)
/// EsmShippingFields(level: ShippingOverrideLevel.listing, value: _form,
///     onChanged: _set, inherited: _baseline, loadBundles: _loadBundles, …)
/// ```
///
/// ⚠️ Picking another shipping place clears the bundle-fee policy — a policy
///    belongs to one place (D36).
/// ⚠️ The four policy facts (`esm.bundleFeeType` …) are never edited here; the
///    server writes them (D66).
/// ❌ Never mixed with the Coupang or 11st fields — an ESM channel shows these
///    alone. There is no master level (D36).
class EsmShippingFields extends StatefulWidget {
  final Map<String, String> value;
  final ValueChanged<Map<String, String>> onChanged;

  /// account = the ESM channel layer · listing = one ESM listing.
  final ShippingOverrideLevel level;
  final bool disabled;

  /// ESM shipping places (post 17) — the parent loads them.
  final List<OutboundPlace> outbound;

  /// ESM address book entries (post 16) — the parent loads them.
  final List<ReturnCenter> returns;

  /// ESM dispatch policies (post 19) — the parent loads them.
  final List<EsmChoice> dispatches;

  /// ESM couriers (post 142) — the parent loads them.
  final List<EsmChoice> companies;
  final bool listsLoading;

  /// The bundle-fee policies of one shipping place (post 18) — asked whenever
  /// the effective place changes.
  final Future<List<EsmChoice>> Function(String placeNo) loadBundles;

  /// The channel layer, shown as 「기본값 사용 (현재: …)」 on the listing level.
  final Map<String, String>? inherited;

  const EsmShippingFields({
    required this.value,
    required this.onChanged,
    required this.level,
    required this.loadBundles,
    super.key,
    this.disabled = false,
    this.outbound = const [],
    this.returns = const [],
    this.dispatches = const [],
    this.companies = const [],
    this.listsLoading = false,
    this.inherited,
  });

  @override
  State<EsmShippingFields> createState() => _EsmShippingFieldsState();
}

class _EsmShippingFieldsState extends State<EsmShippingFields> {
  String _bundlesPlaceNo = '';
  List<EsmChoice> _bundles = const [];
  bool _bundlesFailed = false;

  Map<String, String> get _base => widget.level == ShippingOverrideLevel.account
      ? const {}
      : (widget.inherited ?? const {});

  String _get(String key) => widget.value[key] ?? '';

  // The place whose policies are listed: the own value, else the inherited one.
  String get _placeNo {
    final own = _get(EsmKeys.placeNo);
    return own.isNotEmpty ? own : (_base[EsmKeys.placeNo] ?? '');
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadBundles());
  }

  @override
  void didUpdateWidget(covariant EsmShippingFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_placeNo != _bundlesPlaceNo) {
      unawaited(_loadBundles());
    }
  }

  Future<void> _loadBundles() async {
    final placeNo = _placeNo;
    _bundlesPlaceNo = placeNo;
    if (placeNo.isEmpty) {
      return;
    }
    try {
      final list = await widget.loadBundles(placeNo);
      if (!mounted || _bundlesPlaceNo != placeNo) {
        return;
      }
      setState(() {
        _bundles = list;
        _bundlesFailed = false;
      });
    } on Object {
      if (!mounted || _bundlesPlaceNo != placeNo) {
        return;
      }
      setState(() {
        _bundles = const [];
        _bundlesFailed = true;
      });
    }
  }

  void _set(String key, String raw) {
    final next = Map<String, String>.of(widget.value);
    if (raw.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = raw;
    }
    widget.onChanged(next);
  }

  // D36: the bundle-fee policy belongs to the chosen place, so a new place
  // starts without one.
  void _setPlace(String raw) {
    final next = Map<String, String>.of(widget.value)
      ..remove(EsmKeys.bundlePolicyNo);
    if (raw.trim().isEmpty) {
      next.remove(EsmKeys.placeNo);
    } else {
      next[EsmKeys.placeNo] = raw;
    }
    widget.onChanged(next);
  }

  String _inheritOption(String? display) =>
      widget.level == ShippingOverrideLevel.account
          ? '선택하세요'
          : (display != null && display.isNotEmpty)
              ? '기본값 사용 (현재: $display)'
              : '기본값 사용';

  Widget _choice(
    String key,
    List<(String, String)> list,
    bool loading,
    ValueChanged<String> onPick,
  ) {
    final label = kEsmLabels[key];
    if (loading) {
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
    final baseCode = _base[key];
    var inheritedName = baseCode;
    for (final c in list) {
      if (c.$1 == baseCode) {
        inheritedName = c.$2;
      }
    }
    return _select(
      context,
      label: label,
      fieldKey: '$key-$current',
      value: list.any((c) => c.$1 == current) ? current : '',
      items: [('', _inheritOption(inheritedName)), ...list],
      onChanged: widget.disabled ? null : onPick,
    );
  }

  Widget _hint(String text, {Color? color}) => Text(
        text,
        style: TextStyle(
            fontSize: 12,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
      );

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

  @override
  Widget build(BuildContext context) {
    final placeNo = _placeNo;
    final bundlesLoading = placeNo.isNotEmpty && _bundlesPlaceNo != placeNo;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('출하지 · 배송비', [
          _choice(
            EsmKeys.placeNo,
            [for (final p in widget.outbound) (p.code, p.name)],
            widget.listsLoading,
            _setPlace,
          ),
          _choice(
            EsmKeys.bundlePolicyNo,
            [for (final b in _bundles) (b.code, b.name)],
            bundlesLoading,
            (v) => _set(EsmKeys.bundlePolicyNo, v),
          ),
          _choice(
            EsmKeys.dispatchPolicyNo,
            [for (final d in widget.dispatches) (d.code, d.name)],
            widget.listsLoading,
            (v) => _set(EsmKeys.dispatchPolicyNo, v),
          ),
          if (placeNo.isEmpty) _hint('출하지를 고르면 그 출하지의 묶음배송비가 보입니다.'),
          if (_bundlesFailed && placeNo == _bundlesPlaceNo)
            _hint('묶음배송비 목록을 불러오지 못했습니다.', color: scheme.error),
        ]),
        const SizedBox(height: 20),
        _section('반품/교환', [
          _choice(
            EsmKeys.returnAddrNo,
            [for (final r in widget.returns) (r.code, r.name)],
            widget.listsLoading,
            (v) => _set(EsmKeys.returnAddrNo, v),
          ),
          _choice(
            EsmKeys.companyNo,
            [for (final c in widget.companies) (c.code, c.name)],
            widget.listsLoading,
            (v) => _set(EsmKeys.companyNo, v),
          ),
          _EsmFeeField(
            key: const ValueKey(EsmKeys.returnFee),
            label: kEsmLabels[EsmKeys.returnFee],
            value: _get(EsmKeys.returnFee),
            enabled: !widget.disabled,
            hintText: _base[EsmKeys.returnFee],
            onChanged: (v) => _set(EsmKeys.returnFee, v),
          ),
          _hint('출하지 · 묶음배송비 · 발송정책 · 주소록은 ESM+ 에서 만든 것을 고릅니다.'),
        ]),
      ],
    );
  }
}

// Same `<select>` port as `ElevenstShippingFields` — [fieldKey] changes with
// the value so the field re-reads it.
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

// Digits-only input whose value is owned by the parent: the controller syncs
// from [value] only when they differ.
class _EsmFeeField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? label;
  final String? hintText;

  const _EsmFeeField({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.label,
    this.hintText,
  });

  @override
  State<_EsmFeeField> createState() => _EsmFeeFieldState();
}

class _EsmFeeFieldState extends State<_EsmFeeField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant _EsmFeeField oldWidget) {
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
