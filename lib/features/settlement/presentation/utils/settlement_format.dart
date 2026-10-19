// Labels and formatters of the 「정산관리」 screens (「정산 내역」 and 「매출」) —
// the mobile port of the helpers in the web `src/domain/entities/Settlement.ts`
// (FEATURE_2610_20 / D22: same words and colors as the web). Unknown codes are
// shown as they are, so a new market or enum never leaves a cell blank.
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';

const Map<String, String> _platformLabels = {
  'COUPANG': '쿠팡',
  'NAVER': '네이버',
  'ELEVENST': '11번가',
};

const Map<String, String> _settlementTypeLabels = {
  'WEEKLY': '주정산',
  'MONTHLY': '월정산',
  'DAILY': '일정산',
  'ADDITIONAL': '추가정산',
  'RESERVE': '잔액지급',
  'UNKNOWN': '기타',
};

const Map<String, String> _payoutStatusLabels = {
  'SCHEDULED': '예정',
  'PAID': '완료',
  'UNKNOWN': '미확인',
};

const Map<String, String> _adjustmentLabels = {
  'DEDUCTION': '차감액',
  'DEBT_CARRIED': '전주 채무 이월',
  'PENDING_RELEASE': '보류 해제 예정액',
  'OTHER': '기타 조정',
};

const Map<String, String> _causeLabels = {
  'FEE_RATE': '수수료율 차이',
  'FEE_VAT': '수수료 부가세 차이',
  'SELLER_COUPON': '셀러 쿠폰 부담',
  'DELIVERY': '배송비',
  'REFUND': '환불',
  'UNKNOWN_BASE': '수수료 기준 없음',
  'ROUNDING': '반올림·기타',
  'NONE': '차이 없음',
  'UNMATCHED': '미분류',
};

/// The detail notice of an 11st payout (`reconStatus == 'NO_TOTAL'`, D29) —
/// gray, not a warning.
const String kNoTotalNotice = '11번가는 입금 총액을 따로 주지 않아 맞춰 볼 수 없습니다. '
    '금액은 11번가가 알려 준 정산 예정 금액의 합입니다.';

String _label(Map<String, String> dictionary, String? code) =>
    code == null || code.isEmpty ? '—' : (dictionary[code] ?? code);

String platformLabel(String? platform) => _label(_platformLabels, platform);
String settlementTypeLabel(String? type) => _label(_settlementTypeLabels, type);
String payoutStatusLabel(String? status) => _label(_payoutStatusLabels, status);
String adjustmentLabel(String? type) => _label(_adjustmentLabels, type);
String causeLabel(String? cause) => _label(_causeLabels, cause);

/// D40: 「입금 확인 필요」 when the server flags it, otherwise [payoutStatusLabel].
String payoutStatusText(PayoutSummary row) =>
    row.paymentCheckNeeded ? '입금 확인 필요' : payoutStatusLabel(row.status);

/// D14: the market name in a sentence — 「마켓」 when no channel is chosen or the
/// platform has no name.
String marketName(String? platform) =>
    platform != null && _platformLabels.containsKey(platform)
        ? _platformLabels[platform]!
        : '마켓';

bool _endsWithFinalConsonant(String word) {
  if (word.isEmpty) {
    return false;
  }
  final code = word.codeUnitAt(word.length - 1);
  return code >= 0xAC00 && code <= 0xD7A3 && (code - 0xAC00) % 28 != 0;
}

/// 「쿠팡」 → 「쿠팡이」, 「11번가」 → 「11번가가」, 「마켓」 → 「마켓이」.
String withSubjectParticle(String word) =>
    '$word${_endsWithFinalConsonant(word) ? '이' : '가'}';

/// 「쿠팡」 → 「쿠팡을」, 「11번가」 → 「11번가를」, 「마켓」 → 「마켓을」.
String withObjectParticle(String word) =>
    '$word${_endsWithFinalConsonant(word) ? '을' : '를'}';

/// Channel name: 「쿠팡 · 메인」; an empty alias reads 「채널 #12」.
String channelLabel(String? platform, String? accountAlias, int? accountId) {
  final alias = accountAlias?.trim() ?? '';
  return '${platformLabel(platform)} · '
      '${alias.isNotEmpty ? accountAlias : '채널 #${accountId ?? '—'}'}';
}

final NumberFormat _won = NumberFormat.decimalPattern('ko');

/// Amount rounded to the won with thousands separators; null = `—`.
String formatMoney(num? value) =>
    value == null ? '—' : _won.format(value.round());

/// Signed amount (`+1,000` / `-1,000`); 0 has no sign; null = `—`.
String formatSigned(num? value) {
  if (value == null) {
    return '—';
  }
  final rounded = value.round();
  return rounded > 0 ? '+${_won.format(rounded)}' : _won.format(rounded);
}

/// Measured rate (0~1) → `11.5%`.
String formatRatio(num? value) =>
    value == null ? '—' : '${(value * 100).toStringAsFixed(1)}%';

/// Count with thousands separators.
String formatCount(num value) => _won.format(value);

/// Adjustment sign — same rule as the server's
/// `SettlementReconciler.signedAmount`.
int adjustmentSign(String? type) =>
    type == 'DEDUCTION' || type == 'DEBT_CARRIED' ? -1 : 0;

/// Informational adjustment = left out of the equation (「정보성 · 합계 제외」).
bool isInformationalAdjustment(String? type) => adjustmentSign(type) == 0;

/// Two `yyyy-MM-dd` → `09-01 ~ 09-07`; both missing = `—`.
String formatDateRange(String? from, String? to) {
  String short(String? value) =>
      value == null || value.length < 5 ? '—' : value.substring(5);
  return from == null && to == null ? '—' : '${short(from)} ~ ${short(to)}';
}

/// `2026-09-15T10:20:30` → `09-15 10:20` (the retry time of the
/// minimum-interval notice).
String formatDateTime(String? value) {
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) {
    return '—';
  }
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(parsed.month)}-${pad(parsed.day)} '
      '${pad(parsed.hour)}:${pad(parsed.minute)}';
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Local `yyyy-MM-dd` (no UTC conversion).
String toDateText(DateTime date) =>
    '${date.year}-${_pad2(date.month)}-${_pad2(date.day)}';

/// Today in KST, date only — the last day an 11st arrival date may take
/// (FEATURE_2610_20 / D38). A phone set to another time zone still stops at
/// the Korean date.
DateTime todayKst() {
  final kst = DateTime.now().toUtc().add(const Duration(hours: 9));
  return DateTime(kst.year, kst.month, kst.day);
}

/// Backfill month choices — the last [months] months, newest first (`value` =
/// `yyyy-MM`, `label` = 「2026년 9월」).
List<({String value, String label})> buildSettlementMonthOptions(
    {int months = 12, DateTime? today}) {
  final now = today ?? DateTime.now();
  final options = <({String value, String label})>[];
  for (var i = 0; i < months; i++) {
    final date = DateTime(now.year, now.month - i);
    options.add((
      value: '${date.year}-${_pad2(date.month)}',
      label: '${date.year}년 ${date.month}월'
    ));
  }
  return options;
}

/// `yyyy-MM` → that month's `from` · `to`; `to` never passes today.
({String from, String to}) monthRange(String month, {DateTime? today}) {
  final parts = month.split('-');
  final year = int.parse(parts[0]);
  final monthNumber = int.parse(parts[1]);
  final lastDay = DateTime(year, monthNumber + 1, 0).day;
  final from = '$year-${_pad2(monthNumber)}-01';
  final lastDate = '$year-${_pad2(monthNumber)}-${_pad2(lastDay)}';
  final todayDate = toDateText(today ?? DateTime.now());
  return (
    from: from,
    to: lastDate.compareTo(todayDate) > 0 ? todayDate : lastDate
  );
}

/// `yyyy-MM` → 「2026년 9월」; another shape stays as it is.
String monthLabel(String month) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(month);
  return match == null
      ? month
      : '${match.group(1)}년 ${int.parse(match.group(2)!)}월';
}

/// `fromMonth`..`toMonth` ascending (at most 24); an inverted range is empty.
List<String> monthsBetween(String fromMonth, String toMonth) {
  if (fromMonth.isEmpty ||
      toMonth.isEmpty ||
      fromMonth.compareTo(toMonth) > 0) {
    return const [];
  }
  final parts = fromMonth.split('-');
  final year = int.parse(parts[0]);
  final monthNumber = int.parse(parts[1]);
  final months = <String>[];
  for (var step = 0; step < 24; step++) {
    final cursor = DateTime(year, monthNumber + step);
    final value = '${cursor.year}-${_pad2(cursor.month)}';
    if (value.compareTo(toMonth) > 0) {
      break;
    }
    months.add(value);
  }
  return months;
}
