import 'package:flutter/material.dart';

import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_type_option.dart';

/// 문의 유형 전환 탭 — `ClaimTypeTabs` 와 같은 관용구(`SegmentedButton`).
///
/// **용도**: 목록의 유형 축을 바꾼다. 전환은 **서버 재조회**를 부른다.
/// **필수 규칙**: 후보와 라벨은 [options] 로 받는다 — `GET /api/inquiries/types` 가 유일한
/// 원천이다(PLAN M2). 앱에 유형 라벨 상수표를 만들지 말 것.
/// **파일**: lib/features/inquiry/presentation/widgets/inquiry_type_tabs.dart
///
/// **사용 예제**:
/// ```dart
/// InquiryTypeTabs(
///   options: s.typeOptions,
///   value: s.selectedType,
///   enabled: !s.busy,
///   onChanged: (t) => bloc.add(SelectType(type: t)),
/// )
/// ```
///
/// ⚠️ 유형이 1개 이하면 **줄 자체를 그리지 않는다**(웹과 같은 규칙) — 고를 것이 없는 탭은
/// 자리만 차지한다. 그래서 화면은 `options.length > 1` 을 확인하지 않아도 된다.
/// ❌ 건수 배지 금지 — 다른 유형은 조회하지 않았으므로 거짓 숫자가 된다.
class InquiryTypeTabs extends StatelessWidget {
  final List<InquiryTypeOption> options;

  /// 선택된 유형. null 이면(=`/types` 실패) 아무것도 그리지 않는다.
  final InquiryType? value;
  final ValueChanged<InquiryType> onChanged;

  /// 조회·동기화 중에는 false — 전환 연타로 요청이 겹치지 않게 한다.
  final bool enabled;

  const InquiryTypeTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value;
    if (options.length < 2 || selected == null) {
      return const SizedBox.shrink();
    }
    // 선택 값이 후보에 없으면 SegmentedButton 이 assert 로 죽는다 — 그릴 수 없는 탭이다.
    if (!options.any((option) => option.code == selected)) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<InquiryType>(
        segments: options
            .map((option) => ButtonSegment<InquiryType>(
                  value: option.code,
                  label: Text(option.label),
                ))
            .toList(),
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: enabled ? (set) => onChanged(set.first) : null,
      ),
    );
  }
}
