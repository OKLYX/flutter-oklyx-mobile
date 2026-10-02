import 'package:flutter/material.dart';

import '../../domain/entities/claim.dart';
import 'claim_action_sheet.dart';

/// Bottom sheet for choosing the exchange rejection reason
/// (FEATURE_2609_21 / 07).
///
/// **Purpose**: takes the one extra input (rejection reason code) of an action
/// with `requires == 'REJECT_CODE'`.
/// **File**: lib/features/claim/presentation/widgets/claim_reject_sheet.dart
///
/// **Usage**:
/// ```dart
/// showAppSheet<void>(
///   context,
///   builder: (ctx) => ClaimRejectSheet(
///     claim: claim,
///     action: action,
///     onSubmit: (rejectCode) => _execute(
///       ClaimActionRequest(action: action.action, rejectCode: rejectCode),
///     ),
///   ),
/// );
/// ```
///
/// 🔴 **No code→label map is built in the app** (D19). The choices come down
/// from the server as [ClaimAction.choices] and both value and label are used
/// as they are — if Coupang's rejection codes lived in the app, **the app would
/// have to be redeployed** the day Naver uses a different code set (unlike the
/// web, it is not reflected immediately).
///
/// ⚠️ **`claimType` is not looked at** — the fact that this exists only for
/// exchanges is already expressed by the server through `availableActions`.
/// Deciding again here would put the decision in two places and diverge from
/// the web (06).
/// ⚠️ **Do not add a free-text reason field** — Coupang does not accept it. It
/// would be a field that is filled in but never sent.
/// ⚠️ **This sheet does not send.** Its job ends at the confirmation; it closes
/// the sheet first and then calls [onSubmit] once. Sending, loading, toasts and
/// reloading are all handled by [ClaimActionSheet] — the content of a bottom
/// sheet is not redrawn by the parent's `setState`, so the sending state cannot
/// be drawn inside the sheet.
class ClaimRejectSheet extends StatefulWidget {
  final Claim claim;

  /// 서버 항목 그대로. 제목·확인 버튼 라벨은 [ClaimAction.label] 을 쓴다(D18).
  final ClaimAction action;

  /// 확인까지 마친 뒤 선택된 거부 사유 코드. **1회만** 호출된다.
  final ValueChanged<String> onSubmit;

  const ClaimRejectSheet({
    super.key,
    required this.claim,
    required this.action,
    required this.onSubmit,
  });

  @override
  State<ClaimRejectSheet> createState() => _ClaimRejectSheetState();
}

class _ClaimRejectSheetState extends State<ClaimRejectSheet> {
  /// null = 미선택 → 확인 버튼 비활성. 시트가 닫히면 State 째로 사라진다(07 Step 6).
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final label =
        widget.action.label.isEmpty ? widget.action.action : widget.action.label;

    return Padding(
      // 키보드는 없지만 내비바 오버레이(ScaffoldWithNavBar)에 가리지 않게 하단 여백을 둔다.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // 개수를 코드에 가정하지 않는다 — 지금 쿠팡이 2개일 뿐, 플랫폼이 5개를 줄 수도 있다.
          ...widget.action.choices.map(
            (c) => RadioListTile<String>(
              value: c.code,
              groupValue: _selected,
              contentPadding: EdgeInsets.zero,
              title: Text(c.label.isEmpty ? c.code : c.label),
              onChanged: (v) => setState(() => _selected = v),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size(0, 48), // 터치 타깃 48dp
            ),
            onPressed: _selected == null ? null : _onConfirm,
            child: Text(label),
          ),
        ],
      ),
    );
  }

  /// 2단 확인(D10) → 시트를 닫고 → 전송을 부모에 넘긴다.
  ///
  /// ⚠️ [ClaimActionSheet] 는 `REJECT_CODE` 에서 자기 확인 다이얼로그를 띄우지 않는다 —
  /// 둘 다 띄우면 확인이 3단이 되고, 사유가 안 보이는 확인이 하나 낀다.
  Future<void> _onConfirm() async {
    final code = _selected;
    if (code == null) return;
    final c = widget.claim;
    // 사유 문구도 서버 것이다(D19) — 앱이 짓지 않는다.
    final reason = widget.action.choices
        .firstWhere(
          (choice) => choice.code == code,
          orElse: () => ActionChoice(code: code, label: code),
        )
        .label;

    final confirmed = await showClaimConfirmDialog(
      context,
      title: c.itemName ?? '-',
      // D10 은 상품명·수량·금액을 요구하지만 교환 거부에는 확정되는 금액이 없다 —
      // 그 자리를 **사유**가 대신한다(06 Step 2 와 같은 판단).
      lines: [
        '수량 ${c.quantity}개',
        '사유: $reason',
        // 06 문구 표 기준. 다이얼로그 폭 때문에 웹의 '교환을 거부하면 …' 보다 짧다.
        '거부하면 되돌릴 수 없습니다.',
      ],
      confirmLabel:
          widget.action.label.isEmpty ? widget.action.action : widget.action.label,
    );
    if (!confirmed || !mounted) return;

    // 닫고 보낸다 — 이중 탭이 구조적으로 막히고, 진행 표시는 액션 영역 버튼이 맡는다.
    Navigator.pop(context);
    widget.onSubmit(code);
  }
}
