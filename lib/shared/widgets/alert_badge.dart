import 'package:flutter/material.dart';

/// 메뉴 항목 옆 처리 대기 건수 배지 (FEATURE_2609_49 / D9).
///
/// **용도**: Drawer 메뉴에서 "여기 볼 게 있다"를 숫자로 알린다.
/// **필수 규칙**: 건수 배지가 필요한 자리는 이 Widget 을 쓴다(색·크기를 화면마다 정하지 말 것).
/// **파일**: lib/shared/widgets/alert_badge.dart
///
/// **사용 예제**:
/// // 1) 메뉴 항목 우측
/// ListTile(title: const Text('반품/교환'), trailing: AlertBadge(count: state.openClaims))
///
/// // 2) 그룹 헤더(ExpansionTile 은 trailing 을 화살표가 쓴다 → title 안에 둔다)
/// ExpansionTile(
///   title: Row(children: [const Text('주문관리'), AlertBadge(count: state.total)]),
/// )
///
/// ⚠️ 0 이면 `SizedBox.shrink()` — 빈 동그라미를 남기면 항상 뭔가 있는 것처럼 보인다.
/// ⚠️ 99 초과는 '99+' 로 줄인다(원 크기가 메뉴 줄을 밀지 않게).
/// ❌ ListTile 의 `trailing` 에 Text 로 직접 숫자를 넣지 말 것.
/// ❌ 색을 하드코딩하지 말 것 — 테마의 `colorScheme.error` 를 쓴다.
class AlertBadge extends StatelessWidget {
  /// 표시할 건수. 0 이하면 아무것도 그리지 않는다.
  final int count;

  const AlertBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 22),
      decoration: BoxDecoration(
        color: scheme.error,
        // 한 자리 수에서는 원, 세 자리('99+')에서는 알약 모양이 된다.
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: scheme.onError,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
