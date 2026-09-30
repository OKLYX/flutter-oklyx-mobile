import 'package:intl/intl.dart';

// Mobile counterparts of the web number/amount formatting (FEATURE_2609_80).
// ⚠️ Each web file keeps its own `formatWon`; port it into each Dart file the same way and use [koNumber] here for the number part.

final NumberFormat _ko = NumberFormat.decimalPattern('ko');
final NumberFormat _krw =
    NumberFormat.currency(locale: 'ko', symbol: '₩', decimalDigits: 0);

/// Web `value.toLocaleString('ko-KR')`.
String koNumber(num value) => _ko.format(value);

/// Web `infrastructure/utils/money.ts#formatKrw` — `-` when absent.
String formatKrw(num? value) => value == null ? '-' : _krw.format(value);
