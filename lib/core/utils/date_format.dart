/// 주문 화면 공용 날짜 포맷 유틸.
///
/// **용도**: 백엔드가 내려주는 ISO LocalDateTime 문자열을 목록·상세·카드에서
/// 같은 형식으로 표시한다.
/// **필수 규칙**: 주문 관련 화면에서 `String?` 시각을 표시할 때는 반드시 이 함수를 쓴다.
/// 화면마다 `_formatDate` 사본을 만들지 말 것.
/// **파일**: lib/core/utils/date_format.dart
///
/// **사용 예제**:
/// Text('결제일 ${formatOrderDateTime(order.paidAt)}')
/// Text('마지막 동기화: ${formatRelativeTime(state.lastSyncedFromServer)}')  // 상대 표기
///
/// ISO LocalDateTime → 'yyyy-MM-dd HH:mm'. null/파싱 실패 시 '-' 또는 원본 반환.
String formatOrderDateTime(String? value) {
  if (value == null || value.isEmpty) return '-';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}

/// 서버의 ISO LocalDateTime(오프셋 없는 UTC) → '3분 전' / '2시간 전' / '4일 전'.
/// null·파싱 실패 시 '기록 없음'.
///
/// **용도**: 백그라운드 동기화(FEATURE_2609_49)가 도는 화면의 `마지막 동기화` 표기.
/// 절대 시각이 필요한 자리(결제일·주문일)는 [formatOrderDateTime] 를 그대로 쓴다.
/// **파일**: lib/core/utils/date_format.dart
///
/// 🔴 The sync timestamp is naive UTC (the server container has no TZ set), but DateTime.parse()
/// reads an offset-less string as LOCAL time. Reinterpreting it as UTC pins it; without that the
/// banner says "9시간 전" right after a successful sync.
/// ⚠️ Do NOT copy this into [formatOrderDateTime] — the timestamps it renders (paidAt, order dates)
/// come from Coupang as KST wall-clock, not UTC.
String formatRelativeTime(String? value) {
  if (value == null || value.isEmpty) return '기록 없음';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '기록 없음';
  // Reinterpret the naive string as UTC, then compare in UTC.
  final target = DateTime.utc(parsed.year, parsed.month, parsed.day,
      parsed.hour, parsed.minute, parsed.second);
  final minutes = DateTime.now().toUtc().difference(target).inMinutes;
  if (minutes < 1) return '방금 전';
  if (minutes < 60) return '$minutes분 전';
  final hours = minutes ~/ 60;
  if (hours < 24) return '$hours시간 전';
  return '${hours ~/ 24}일 전';
}

/// 마켓이 준 KST 벽시계 시각(주문일·접수일·문의일) → '3시간 전'.
/// null·파싱 실패 시 '기록 없음'.
///
/// **용도**: 알림(처리해야 할 일) 목록의 `occurredAt` 표기(FEATURE_2609_51 / D8).
/// **파일**: lib/core/utils/date_format.dart
///
/// 🔴 [formatRelativeTime] 과 **다른 함수다.** 그쪽은 서버가 낙인한 시각(오프셋 없는 UTC)을
///    UTC 로 재해석하는데, 이 값들은 마켓이 이미 KST 로 준 벽시계라 그렇게 하면 9시간 어긋난다
///    — 이 파일 위쪽 주석이 경고하는 바로 그 경우다(방금 들어온 주문이 '9시간 전'으로 보인다).
/// ❌ 둘을 합치지 말 것. 어느 쪽을 쓸지는 **값의 출처**로 정한다(서버 낙인 vs 마켓 원본).
String formatMarketRelativeTime(String? value) {
  if (value == null || value.isEmpty) return '기록 없음';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '기록 없음';
  // UTC 로 재해석하지 않는다 — 오프셋 없는 문자열을 기기 로컬(KST)로 읽고 로컬끼리 비교한다.
  final minutes = DateTime.now().difference(parsed).inMinutes;
  if (minutes < 1) return '방금 전';
  if (minutes < 60) return '$minutes분 전';
  final hours = minutes ~/ 60;
  if (hours < 24) return '$hours시간 전';
  return '${hours ~/ 24}일 전';
}
