// Measure notice detection + composition — port of web
// `app/dashboard/master-products/[id]/components/optionNoticeCompose.ts`
// (@09208a0).
// File: lib/features/master_product/presentation/logic/option_notice_compose.dart
//
// ⚠️ Keep the format literal (`개`) inside this file only.
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';

const List<String> _measureTokens = ['용량', '중량', '무게', '부피'];

/// A measure notice = the key has `수량` AND one of the measure tokens, both
/// on a word boundary.
bool isMeasureNotice(String key) =>
    hasBoundaryToken(key, '수량') &&
    _measureTokens.any((t) => hasBoundaryToken(key, t));

/// `${measured} ${qty}개`; `''` when the measure is blank or [qty] <= 0.
/// ⚠️ [measured] already carries its unit (`320g`).
String composeMeasureNotice(String measured, int qty) {
  final m = measured.trim();
  if (m.isEmpty || qty <= 0) {
    return '';
  }
  return '$m $qty개';
}
