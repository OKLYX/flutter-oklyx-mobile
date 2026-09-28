import 'package:flutter/material.dart';

/// 예약 발송 시각 선택 — 날짜 → 시각 두 번 고른다 (FEATURE_2609_75 / D4·D20).
///
/// **용도**: 발송처리 다이얼로그의 예약 시각 · 예약 발송 현황의 [시각 변경] 두 곳이 같이 쓴다.
/// **반환**: KST 벽시계 문자열 'yyyy-MM-ddTHH:mm:00'. 어느 단계든 취소하면 null.
/// **파일**: lib/features/shipping_label/presentation/utils/reserved_time_picker.dart
///
/// 🔴 [current] 는 서버가 준 KST 벽시계다 — 오프셋 없는 문자열을 `DateTime.tryParse` 로 읽으면 필드 값이
///    그대로 남는다(시간대 변환 없음). `toUtc()`·`toLocal()` 을 부르지 않는다.
/// ⚠️ 지난 시각 판정은 서버가 한다(`지난 시각은 고를 수 없습니다`) — 여기서 막지 않는다.
/// ❌ 화면마다 날짜·시각 선택 사본을 만들지 말 것.
Future<String?> pickReservedExecuteAt(
  BuildContext context,
  String? current,
) async {
  final base = (current == null ? null : DateTime.tryParse(current)) ??
      DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: DateTime(base.year, base.month, base.day),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
  );
  if (time == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}'
      'T${two(time.hour)}:${two(time.minute)}:00';
}
