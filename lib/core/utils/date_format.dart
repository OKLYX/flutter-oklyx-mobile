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
/// Text('마지막 동기화: ${formatOrderDateTime(state.lastSyncedAt)}')
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
