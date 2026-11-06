import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/lotteon_shipping.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';

/// LotteON shipping fields — port of web
/// `presentation/components/LotteonShippingFields.tsx` (FEATURE_2610_24 /
/// D42 · D43 · D65), shared by the LotteON channel layer and a LotteON
/// listing.
///
/// **Purpose**: the value is one string map of the three `lotteon.*` input
/// keys; the parent owns and saves it. Every choice comes from the LotteON
/// seller center (the seller makes them there, D29) — nothing is typed.
/// **File**: lib/features/master_product/presentation/widgets/lotteon_shipping_fields.dart
///
/// **Usage**:
/// ```dart
/// LotteonShippingFields(level: ShippingOverrideLevel.account, value: _form,
///     onChanged: (next) => setState(() => _form = next),
///     outbound: _outbound, returns: _returns, feePolicies: _policies)
/// LotteonShippingFields(level: ShippingOverrideLevel.listing, value: _form,
///     onChanged: _set, inherited: _baseline, outbound: _outbound,
///     returns: _returns, feePolicies: _policies, listsLoading: _loading)
/// ```
///
/// ⚠️ The policy fee keys (`lotteon.dvCstDvsCd` · `lotteon.dvCst` ·
///    `lotteon.cndlFreeStdAmt`) are never shown or edited here; the server
///    writes them (D65).
/// ❌ Never mixed with the Coupang, 11st or ESM fields — a LotteON channel
///    shows these alone. There is no master level (D42).
class LotteonShippingFields extends StatelessWidget {
  final Map<String, String> value;
  final ValueChanged<Map<String, String>> onChanged;

  /// account = the LotteON channel layer · listing = one LotteON listing.
  final ShippingOverrideLevel level;
  final bool disabled;

  /// LotteON shipping places (150, type 02) — the parent loads them.
  final List<OutboundPlace> outbound;

  /// LotteON return places (150, type 01) — the parent loads them.
  final List<ReturnCenter> returns;

  /// LotteON shipping fee policies (166) — the parent loads them.
  final List<LotteonChoice> feePolicies;
  final bool listsLoading;

  /// The channel layer, shown as 「기본값 사용 (현재: …)」 on the listing level.
  final Map<String, String>? inherited;

  const LotteonShippingFields({
    required this.value,
    required this.onChanged,
    required this.level,
    super.key,
    this.disabled = false,
    this.outbound = const [],
    this.returns = const [],
    this.feePolicies = const [],
    this.listsLoading = false,
    this.inherited,
  });

  Map<String, String> get _base => level == ShippingOverrideLevel.account
      ? const {}
      : (inherited ?? const {});

  void _set(String key, String raw) {
    final next = Map<String, String>.of(value);
    if (raw.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = raw;
    }
    onChanged(next);
  }

  String _inheritOption(String? display) =>
      level == ShippingOverrideLevel.account
          ? '선택하세요'
          : (display != null && display.isNotEmpty)
              ? '기본값 사용 (현재: $display)'
              : '기본값 사용';

  Widget _choice(
    BuildContext context,
    String key,
    List<(String, String)> list,
  ) {
    final label = kLotteonLabels[key];
    if (listsLoading) {
      return _select(
        context,
        label: label,
        fieldKey: '$key-loading',
        value: '',
        items: const [('', '목록을 불러오는 중…')],
        onChanged: null,
      );
    }
    final current = value[key] ?? '';
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
      onChanged: disabled ? null : (v) => _set(key, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      _choice(context, LotteonKeys.owhpNo,
          [for (final p in outbound) (p.code, p.name)]),
      _choice(context, LotteonKeys.rtrpNo,
          [for (final r in returns) (r.code, r.name)]),
      _choice(context, LotteonKeys.dvCstPolNo,
          [for (final f in feePolicies) (f.code, f.name)]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          fields[i],
        ],
        const SizedBox(height: 12),
        Text(
          '출고지 · 회수지 · 배송비 정책은 롯데ON 판매자센터에서 만든 것을 고릅니다.',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// Same `<select>` port as `EsmShippingFields` — [fieldKey] changes with the
// value so the field re-reads it.
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
