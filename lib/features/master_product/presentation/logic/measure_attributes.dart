// Weight/volume either-or pairing — port of web
// `app/dashboard/master-products/[id]/components/measureAttributes.ts`
// (@09208a0).
// File: lib/features/master_product/presentation/logic/measure_attributes.dart
//
// Coupang sends weight and volume as separate attributes that may both be
// MANDATORY, while a product only carries one of them. Pairs are rendered as
// "axis pick + one value" and validated as one-of.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';

const List<String> _weightTokens = ['중량', '무게'];
const List<String> _volumeTokens = ['용량', '부피'];

/// Web `MeasurePair`.
class MeasurePair {
  /// Common prefix with the unit tokens removed (group id), e.g. `개당`.
  final String base;
  final CategoryAttribute weight;
  final CategoryAttribute volume;

  const MeasurePair({
    required this.base,
    required this.weight,
    required this.volume,
  });
}

/// Web `PairedAttributes`.
class PairedAttributes {
  final List<MeasurePair> pairs;

  /// Attributes not bound into a pair.
  final List<CategoryAttribute> singles;

  const PairedAttributes({required this.pairs, required this.singles});
}

bool _hasToken(String name, List<String> tokens) =>
    tokens.any((t) => name.contains(t));

// Remove every unit token and all whitespace → normalized group id.
String _stripUnits(String name) {
  var s = name;
  for (final t in [..._weightTokens, ..._volumeTokens]) {
    s = s.split(t).join();
  }
  return s.replaceAll(RegExp(r'\s+'), '');
}

/// Splits [attributes] into weight/volume pairs and the rest, keeping order.
PairedAttributes pairMeasureAttributes(List<CategoryAttribute> attributes) {
  final used = <String>{};
  final pairs = <MeasurePair>[];

  for (final a in attributes) {
    if (used.contains(a.name)) {
      continue;
    }
    // Start a pair from an attribute with a weight token and no volume token.
    if (!_hasToken(a.name, _weightTokens) || _hasToken(a.name, _volumeTokens)) {
      continue;
    }
    final base = _stripUnits(a.name);
    CategoryAttribute? volume;
    for (final b in attributes) {
      if (!used.contains(b.name) &&
          b.name != a.name &&
          _hasToken(b.name, _volumeTokens) &&
          !_hasToken(b.name, _weightTokens) &&
          _stripUnits(b.name) == base) {
        volume = b;
        break;
      }
    }
    if (volume != null) {
      pairs.add(MeasurePair(base: base, weight: a, volume: volume));
      used
        ..add(a.name)
        ..add(volume.name);
    }
  }

  final singles = attributes.where((a) => !used.contains(a.name)).toList();
  return PairedAttributes(pairs: pairs, singles: singles);
}

/// A pair is required when either side is MANDATORY.
bool isPairRequired(MeasurePair p) => p.weight.required || p.volume.required;

/// Unit inferred from stored values: `중량` / `용량` / ``.
String derivedUnit(MeasurePair p, Map<String, String> values) {
  if ((values[p.weight.name] ?? '').trim().isNotEmpty) {
    return '중량';
  }
  if ((values[p.volume.name] ?? '').trim().isNotEmpty) {
    return '용량';
  }
  return '';
}

const Map<String, List<String>> _axisTokens = {
  '중량': _weightTokens,
  '용량': _volumeTokens,
};

// The name has the axis token on a word boundary and no opposite-axis token.
bool _isAxisName(String name, String axis) {
  final other = axis == '중량' ? _volumeTokens : _weightTokens;
  return _axisTokens[axis]!.any((t) => hasBoundaryToken(name, t)) &&
      !other.any((t) => hasBoundaryToken(name, t));
}

/// The measure attribute name for [axis]: the pair side when a pair exists,
/// otherwise a single with the same axis token. `''` when none.
String findMeasureAttrName(List<CategoryAttribute> attributes, String axis) {
  final optionAttrs = attributes.where((a) => isOptionField(a.name)).toList();
  final paired = pairMeasureAttributes(optionAttrs);
  if (paired.pairs.isNotEmpty) {
    final p = paired.pairs[0];
    return axis == '중량' ? p.weight.name : p.volume.name;
  }
  for (final a in paired.singles) {
    if (_isAxisName(a.name, axis)) {
      return a.name;
    }
  }
  return '';
}

/// Whether this category has a measure attribute (weight or volume axis).
bool hasMeasureAttr(List<CategoryAttribute> attributes) =>
    findMeasureAttrName(attributes, '중량') != '' ||
    findMeasureAttrName(attributes, '용량') != '';

/// Axis of an attribute name: `중량` / `용량` / ``.
String axisOfAttrName(String name) {
  if (_isAxisName(name, '중량')) {
    return '중량';
  }
  if (_isAxisName(name, '용량')) {
    return '용량';
  }
  return '';
}

/// The current stored/entered measure value — reads exactly the attributes
/// auto-fill writes to ([findMeasureAttrName]). `''` when none.
String readMeasureValue(
  List<CategoryAttribute> attributes,
  Map<String, String> values,
) {
  final names = [
    findMeasureAttrName(attributes, '중량'),
    findMeasureAttrName(attributes, '용량'),
  ].where((n) => n != '');
  for (final n in names) {
    final v = (values[n] ?? '').trim();
    if (v.isNotEmpty) {
      return v;
    }
  }
  return '';
}
