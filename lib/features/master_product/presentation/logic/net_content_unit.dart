// Product measure value → option per-unit weight/volume derivation — port of
// web `app/dashboard/master-products/[id]/components/netContentUnit.ts`
// (@09208a0).
// File: lib/features/master_product/presentation/logic/net_content_unit.dart
//
// Pure functions (no state): callers compute once and pass the same value to
// both the attribute injection and the notice composition.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';

/// Web `MARKET_UNIT` — product storage unit (G/KG/L/ML) → market notation.
/// ⚠️ Same table as the product form select; do not extend it ad hoc.
const Map<String, String> kMarketUnit = {
  'G': 'g',
  'KG': 'kg',
  'L': 'l',
  'ML': 'ml',
};

const Set<String> _massUnits = {'G', 'KG'};

/// Mass unit (→ weight side of a pair). L/ML → false (volume side).
bool isMassUnit(String u) => _massUnits.contains(u.trim().toUpperCase());

final RegExp _numberOnly = RegExp(r'^[0-9]+(\.[0-9]+)?$');

/// Appends [unit] when [value] is a bare number; leaves values that already
/// carry a unit as-is. ⚠️ Blank value → `''`.
String withUnit(String value, String unit) {
  final v = value.trim();
  if (v.isEmpty) {
    return '';
  }
  final u = unit.trim();
  if (u.isEmpty) {
    return v;
  }
  return _numberOnly.hasMatch(v) ? '$v$u' : v;
}

// The single component satisfying all three derivation conditions, or null:
// exactly one component · non-blank netContent · unit in kMarketUnit.
MasterComponent? _soleMeasuredComponent(List<MasterComponent> components) {
  if (components.length != 1) {
    return null;
  }
  final c = components[0];
  final value = (c.netContent ?? '').trim();
  final unit = (c.netContentUnit ?? '').trim().toUpperCase();
  if (value.isEmpty || (kMarketUnit[unit] ?? '').isEmpty) {
    return null;
  }
  return c;
}

/// Derived measure (`320g`) when the derivation conditions hold, else `''`.
String deriveMeasured(List<MasterComponent> components) {
  final c = _soleMeasuredComponent(components);
  if (c == null) {
    return '';
  }
  final unit = kMarketUnit[(c.netContentUnit ?? '').trim().toUpperCase()]!;
  return withUnit((c.netContent ?? '').trim(), unit);
}

/// Derived axis (`중량` / `용량` / ``).
String derivedAxis(List<MasterComponent> components) {
  final c = _soleMeasuredComponent(components);
  if (c == null) {
    return '';
  }
  return isMassUnit(c.netContentUnit ?? '') ? '중량' : '용량';
}

/// Web `MEASURE_UNITS_BY_AXIS` — selectable units per axis (notation form),
/// derived from [kMarketUnit] only.
final Map<String, List<String>> kMeasureUnitsByAxis = {
  '중량': kMarketUnit.keys
      .where(isMassUnit)
      .map((code) => kMarketUnit[code]!)
      .toList(),
  '용량': kMarketUnit.keys
      .where((code) => !isMassUnit(code))
      .map((code) => kMarketUnit[code]!)
      .toList(),
};

/// Web `SplitMeasured`.
class SplitMeasured {
  /// Numeric part (may be `''`).
  final String amount;

  /// Notation unit (`''` = unspecified).
  final String unit;

  /// `false` = could not split into number + unit (legacy free text) — edit
  /// the raw text instead.
  final bool parsed;

  const SplitMeasured({
    required this.amount,
    required this.unit,
    required this.parsed,
  });
}

final RegExp _measuredRe =
    RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Z]*)\s*$');

/// Splits a stored value (`320g`) into number and unit. Blank → parsed with
/// both empty. ⚠️ Unsplittable values return `parsed: false`.
SplitMeasured splitMeasured(String value) {
  final v = value.trim();
  if (v.isEmpty) {
    return const SplitMeasured(amount: '', unit: '', parsed: true);
  }
  final m = _measuredRe.firstMatch(v);
  if (m == null) {
    return SplitMeasured(amount: v, unit: '', parsed: false);
  }
  return SplitMeasured(
    amount: m.group(1)!,
    unit: m.group(2)!.toLowerCase(),
    parsed: true,
  );
}

/// Number + unit → stored value. Blank number → `''`.
String joinMeasured(String amount, String unit) => withUnit(amount, unit);

final RegExp _amountInputRe = RegExp(r'^(\d+(\.\d*)?)?$');

/// Whether the input may go into the measure number field as-is (blank ·
/// `200` · `23.` · `23.9`).
bool isAmountInput(String value) => _amountInputRe.hasMatch(value);

/// Screen input (`23.`) → stored number (`23`).
String normalizeAmount(String value) =>
    value.endsWith('.') ? value.substring(0, value.length - 1) : value;
