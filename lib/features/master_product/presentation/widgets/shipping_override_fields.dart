import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/shipping_override.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/carrier_option.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/domain/usecases/shipping_label_usecase.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

// Coupang product-creation enums (backend register payload SSOT).
const List<(String, String)> _deliveryMethods = [
  ('SEQUENCIAL', '일반배송'),
  ('COLD_FRESH', '신선냉동'),
  ('MAKE_ORDER', '주문제작'),
  ('AGENT_BUY', '구매대행'),
  ('VENDOR_DIRECT', '설치/직접전달'),
];
const List<(String, String)> _deliveryChargeTypes = [
  ('FREE', '무료배송'),
  ('NOT_FREE', '유료배송'),
  ('CHARGE_RECEIVED', '착불'),
  ('CONDITIONAL_FREE', '조건부 무료'),
];

// deliveryMethod values that surface the extraInfoMessage input.
const Set<String> _extraInfoMethods = {'MAKE_ORDER', 'VENDOR_DIRECT'};

// Buyer-facing extra-info presets (front-side constants).
const List<String> _extraInfoPresets = [
  '주문 후 제작되는 상품으로, 발송까지 영업일 기준 3~5일이 소요됩니다.',
  '설치 배송 상품으로, 배송기사가 방문하여 설치해 드립니다.',
  '주문 제작 상품으로 단순 변심에 의한 교환·반품이 제한될 수 있습니다.',
];
const String _customMessage = '__custom__';
const String _manualCarrier = '__manual__';

/// Web `ShippingOverrideLevel`: account = account default (no inheritance) ·
/// master = master override (no outbound/return places) · listing = channel
/// override.
enum ShippingOverrideLevel { account, master, listing }

/// Shipping override editor shared by the account default, master override
/// and channel override — port of web
/// `presentation/components/ShippingOverrideFields.tsx` +
/// `presentation/hooks/useCarrierOptions.ts` (@09208a0).
///
/// **Purpose**: edits every shipping field (carrier, method, charge type /
/// base charge / free threshold, union delivery, remote area, return fees,
/// outbound/return places) plus the extra-info message in one widget.
/// **File**: lib/features/master_product/presentation/widgets/shipping_override_fields.dart
///
/// **Semantics**: a blank field = inherit (master/listing). The parent owns
/// [value] and serializes it with `overrideToMap` on save.
/// **Carriers**: loaded here from the backend catalog for [platform]; no
/// [platform] = no request, free-text entry. A failed load also falls back to
/// free text and shows one hint line.
///
/// **Usage**:
/// ```dart
/// ShippingOverrideFields(
///   value: _override,
///   onChanged: (next) => setState(() => _override = next),
///   level: ShippingOverrideLevel.master,
///   platform: 'COUPANG',
/// )
/// ShippingOverrideFields(
///   value: _override, onChanged: _set, level: ShippingOverrideLevel.listing,
///   platform: 'COUPANG', outbound: _outbound, returns: _returns,
///   inherited: _baseline, placesLoading: _placesLoading,
/// )
/// ShippingOverrideFields(value: _v, onChanged: _set,
///   level: ShippingOverrideLevel.master, scope: 'common')
/// ```
///
/// ⚠️ [level] master hides outbound/return places (per-account centers).
/// ⚠️ [scope] `'common'` = create form only: hides places, return fees and
///    the extra-info message.
/// ❌ Do not keep a separate carrier constant list on a screen — the catalog
///    loaded here is the only source.
class ShippingOverrideFields extends StatefulWidget {
  final ShippingSettings value;
  final ValueChanged<ShippingSettings> onChanged;
  final ShippingOverrideLevel level;
  final String? platform;
  final bool disabled;
  final List<OutboundPlace>? outbound;
  final List<ReturnCenter>? returns;

  /// Inherited baseline (master ?? account) — shown as placeholders.
  final ShippingSettings? inherited;
  final bool placesLoading;

  /// `'full'` (default) or `'common'`.
  final String scope;

  const ShippingOverrideFields({
    required this.value,
    required this.onChanged,
    required this.level,
    super.key,
    this.platform,
    this.disabled = false,
    this.outbound,
    this.returns,
    this.inherited,
    this.placesLoading = false,
    this.scope = 'full',
  });

  @override
  State<ShippingOverrideFields> createState() => _ShippingOverrideFieldsState();
}

// One carrier lookup result tagged with its platform (web `CarrierEntry`).
class _CarrierEntry {
  final String platform;
  final List<CarrierOption> carriers;
  final bool failed;
  final bool loading;

  const _CarrierEntry({
    required this.platform,
    required this.carriers,
    required this.failed,
    required this.loading,
  });
}

class _ShippingOverrideFieldsState extends State<ShippingOverrideFields> {
  _CarrierEntry? _entry;
  int _carrierSeq = 0;

  // UI-only state (not value).
  bool _manualCarrierOn = false;
  bool _customMessageOn = false;

  @override
  void initState() {
    super.initState();
    _startCarrierLoad();
  }

  @override
  void didUpdateWidget(covariant ShippingOverrideFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.platform != oldWidget.platform) {
      _startCarrierLoad();
    }
  }

  // Web `useCarrierOptions` — no platform = no request.
  void _startCarrierLoad() {
    final platform = widget.platform;
    if (platform == null || platform.isEmpty) {
      return;
    }
    final seq = ++_carrierSeq;
    _entry = _CarrierEntry(
        platform: platform, carriers: const [], failed: false, loading: true);
    unawaited(_loadCarriers(seq, platform));
  }

  Future<void> _loadCarriers(int seq, String platform) async {
    final result =
        await getIt<ShippingLabelUseCase>().getCarrierOptions(platform: platform);
    if (!mounted || seq != _carrierSeq) {
      return;
    }
    setState(() {
      _entry = result.fold(
        (_) => _CarrierEntry(
            platform: platform,
            carriers: const [],
            failed: true,
            loading: false),
        (options) => _CarrierEntry(
            platform: platform,
            carriers: options,
            failed: false,
            loading: false),
      );
    });
  }

  bool get _hasPlatform => (widget.platform ?? '').isNotEmpty;

  _CarrierEntry? get _current {
    final entry = _entry;
    return _hasPlatform && entry != null && entry.platform == widget.platform
        ? entry
        : null;
  }

  List<CarrierOption> get _companies => _current?.carriers ?? const [];
  bool get _carriersLoading => _hasPlatform && (_current?.loading ?? true);
  bool get _carriersFailed => _current?.failed ?? false;

  void _setField(String key, Object? next) =>
      widget.onChanged(withShippingField(widget.value, key, next));

  // Web `Number(raw)` / blank → null.
  void _numberField(String key, String raw) =>
      _setField(key, raw == '' ? null : num.tryParse(raw));

  // Web `a || b` — blank strings are falsy.
  static String? _or(String? a, String? b) =>
      (a != null && a.isNotEmpty) ? a : b;

  String? _labelOf(List<(String, String)> opts, String? v) {
    if (v == null) {
      return null;
    }
    for (final o in opts) {
      if (o.$1 == v) {
        return o.$2;
      }
    }
    return v;
  }

  // `이름 (코드)` — same as the dropdown option label.
  String? _carrierName(String? code) {
    if (code == null) {
      return null;
    }
    for (final c in _companies) {
      if (c.deliveryCompanyCode == code) {
        return '${c.carrierName} (${c.deliveryCompanyCode})';
      }
    }
    return code;
  }

  static String? _numStr(num? n) => n == null
      ? null
      : (n == n.roundToDouble() ? n.toInt().toString() : n.toString());

  static String? _ynLabel(String? v) => v == 'Y'
      ? '가능'
      : v == 'N'
          ? '불가'
          : null;

  static String? _unionLabel(String? v) => v == 'UNION_DELIVERY'
      ? '가능'
      : v == 'NOT_UNION_DELIVERY'
          ? '불가'
          : null;

  // Fallback option label ("기본값 사용", never 상속/override).
  String _inheritOptionOf(String? display) =>
      widget.level == ShippingOverrideLevel.account
          ? '선택하세요'
          : (display != null && display.isNotEmpty)
              ? '기본값 사용 (현재: $display)'
              : '기본값 사용';

  void _applyOutbound(OutboundPlace place) =>
      _setField('outboundShippingPlaceCode', place.code);

  void _applyReturnCenter(ReturnCenter center) {
    var next = widget.value;
    next = withShippingField(next, 'returnCenterCode', center.code);
    next = withShippingField(next, 'returnChargeName', center.name);
    next = withShippingField(next, 'returnContactNumber', center.contactNumber);
    next = withShippingField(next, 'returnZipCode', center.zipCode);
    next = withShippingField(next, 'returnAddress', center.address);
    next = withShippingField(next, 'returnAddressDetail', center.addressDetail);
    next = withShippingField(next, 'returnCharge', center.returnCharge);
    next = withShippingField(
        next, 'deliveryChargeOnReturn', center.deliveryChargeOnReturn);
    widget.onChanged(next);
  }

  void _clearReturnCenter() {
    var next = widget.value;
    for (final key in const [
      'returnCenterCode',
      'returnChargeName',
      'returnContactNumber',
      'returnZipCode',
      'returnAddress',
      'returnAddressDetail',
    ]) {
      next = withShippingField(next, key, null);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isCommon = widget.scope == 'common';
    final showPlaces =
        widget.level != ShippingOverrideLevel.master && !isCommon;
    final sections = <Widget>[
      if (showPlaces) _buildOutboundSection(context),
      _buildDeliverySection(context, isCommon),
      if (showPlaces) _buildReturnSection(context),
      if (!isCommon) _buildReturnFeeSection(context),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          sections[i],
        ],
      ],
    );
  }

  // ── Outbound place ─────────────────────────────────────────────────────
  Widget _buildOutboundSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = widget.value;
    final outbound = widget.outbound ?? const <OutboundPlace>[];
    final disabled = widget.disabled;
    final isAccount = widget.level == ShippingOverrideLevel.account;
    final inherited = widget.inherited;
    String? outboundName;
    for (final p in outbound) {
      if (p.code == value.outboundShippingPlaceCode) {
        outboundName = p.name;
        break;
      }
    }
    final inheritedOutboundCode =
        isAccount ? null : inherited?.outboundShippingPlaceCode;
    String? inheritedOutboundName;
    for (final p in outbound) {
      if (p.code == inheritedOutboundCode) {
        inheritedOutboundName = p.name;
        break;
      }
    }

    Widget body;
    if (widget.placesLoading) {
      body = _hint(context, '출고지 목록을 불러오는 중...');
    } else if (outbound.isNotEmpty) {
      final code = value.outboundShippingPlaceCode;
      if (code != null && code.isNotEmpty) {
        body = _placeCard(
          context,
          dashed: false,
          lines: [
            Text(_or(outboundName, code)!,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (outboundName != null && outboundName.isNotEmpty)
              Text(code,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
          actions: [
            _outlined(
                '변경', disabled ? null : () => _openOutboundPicker(context)),
            if (!isAccount)
              _outlined(
                '기본값 사용',
                disabled
                    ? null
                    : () => _setField('outboundShippingPlaceCode', null),
                muted: true,
              ),
          ],
        );
      } else if (inheritedOutboundCode != null &&
          inheritedOutboundCode.isNotEmpty) {
        body = _placeCard(
          context,
          dashed: true,
          lines: [
            Text('기본값 사용',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Text(_or(inheritedOutboundName, inheritedOutboundCode)!,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
          actions: [
            _outlined(
                '직접 지정', disabled ? null : () => _openOutboundPicker(context)),
          ],
        );
      } else {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              onPressed: disabled ? null : () => _openOutboundPicker(context),
              child: const Text('출고지 선택'),
            ),
            if (!isAccount && inherited != null) ...[
              const SizedBox(height: 8),
              _hint(context, '판매자에 지정된 기본 출고지가 없습니다.'),
            ],
          ],
        );
      }
    } else {
      body = _ShippingTextField(
        key: const ValueKey('outboundShippingPlaceCode'),
        value: value.outboundShippingPlaceCode ?? '',
        enabled: !disabled,
        hintText: inherited?.outboundShippingPlaceCode ?? '출고지 코드를 직접 입력하세요',
        onChanged: (v) =>
            _setField('outboundShippingPlaceCode', v.isEmpty ? null : v),
      );
    }
    return _section('출고지', body);
  }

  // ── Delivery settings ──────────────────────────────────────────────────
  Widget _buildDeliverySection(BuildContext context, bool isCommon) {
    final value = widget.value;
    final inherited = widget.inherited;
    final disabled = widget.disabled;
    final isAccount = widget.level == ShippingOverrideLevel.account;

    final currentMessage = value.extraInfoMessage ?? '';
    final isPreset = _extraInfoPresets.contains(currentMessage);
    final showCustomInput =
        _customMessageOn || (currentMessage != '' && !isPreset);
    final messageSelectValue = showCustomInput
        ? _customMessage
        : isPreset
            ? currentMessage
            : '';
    final showExtraInfo =
        _extraInfoMethods.contains(value.deliveryMethod ?? '');
    final chargeType = value.deliveryChargeType;

    final fields = <Widget>[
      _renderToggle(
        '도서산간 배송',
        value.remoteAreaDeliverable,
        const [('Y', '가능'), ('N', '불가')],
        (v) => _setField('remoteAreaDeliverable', v.isEmpty ? null : v),
        _ynLabel(inherited?.remoteAreaDeliverable),
      ),
      _labeled('택배사', _buildCarrier(context)),
      _labeled(
        '배송비 유형',
        _select(
          context,
          fieldKey: 'deliveryChargeType-$chargeType',
          value: _inList(_deliveryChargeTypes, chargeType),
          items: [
            (
              '',
              _inheritOptionOf(
                  _labelOf(_deliveryChargeTypes, inherited?.deliveryChargeType))
            ),
            ..._deliveryChargeTypes,
          ],
          onChanged: disabled
              ? null
              : (v) => _setField('deliveryChargeType', v.isEmpty ? null : v),
        ),
      ),
      _renderToggle(
        '묶음배송',
        value.unionDeliveryType,
        const [('UNION_DELIVERY', '가능'), ('NOT_UNION_DELIVERY', '불가')],
        (v) => _setField('unionDeliveryType', v.isEmpty ? null : v),
        _unionLabel(inherited?.unionDeliveryType),
      ),
      if (chargeType == 'NOT_FREE' || chargeType == 'CONDITIONAL_FREE')
        _labeled(
          '기본배송비',
          _numberInput('deliveryCharge', value.deliveryCharge,
              _numStr(inherited?.deliveryCharge)),
        ),
      if (chargeType == 'CONDITIONAL_FREE')
        _labeled(
          '무료배송 기준금액',
          _numberInput('freeShipOverAmount', value.freeShipOverAmount,
              _numStr(inherited?.freeShipOverAmount) ?? '이 금액 이상 무료'),
        ),
      _labeled(
        '배송방법',
        _select(
          context,
          fieldKey: 'deliveryMethod-${value.deliveryMethod}',
          value: _inList(_deliveryMethods, value.deliveryMethod),
          items: [
            (
              '',
              _inheritOptionOf(
                  _labelOf(_deliveryMethods, inherited?.deliveryMethod))
            ),
            ..._deliveryMethods,
          ],
          onChanged: disabled
              ? null
              : (v) => _setField('deliveryMethod', v.isEmpty ? null : v),
        ),
      ),
      if (showExtraInfo && !isCommon)
        _labeled(
          '추가 안내문구',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _select(
                context,
                fieldKey: 'extraInfo-$messageSelectValue',
                value: messageSelectValue,
                items: [
                  ('', isAccount ? '사용 안 함' : '기본값 사용'),
                  for (var i = 0; i < _extraInfoPresets.length; i++)
                    (
                      _extraInfoPresets[i],
                      '프리셋 ${i + 1} — ${_extraInfoPresets[i]}'
                    ),
                  (_customMessage, '직접 입력…'),
                ],
                onChanged: disabled
                    ? null
                    : (v) {
                        if (v == _customMessage) {
                          setState(() => _customMessageOn = true);
                        } else {
                          setState(() => _customMessageOn = false);
                          _setField('extraInfoMessage', v.isEmpty ? null : v);
                        }
                      },
              ),
              if (showCustomInput) ...[
                const SizedBox(height: 4),
                _ShippingTextField(
                  key: const ValueKey('extraInfoMessage'),
                  value: value.extraInfoMessage ?? '',
                  enabled: !disabled,
                  maxLines: 4,
                  maxLength: 500,
                  hintText:
                      inherited?.extraInfoMessage ?? '구매자에게 노출할 안내문구를 입력하세요',
                  onChanged: (v) =>
                      _setField('extraInfoMessage', v.isEmpty ? null : v),
                ),
              ],
              const SizedBox(height: 4),
              _hint(context, '주문제작·설치배송 상품에서 구매자에게 노출됩니다.'),
            ],
          ),
        ),
      if (value.unionDeliveryType == 'UNION_DELIVERY' &&
          chargeType == 'CHARGE_RECEIVED')
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '묶음배송(가능)과 착불은 동시에 지정할 수 없습니다. 등록 시 오류가 발생합니다.',
            style: TextStyle(fontSize: 12, color: AppColors.warningForeground),
          ),
        ),
    ];

    return _section(
      '배송설정',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            fields[i],
          ],
        ],
      ),
    );
  }

  Widget _buildCarrier(BuildContext context) {
    final value = widget.value;
    final inherited = widget.inherited;
    final disabled = widget.disabled;
    final companies = _companies;

    // Loading first — otherwise the manual box flashes before the list.
    if (_carriersLoading) {
      return _select(
        context,
        fieldKey: 'carrier-loading',
        value: '',
        items: const [('', '택배사를 불러오는 중…')],
        onChanged: null,
      );
    }
    if (companies.isNotEmpty) {
      final code = value.deliveryCompanyCode;
      final codeInList = companies.any((c) => c.deliveryCompanyCode == code);
      final showManualCarrier =
          _manualCarrierOn || (code != null && code.isNotEmpty && !codeInList);
      final selectValue =
          showManualCarrier ? _manualCarrier : (codeInList ? code! : '');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _select(
            context,
            fieldKey: 'carrier-$selectValue',
            value: selectValue,
            items: [
              (
                '',
                _inheritOptionOf(_carrierName(inherited?.deliveryCompanyCode))
              ),
              // Server order as-is (registered carriers first).
              for (final c in companies)
                (
                  c.deliveryCompanyCode,
                  '${c.carrierName} (${c.deliveryCompanyCode})'
                ),
              (_manualCarrier, '직접 입력…'),
            ],
            onChanged: disabled
                ? null
                : (v) {
                    if (v == _manualCarrier) {
                      setState(() => _manualCarrierOn = true);
                    } else {
                      setState(() => _manualCarrierOn = false);
                      _setField('deliveryCompanyCode', v.isEmpty ? null : v);
                    }
                  },
          ),
          if (showManualCarrier) ...[
            const SizedBox(height: 4),
            _ShippingTextField(
              key: const ValueKey('deliveryCompanyCode-manual'),
              value: code ?? '',
              enabled: !disabled,
              hintText:
                  inherited?.deliveryCompanyCode ?? '쿠팡 택배사 코드 (예: KDEXP)',
              onChanged: (v) =>
                  _setField('deliveryCompanyCode', v.isEmpty ? null : v),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShippingTextField(
          key: const ValueKey('deliveryCompanyCode'),
          value: value.deliveryCompanyCode ?? '',
          enabled: !disabled,
          hintText: inherited?.deliveryCompanyCode ?? '택배사 코드를 직접 입력하세요',
          onChanged: (v) =>
              _setField('deliveryCompanyCode', v.isEmpty ? null : v),
        ),
        // An empty list mixes "unsupported platform" and "load failed" —
        // explain only the failure.
        if (_carriersFailed) ...[
          const SizedBox(height: 4),
          const Text(
            '택배사 목록을 불러오지 못했습니다. 코드를 직접 입력하세요',
            style: TextStyle(fontSize: 12, color: AppColors.warningForeground),
          ),
        ],
      ],
    );
  }

  Widget _renderToggle(
    String label,
    String? current,
    List<(String, String)> options,
    ValueChanged<String> onSelect,
    String? inheritedHint,
  ) =>
      Builder(builder: (context) {
        final disabled = widget.disabled;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label(label),
            Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: current == options[i].$1
                        ? FilledButton(
                            onPressed: disabled ? null : () => onSelect(''),
                            child: Text(options[i].$2),
                          )
                        : OutlinedButton(
                            onPressed:
                                disabled ? null : () => onSelect(options[i].$1),
                            child: Text(options[i].$2),
                          ),
                  ),
                ],
              ],
            ),
            if (widget.level != ShippingOverrideLevel.account &&
                current == null &&
                inheritedHint != null &&
                inheritedHint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '기본값: $inheritedHint',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      });

  // ── Return center ──────────────────────────────────────────────────────
  Widget _buildReturnSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = widget.value;
    final returns = widget.returns ?? const <ReturnCenter>[];
    final disabled = widget.disabled;
    final isAccount = widget.level == ShippingOverrideLevel.account;
    final inherited = widget.inherited;

    final inheritedReturnCode = isAccount ? null : inherited?.returnCenterCode;
    ReturnCenter? inheritedEntry;
    for (final r in returns) {
      if (r.code == inheritedReturnCode) {
        inheritedEntry = r;
        break;
      }
    }
    final inheritedReturnName = _or(
        _or(inherited?.returnChargeName, inheritedEntry?.chargeName),
        inheritedEntry?.name);
    final inheritedZip = _or(inherited?.returnZipCode, inheritedEntry?.zipCode);
    final inheritedReturnAddressLine = [
      if (inheritedZip != null && inheritedZip.isNotEmpty) '[$inheritedZip]',
      inherited?.returnAddress ?? inheritedEntry?.address ?? '',
      inherited?.returnAddressDetail ?? inheritedEntry?.addressDetail ?? '',
    ].where((p) => p.trim().isNotEmpty).join(' ').trim();
    final zip = value.returnZipCode;
    final returnAddressLine = [
      if (zip != null && zip.isNotEmpty) '[$zip]',
      value.returnAddress ?? '',
      value.returnAddressDetail ?? '',
    ].where((p) => p.trim().isNotEmpty).join(' ').trim();

    Widget body;
    if (widget.placesLoading) {
      body = _hint(context, '반품지 목록을 불러오는 중...');
    } else if (returns.isNotEmpty) {
      final code = value.returnCenterCode;
      final contact = value.returnContactNumber;
      if (code != null && code.isNotEmpty) {
        body = _placeCard(
          context,
          dashed: false,
          lines: [
            Text(_or(value.returnChargeName, code)!,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (returnAddressLine.isNotEmpty)
              Text(returnAddressLine,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            if (contact != null && contact.isNotEmpty)
              Text(contact,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
          actions: [
            _outlined('변경', disabled ? null : () => _openReturnPicker(context)),
            if (!isAccount)
              _outlined('기본값 사용', disabled ? null : _clearReturnCenter,
                  muted: true),
          ],
        );
      } else if (inheritedReturnCode != null &&
          inheritedReturnCode.isNotEmpty) {
        body = _placeCard(
          context,
          dashed: true,
          lines: [
            Text('기본값 사용',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Text(_or(inheritedReturnName, inheritedReturnCode)!,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (inheritedReturnAddressLine.isNotEmpty)
              Text(inheritedReturnAddressLine,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
          actions: [
            _outlined(
                '직접 지정', disabled ? null : () => _openReturnPicker(context)),
          ],
        );
      } else {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              onPressed: disabled ? null : () => _openReturnPicker(context),
              child: const Text('반품지 선택'),
            ),
            if (!isAccount && inherited != null) ...[
              const SizedBox(height: 8),
              _hint(context, '판매자에 지정된 기본 반품지가 없습니다.'),
            ],
          ],
        );
      }
    } else {
      Widget text(String key, String label, String? current) => _labeled(
            label,
            _ShippingTextField(
              key: ValueKey(key),
              value: current ?? '',
              enabled: !disabled,
              onChanged: (v) => _setField(key, v.isEmpty ? null : v),
            ),
          );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShippingTextField(
            key: const ValueKey('returnCenterCode'),
            value: value.returnCenterCode ?? '',
            enabled: !disabled,
            hintText: '반품지 코드 (미생성 시 NO_RETURN_CENTERCODE)',
            onChanged: (v) =>
                _setField('returnCenterCode', v.isEmpty ? null : v),
          ),
          const SizedBox(height: 8),
          text('returnChargeName', '반품지명', value.returnChargeName),
          const SizedBox(height: 8),
          text('returnContactNumber', '연락처', value.returnContactNumber),
          const SizedBox(height: 8),
          text('returnZipCode', '우편번호', value.returnZipCode),
          const SizedBox(height: 8),
          text('returnAddress', '주소', value.returnAddress),
          const SizedBox(height: 8),
          text('returnAddressDetail', '상세 주소', value.returnAddressDetail),
        ],
      );
    }
    return _section('반품지', body);
  }

  // ── Return-leg fees ────────────────────────────────────────────────────
  Widget _buildReturnFeeSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = widget.value;
    final inherited = widget.inherited;
    final returnRoundTrip =
        (value.deliveryChargeOnReturn ?? 0) + (value.returnCharge ?? 0);
    return _section(
      '반품 배송비',
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _labeled(
              '초도배송(편도)',
              _numberInput(
                  'deliveryChargeOnReturn',
                  value.deliveryChargeOnReturn,
                  _numStr(inherited?.deliveryChargeOnReturn)),
            ),
            const SizedBox(height: 8),
            _labeled(
              '반품배송비(편도)',
              _numberInput('returnCharge', value.returnCharge,
                  _numStr(inherited?.returnCharge)),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: '고객 사유로 인한 반품 시, 왕복 반품·배송비는 ',
                children: [
                  TextSpan(
                    text: '초도배송비 + 반품배송비의 합계인 ${koNumber(returnRoundTrip)}원',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: scheme.error),
                  ),
                  const TextSpan(text: '이 청구됩니다.'),
                ],
              ),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pickers (web OutboundPlacePickerModal / ReturnCenterPickerModal) ────
  Future<void> _openOutboundPicker(BuildContext context) async {
    final outbound = widget.outbound ?? const <OutboundPlace>[];
    final picked = await _showPlacePicker<OutboundPlace>(
      context,
      title: '출고지 선택',
      emptyText: '조회된 출고지가 없습니다.',
      items: outbound,
      isActive: (p) => p.code == widget.value.outboundShippingPlaceCode,
      itemBuilder: (context, p) => [
        _pickerHeader(context, _or(p.name, p.code)!, p.code),
      ],
    );
    if (picked != null && mounted) {
      _applyOutbound(picked);
    }
  }

  Future<void> _openReturnPicker(BuildContext context) async {
    final returns = widget.returns ?? const <ReturnCenter>[];
    final picked = await _showPlacePicker<ReturnCenter>(
      context,
      title: '반품지 선택',
      emptyText: '조회된 반품지가 없습니다.',
      items: returns,
      isActive: (c) => c.code == widget.value.returnCenterCode,
      itemBuilder: (context, c) {
        final scheme = Theme.of(context).colorScheme;
        final addr = [c.address ?? '', c.addressDetail ?? '']
            .where((p) => p.trim().isNotEmpty)
            .join(' ');
        final zip = c.zipCode;
        final contact = c.contactNumber;
        return [
          _pickerHeader(context, _or(c.name, c.code)!, c.code),
          const SizedBox(height: 4),
          Text(
            (zip != null && zip.isNotEmpty) ? '[$zip] $addr' : addr,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
          if (contact != null && contact.isNotEmpty)
            Text(contact,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ];
      },
    );
    if (picked != null && mounted) {
      _applyReturnCenter(picked);
    }
  }

  Widget _pickerHeader(BuildContext context, String name, String code) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text(code,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );

  // ── Layout helpers ─────────────────────────────────────────────────────
  Widget _section(String title, Widget body) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          body,
        ],
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      );

  Widget _labeled(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_label(label), child],
      );

  Widget _hint(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );

  Widget _outlined(String text, VoidCallback? onPressed,
          {bool muted = false}) =>
      Builder(
        builder: (context) => OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor:
                muted ? Theme.of(context).colorScheme.onSurfaceVariant : null,
          ),
          onPressed: onPressed,
          child: Text(text),
        ),
      );

  Widget _placeCard(
    BuildContext context, {
    required bool dashed,
    required List<Widget> lines,
    required List<Widget> actions,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dashed ? scheme.surfaceContainerLow : null,
        border:
            Border.all(color: dashed ? scheme.outline : scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            ),
          ),
          const SizedBox(width: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }

  Widget _numberInput(String key, num? current, String? hintText) =>
      _ShippingTextField(
        key: ValueKey(key),
        value: _numStr(current) ?? '',
        enabled: !widget.disabled,
        hintText: hintText,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _numberField(key, v),
      );

  // A stored value outside the option list shows the first option (web
  // `<select>` behavior) instead of breaking the dropdown.
  static String _inList(List<(String, String)> opts, String? v) =>
      v != null && opts.any((o) => o.$1 == v) ? v : '';
}

Future<T?> _showPlacePicker<T>(
  BuildContext context, {
  required String title,
  required String emptyText,
  required List<T> items,
  required bool Function(T item) isActive,
  required List<Widget> Function(BuildContext context, T item) itemBuilder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(emptyText,
                            style: TextStyle(
                                fontSize: 14, color: scheme.onSurfaceVariant)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final active = isActive(item);
                          return Material(
                            color:
                                active ? AppColors.infoSurface : scheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(
                                color: active
                                    ? AppColors.infoForeground
                                    : scheme.outlineVariant,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => Navigator.of(sheetContext).pop(item),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: itemBuilder(context, item),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

// Web `<select>` (R8). [fieldKey] changes with [value] so the form field
// re-reads its initial value when the parent changes it. The closed field
// shows one line; the open menu shows each label in full.
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
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

// Text input whose value is owned by the parent (R22): the controller syncs
// from [value] only when they differ, keeping cursor and IME composition.
class _ShippingTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;

  const _ShippingTextField({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<_ShippingTextField> createState() => _ShippingTextFieldState();
}

class _ShippingTextFieldState extends State<_ShippingTextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant _ShippingTextField oldWidget) {
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
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText: widget.hintText,
          counterText: '',
        ),
        onChanged: widget.onChanged,
      );
}
