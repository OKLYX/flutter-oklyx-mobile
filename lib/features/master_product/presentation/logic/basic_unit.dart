// Base-unit (Coupang basicUnit) display helpers — port of web
// `app/dashboard/master-products/[id]/components/basicUnit.ts` (@09208a0).
// File: lib/features/master_product/presentation/logic/basic_unit.dart
//
// Display only — stored values never get the unit appended.
// ⚠️ Do not bake a fallback text into these helpers; each call site decides
//    its own fallback with `ifEmpty`.
// ❌ Do not change the unit's letter case — use the backend value as-is.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';

// null / blank → '' (no unit = draw nothing).
String _unitOf(CategoryAttribute? a) => a?.basicUnit?.trim() ?? '';

/// Label suffix: `(g)` when a unit exists, otherwise `''`.
String unitSuffix(CategoryAttribute? a) {
  final u = _unitOf(a);
  return u.isNotEmpty ? '($u)' : '';
}

/// Input placeholder: `단위: g` when a unit exists, otherwise `''`.
String unitPlaceholder(CategoryAttribute? a) {
  final u = _unitOf(a);
  return u.isNotEmpty ? '단위: $u' : '';
}
