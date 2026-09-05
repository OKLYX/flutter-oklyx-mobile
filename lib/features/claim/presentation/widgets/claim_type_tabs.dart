import 'package:flutter/material.dart';

import '../../domain/entities/claim.dart';

/// 반품 / 교환 전환 탭 — 구매목록 `_TabSwitcher` 와 같은 관용구(`SegmentedButton`).
///
/// **용도**: 클레임 목록의 종류 축을 바꾼다. 전환은 **서버 재조회**를 부른다.
/// **필수 규칙**: 라벨은 [getClaimTypeLabel] 하나만 쓴다(라벨표 사본 금지).
/// **파일**: lib/features/claim/presentation/widgets/claim_type_tabs.dart
///
/// **사용 예제**:
/// ```dart
/// ClaimTypeTabs(
///   value: s.claimType,
///   enabled: !s.isSearching,
///   onChanged: (t) => bloc.add(SelectClaimType(type: t)),
/// )
/// ```
///
/// ⚠️ 상태 칩(`ClaimStatusFilterBar`)과 형태를 다르게 두는 것이 의도다 — 이 전환은
/// 서버 재조회이고 칩은 클라이언트 필터라, 같은 모양이면 사용자가 비용을 구분할 수 없다.
/// ❌ 건수 배지 금지 — 다른 탭은 조회하지 않았으므로 거짓 숫자가 된다.
class ClaimTypeTabs extends StatelessWidget {
  final ClaimType value;
  final ValueChanged<ClaimType> onChanged;

  /// 조회 중에는 false — 전환 연타로 요청이 겹치지 않게 한다.
  final bool enabled;

  const ClaimTypeTabs({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ClaimType>(
        segments: ClaimType.values
            .map((type) => ButtonSegment<ClaimType>(
                  value: type,
                  label: Text(getClaimTypeLabel(type)),
                ))
            .toList(),
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged:
            enabled ? (set) => onChanged(set.first) : null,
      ),
    );
  }
}
