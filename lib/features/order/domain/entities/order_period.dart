/// 주문내역 조회 기간.
///
/// **용도**: '최근 2주'(서버 기본 창 = coupang.sync-days) + 최근 12개월 월 단위 옵션.
/// **파일**: lib/features/order/domain/entities/order_period.dart
///
/// ⚠️ '최근 2주'는 **from/to 를 보내지 않는다** — 서버 기본 창을 그대로 탄다(PLAN D3).
///    서버의 sync-days 를 바꾸면 이 라벨도 함께 고쳐야 한다.
const String kRecentPeriod = 'RECENT';

class OrderPeriodOption {
  final String value; // kRecentPeriod | 'YYYY-MM'
  final String label; // '최근 2주' | '2026년 8월'

  const OrderPeriodOption({required this.value, required this.label});
}

/// 월별 주문 건수 (GET /api/orders/months). 라벨의 '(데이터 없음)' 판정에만 쓴다.
class OrderMonth {
  final String ym; // 'YYYY-MM'
  final int count;

  const OrderMonth({required this.ym, required this.count});
}

/// 최근 2주 + 최근 [months]개월(현재 달 포함).
///
/// 주문이 없는 달은 **지우지 않고 '(데이터 없음)'** 을 붙인다(PLAN D18) — 지우면 그 달을 고를 수 없고
/// 후속 기능(2609_10)의 백필 진입점까지 사라진다. [monthsWithData] 는 'YYYY-MM' 집합.
///
/// ⚠️ [monthsWithData] 가 **null 이면 데이터 유무를 아예 표시하지 않는다** — 월별 건수 API 가 없는
/// 화면(반품/교환, 2609_18)이 쓴다. `const {}` 를 넘기면 전 달에 '(데이터 없음)' 이 붙어 거짓
/// 정보가 되므로, 건수를 모르는 화면은 인자를 생략하거나 null 을 넘긴다.
List<OrderPeriodOption> buildPeriodOptions({
  Set<String>? monthsWithData,
  DateTime? today,
  int months = 12,
}) {
  final now = today ?? DateTime.now();
  final options = <OrderPeriodOption>[
    const OrderPeriodOption(value: kRecentPeriod, label: '최근 2주'),
  ];
  for (var i = 0; i < months; i++) {
    // month 가 0/-1 이어도 DateTime 이 정규화한다.
    final d = DateTime(now.year, now.month - i, 1);
    final value = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    final base = '${d.year}년 ${d.month}월';
    options.add(OrderPeriodOption(
      value: value,
      label: (monthsWithData == null || monthsWithData.contains(value))
          ? base
          : '$base (데이터 없음)',
    ));
  }
  return options;
}

/// (from, to) 문자열. kRecentPeriod 면 null — 파라미터를 보내지 않는다는 뜻이다.
///
/// 🔴 `toIso8601String()` / `toUtc()` 을 쓰지 않는다 — UTC 변환은 KST 에서 하루 앞선 날짜를 만든다.
({String from, String to})? toPeriodRange(String value) {
  if (value == kRecentPeriod) return null;
  final parts = value.split('-');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return null;
  // 다음 달 0일 = 이번 달 말일.
  final lastDay = DateTime(year, month + 1, 0).day;
  final mm = month.toString().padLeft(2, '0');
  return (
    from: '$year-$mm-01',
    to: '$year-$mm-${lastDay.toString().padLeft(2, '0')}',
  );
}

/// 월 옵션이면 stale 안내를 띄운다(PLAN D7).
bool isMonthPeriod(String value) => value != kRecentPeriod;
