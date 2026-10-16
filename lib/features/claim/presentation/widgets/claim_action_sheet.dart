import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/carrier_option.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/domain/usecases/shipping_label_usecase.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/claim_usecase.dart';
import 'claim_reason_sheet.dart';
import 'claim_reject_sheet.dart';

/// Action area of the claim detail (FEATURE_2609_21 / 04).
///
/// **Purpose**: draws the server's [Claim.availableActions] as buttons and,
/// after a run, hands the re-read claim up through [onActionDone].
/// **File**: lib/features/claim/presentation/widgets/claim_action_sheet.dart
///
/// **Usage**:
/// ```dart
/// ClaimActionSheet(
///   claim: _claim,
///   onActionDone: (updated) => setState(() => _claim = updated),
/// )
/// ```
///
/// 🔴 **No branching on status codes.** What to show is decided by the
/// server's `availableActions` (D1), and branching is by `requires` only — a
/// `switch` on the `action` code would need a redesign the day the 4 exchange
/// actions arrive, and the web (03) would show other buttons for the same
/// claim. Coupang and 11st claims go through the same rule
/// (FEATURE_2610_17 / D15).
///
/// ⚠️ **No BLoC** (D9 / 04 Step 5). The list `ClaimListBloc` is made by the
/// list screen's `BlocProvider(create:)` and cannot be reached from the detail
/// (`registerFactory`, so `getIt` returns another instance), and the only
/// value an action changes is the detail's own `availableActions`.
/// ⚠️ **No optimistic update** (D7) — the status label is not changed ahead.
/// The marketplace status comes with the next sync.
/// ⚠️ Mobile has no ADMIN gate — the server gives a non-ADMIN an empty list,
/// and a 403 is the last line of defense if a button is pressed anyway (D13).
/// Do not add a role lookup.
class ClaimActionSheet extends StatefulWidget {
  final Claim claim;

  /// 액션 성공(또는 409) 뒤 단건 재조회한 클레임. 상세 페이지가 `setState` 로 받아 그린다.
  final ValueChanged<Claim> onActionDone;

  const ClaimActionSheet({
    super.key,
    required this.claim,
    required this.onActionDone,
  });

  @override
  State<ClaimActionSheet> createState() => _ClaimActionSheetState();
}

class _ClaimActionSheetState extends State<ClaimActionSheet> {
  // 03 의 문구 표가 단일 출처다 — 웹과 문자 단위로 같아야 한다(두 화면이 같은 사건을 다르게
  // 설명하면 사용자는 둘 중 하나를 버그로 읽는다).
  static const _successMessage = '처리 요청을 보냈습니다. 다음 동기화 후 상태가 갱신됩니다.';
  static const _conflictMessage = '이미 처리된 접수입니다.';
  static const _forbiddenMessage = '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
  static const _rawResponseTitle = '마켓 응답 보기';

  /// Notice for a round the marketplace rejected and only our ledger kept
  /// (2609_70 / D6 · FEATURE_2610_17 / D18 · D22).
  /// 🔴 Not a failure but **half a success** — shown in red, the user would
  /// think the record failed too.
  static const _localRecordMessage =
      '마켓에는 반영되지 않았습니다. 회수송장은 우리 기록에만 저장했습니다.';

  /// X3(재발송 송장)의 400 안내 꼬리말. **클라이언트가 붙이는 유일한 문구**다 —
  /// 05 Step 5 의 박스 alias 가 실제 스키마와 다르면 10분이 지나도 같은 400 이 오는데,
  /// 이 줄이 없으면 사용자는 "아직 이른가 보다" 하며 무한히 재시도한다.
  static const _reshipRetryHint = '여러 번 반복되면 관리자에게 알려주세요.';

  /// 🔴 **This widget branches on the `action` code in exactly two places** —
  /// ① the helper text of the invoice sheet ([_invoiceSubtitles]) ② the hint
  /// appended to the 400 of X3 and reopening the sheet ([_execute]).
  /// They are **intentional exceptions** to the "branch only on `requires`"
  /// rule and must not grow — if a third one is about to appear, the server is
  /// missing something it should send down.
  static const _actionExchangeReshipInvoice = 'EXCHANGE_RESHIP_INVOICE';

  /// 교환에는 송장 액션이 둘이라 제목만으로는 어느 쪽에 넣는지 알 수 없다.
  /// 제목은 서버 `label`, 이 보조 문구만 앱이 붙인다(웹 06 과 **같은 문자열**).
  static const _invoiceSubtitles = <String, String>{
    'EXCHANGE_COLLECT_INVOICE': '고객에게서 받아오는 택배',
    _actionExchangeReshipInvoice: '고객에게 다시 보내는 택배',
  };

  /// 전송 중인 액션 코드. null 이 아니면 모든 버튼이 잠긴다 —
  /// 되돌릴 수 없는 액션에서 더블탭은 실제 사고다.
  String? _sending;

  /// 택배사 코드표(마켓 코드). 발송처리와 **같은 원천**을 쓴다(D16).
  List<CarrierOption> _carriers = const [];
  bool _carriersLoading = false;
  String? _carriersError;

  bool get _hasInvoiceAction => widget.claim.availableActions
      .any((a) => a.requires == ClaimActionRequires.invoice);

  @override
  void initState() {
    super.initState();
    // 송장 액션이 하나라도 있을 때만 당겨온다 — 전부 NONE 인 클레임에서 상세를 열 때마다
    // 쓸모없는 요청이 늘 필요는 없다.
    if (_hasInvoiceAction) _loadCarriers();
  }

  Future<void> _loadCarriers() async {
    setState(() {
      _carriersLoading = true;
      _carriersError = null;
    });
    final result = await getIt<ShippingLabelUseCase>()
        .getCarrierOptions(platform: widget.claim.platform);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _carriersLoading = false;
        _carriersError = '택배사 목록을 불러오지 못했습니다.';
      }),
      (options) => setState(() {
        _carriersLoading = false;
        _carriers = options;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 서버가 빈 목록을 주면 영역 자체를 만들지 않는다 — 대부분의 클레임이 그 상태라
    // "처리할 작업이 없습니다" 같은 문구는 잡음이 된다.
    final actions = widget.claim.availableActions
        // 모르는 requires = 입력 폼을 만들 수 없다 → 버튼을 그리지 않는다(PLAN §8).
        .where((a) => ClaimActionRequires.supported.contains(a.requires))
        // No choices means nothing to pick → draw no **button** at all, not
        // an empty sheet. Blocking inside the sheet would leave a dead button
        // that opens nothing (07 Step 1).
        // Same for REASON (FEATURE_2610_17 / D34) — it picks from choices too.
        .where((a) =>
            (a.requires != ClaimActionRequires.rejectCode &&
                a.requires != ClaimActionRequires.reason) ||
            a.choices.isNotEmpty)
        .toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '처리',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Wrap 이라 라벨이 길어지면 접힌다 — 라벨은 서버가 주므로 Row+Expanded 로 고정하면
            // 문구가 길어지는 순간 오버플로가 난다.
            Wrap(
              spacing: 12, // 되돌릴 수 없는 버튼이 옆 버튼에 붙지 않게(오탭 1번 = 환불 확정)
              runSpacing: 12,
              children: actions.map(_buildActionButton).toList(),
            ),
            if (_hasInvoiceAction) _buildCarrierNotice(),
          ],
        ),
    );
  }

  /// 송장 버튼이 왜 비활성인지 알려준다 — 이유 없이 안 눌리는 버튼은 사용자를 막다른 길에 세운다.
  ///
  /// ⚠️ **조회 실패와 '선택할 수 있는 택배사 없음'은 문구가 다르다**(합치면 거짓 안내가 된다).
  /// 쿠팡은 서버가 코드표 전량을 내려주므로 빈 목록까지 오면 서버 쪽 문제이고, 등록된 코드만
  /// 내려가는 다른 플랫폼에서는 택배사 관리에 코드를 넣어야 한다는 뜻이다.
  Widget _buildCarrierNotice() {
    if (_carriersLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '택배사 목록을 불러오는 중입니다…',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    if (_carriersError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _carriersError!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadCarriers,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (_carriers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '선택할 수 있는 택배사가 없습니다. 잠시 후 다시 시도해주세요.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton(ClaimAction action) {
    final busy = _sending != null;
    final isSendingThis = _sending == action.action;
    final needsInvoice = action.requires == ClaimActionRequires.invoice;
    // 택배사 목록이 없으면 송장 액션은 누를 수 없다 — 빈 드롭다운을 띄우면 사용자가 무한히 탭한다.
    final blocked = needsInvoice && (_carriersLoading || _carriers.isEmpty);

    final style = action.irreversible
        ? FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            minimumSize: const Size(0, 48), // 터치 타깃 48dp
          )
        : FilledButton.styleFrom(minimumSize: const Size(0, 48));

    return FilledButton(
      style: style,
      onPressed: busy || blocked ? null : () => _onPressed(action),
      child: isSendingThis
          ? AppBusyLabel(action.label.isEmpty ? action.action : action.label)
          // 라벨은 서버 값 그대로 쓴다(D18) — 앱에 코드→라벨 상수를 만들지 않는다.
          : Text(action.label.isEmpty ? action.action : action.label),
    );
  }

  Future<void> _onPressed(ClaimAction action) async {
    if (action.requires == ClaimActionRequires.invoice) {
      await _openInvoiceSheet(action);
      return;
    }
    if (action.requires == ClaimActionRequires.rejectCode) {
      await _openRejectSheet(action);
      return;
    }
    if (action.requires == ClaimActionRequires.reason) {
      await _openReasonSheet(action);
      return;
    }
    if (action.irreversible && !await _confirm(action)) return;
    await _execute(ClaimActionRequest(action: action.action));
  }

  /// 거부 사유 시트(07). **자기 확인 다이얼로그를 띄우지 않는다** — 확인은 시트가 소유한다.
  /// 둘 다 띄우면 확인이 2단이 아니라 3단이 되고, 사유가 안 보이는 확인이 하나 낀다.
  Future<void> _openRejectSheet(ClaimAction action) async {
    String? rejectCode;
    await showAppSheet<void>(
      context,
      builder: (ctx) => ClaimRejectSheet(
        claim: widget.claim,
        action: action,
        // 시트가 먼저 닫히고 전송은 여기서 한다 — 시트 안에서는 `isSending` 이 갱신되지 않는다.
        onSubmit: (code) => rejectCode = code,
      ),
    );
    if (rejectCode == null || !mounted) return;
    await _execute(
      ClaimActionRequest(action: action.action, rejectCode: rejectCode),
    );
  }

  /// Reason sheet (`REASON`, FEATURE_2610_17 / D34). Like the reject sheet it
  /// owns its confirm — no second dialog here.
  Future<void> _openReasonSheet(ClaimAction action) async {
    ClaimReasonInput? input;
    await showAppSheet<void>(
      context,
      builder: (ctx) => ClaimReasonSheet(
        claim: widget.claim,
        action: action,
        onSubmit: (value) => input = value,
      ),
    );
    final chosen = input;
    if (chosen == null || !mounted) return;
    await _execute(
      ClaimActionRequest(
        action: action.action,
        rejectCode: chosen.code,
        reasonText: chosen.text,
      ),
    );
  }

  /// 2단 확인 (D10). 문구에 **무엇을 확정하는지 실명으로** 박는다 —
  /// "정말 하시겠습니까?" 만으로는 아무것도 막지 못한다.
  Future<bool> _confirm(ClaimAction action) async {
    final c = widget.claim;
    final details = <String>[
      '수량 ${c.quantity}개',
      // null 이면 줄을 뺀다 — '청구 안 함'과 '0원'은 다르다.
      if (c.returnShippingCharge != null) '반품비 ${c.returnShippingCharge}원',
    ].join(' · ');

    return showClaimConfirmDialog(
      context,
      title: c.itemName ?? '-',
      lines: [
        details,
        // 03 wording table; the exchange reject (07) wording goes through
        // `ClaimRejectSheet` into the same function. INVOICE = the 11st
        // exchange approve with the re-shipping invoice (FEATURE_2610_17 / D24).
        action.requires == ClaimActionRequires.invoice
            ? '이 교환을 승인하면 재발송 송장이 등록되며 되돌릴 수 없습니다.'
            : '이 반품을 승인하면 환불이 확정되며 되돌릴 수 없습니다.',
      ],
      confirmLabel: action.label.isEmpty ? action.action : action.label,
    );
  }

  /// Invoice input bottom sheet. `showAppSheet` + `viewInsets` keep it from
  /// being covered by the keyboard.
  ///
  /// The 400 of X3 (reship invoice) is an **early request**, so retrying is the
  /// normal path — that is why only on that 400 the sheet is reopened with the
  /// input kept as it was (so the user does not retype the carrier and invoice
  /// number). The sheet is not kept open while sending — the inside of the
  /// sheet is not redrawn by the parent's `setState`, so `isSending` would not
  /// update.
  Future<void> _openInvoiceSheet(ClaimAction action) async {
    _InvoiceInput? prefill;
    while (true) {
      final input = await showAppSheet<_InvoiceInput>(
        context,
        builder: (ctx) => _InvoiceSheet(
          // 제목은 서버 라벨(D18), 보조 문구만 앱이 붙인다 — 회수/재발송을 구분하는 유일한 표시다.
          title: action.label.isEmpty ? action.action : action.label,
          subtitle: _invoiceSubtitles[action.action],
          carriers: _carriers,
          initial: prefill,
        ),
      );
      // 취소·바깥 탭이면 입력값을 버린다(07 Step 6).
      if (input == null || !mounted) return;
      // An irreversible invoice action (the 11st exchange approve, D24) asks
      // once more after the input.
      if (action.irreversible && !await _confirm(action)) return;
      final retryable = await _execute(
        ClaimActionRequest(
          action: action.action,
          deliveryCompanyCode: input.deliveryCompanyCode,
          invoiceNumber: input.invoiceNumber,
        ),
      );
      if (!retryable || !mounted) return;
      prefill = input;
    }
  }

  /// 반환값 = **X3 의 이른 400** 인가(= 같은 입력으로 시트를 다시 열어 줄 만한 실패인가).
  /// 그 외의 모든 결과는 false 다 — 성공·409·502·권한·일반 400.
  Future<bool> _execute(ClaimActionRequest request) async {
    setState(() => _sending = request.action);
    final result = await getIt<ClaimUseCase>()
        .executeAction(widget.claim.id, request);
    // 상세를 벗어난 뒤 응답이 도착할 수 있다 — 가드 없이 context 를 쓰면 죽는다.
    if (!mounted) return false;

    bool retryable = false;
    await result.fold<Future<void>>(
      (failure) async => retryable = await _onFailure(failure, request),
      (actionResult) async {
        // 🔴 **No branching on the action code** — only the server's
        //    localRecordOnly decides (2609_70 / D6). After the re-read the
        //    server opens the resend button ([쿠팡에 다시 보내기] /
        //    [마켓에 다시 보내기], D7 · FEATURE_2610_17 / D22).
        if (actionResult.localRecordOnly) {
          _showLocalRecordNotice(actionResult);
        } else {
          showSuccessToast(context, _successMessage);
        }
        await _reload();
      },
    );

    // 잠금은 **재조회까지 끝난 뒤** 푼다 — 그 사이에 다시 누르면 낡은 버튼으로 재전송이 된다.
    if (!mounted) return false;
    setState(() => _sending = null);
    return retryable;
  }

  /// 반환값 = 같은 입력으로 송장 시트를 다시 열 것인가(X3 의 이른 400 뿐).
  Future<bool> _onFailure(Failure failure, ClaimActionRequest request) async {
    final f = failure is ClaimActionFailure ? failure : null;
    final status = f?.statusCode;
    if (status == 409) {
      // 재조회하면 availableActions 가 비어 버튼이 사라진다 —
      // 웹(03: 버튼 즉시 감춤)과 결과가 같다. 로컬에서 버튼만 지우지 않는다.
      showErrorToast(context, _conflictMessage);
      await _reload();
      return false;
    }
    if (status == 502) {
      // The marketplace's original text as is (D15). No translation or summary.
      _showRawResponse(f);
      return false;
    }
    if (status == 401 || status == 403) {
      showErrorToast(context, _forbiddenMessage);
      return false;
    }
    // 400(입력값·미등록 택배사·현재 상태에서 불가) 은 서버 메시지가 사유를 담고 있다.
    final message = f?.message ?? failure.message;
    if (status == 400 && request.action == _actionExchangeReshipInvoice) {
      // A reship invoice is accepted **about 10 minutes** after the receipt
      // confirmation — a 400 before that is not a mistake, it is just early.
      // The hint is appended to stop endless retries.
      //
      // Shown as an error (red, 6s) like every other failure in this method —
      // FEATURE_2610_02 D124 reversed the FEATURE_2609_21 rule that kept this
      // one in the notice color. The other 400s of the reship-invoice action
      // (e.g. unmapped carrier) pass through here too and get the same hint.
      // 🔴 Do not parse the server text to tell causes apart by color (it
      // breaks silently when the text changes).
      showErrorToast(context, '$message\n$_reshipRetryHint');
      return true;
    }
    showErrorToast(context, message);
    return false;
  }

  /// Marketplace rejection + local record (D6) notice. The marketplace's
  /// **original text** from the server is appended as is — no translation or
  /// summary (same rule as D15).
  void _showLocalRecordNotice(ClaimActionResult result) {
    final raw = [
      if (result.resultCode != null && result.resultCode!.isNotEmpty)
        result.resultCode!,
      if (result.resultMessage != null && result.resultMessage!.isNotEmpty)
        result.resultMessage!,
    ].join('\n');
    final body =
        raw.isEmpty ? _localRecordMessage : '$_localRecordMessage\n$raw';
    _showLongBody(body, warning: true);
  }

  /// The raw text of a 502 can be long, so it is opened in a dialog (a toast
  /// is enough when it is short).
  void _showRawResponse(ClaimActionFailure? f) {
    final raw = [
      if (f?.resultCode != null) f!.resultCode!,
      if (f?.resultMessage != null) f!.resultMessage!,
    ].join('\n');
    final body = raw.isEmpty ? (f?.message ?? '마켓 처리에 실패했습니다.') : raw;
    _showLongBody(body);
  }

  /// Long text goes to a dialog, short text to a toast — the two paths that
  /// show the marketplace's raw text (502 failure · local-record notice) use
  /// **the same place**.
  void _showLongBody(String body, {bool warning = false}) {
    if (body.length <= 60) {
      // warning == true: local-record notice (plain notice).
      // warning == false: the short raw text of a 502 failure (error).
      if (warning) {
        showNoticeToast(context, body);
      } else {
        showErrorToast(context, body);
      }
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(_rawResponseTitle),
        content: SingleChildScrollView(child: SelectableText(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 단건 재조회(D8). 실패해도 화면을 막지 않는다 — 전송 자체는 이미 끝났고,
  /// 낡은 버튼은 서버 409 가 다시 막는다.
  Future<void> _reload() async {
    final result = await getIt<ClaimUseCase>().getClaim(widget.claim.id);
    if (!mounted) return;
    result.fold((_) {}, widget.onActionDone);
  }

}

/// Confirmation for an irreversible claim action (D10) — shared by
/// [ClaimActionSheet] (return approval …) and [ClaimRejectSheet] (exchange
/// rejection) so both show the same dialog.
///
/// **File**: lib/features/claim/presentation/widgets/claim_action_sheet.dart
///
/// ```dart
/// final ok = await showClaimConfirmDialog(
///   context,
///   title: claim.itemName ?? '-',
///   lines: ['수량 3개', '사유: 고객이 교환요청을 철회함', '거부하면 되돌릴 수 없습니다.'],
///   confirmLabel: action.label,
/// );
/// ```
///
/// [lines]: the last line is the warning sentence; the lines before it are
/// the details (quantity · return fee · reason). They are joined into one
/// block of text — details, one blank line, warning (FEATURE_2610_02 · N9).
///
/// ⚠️ The standard dialog is used: two text buttons, the confirm label in red,
///    tapping outside cancels (D109 — the old "cancel is emphasized" rule of
///    FEATURE_2609_21 is withdrawn).
/// ⚠️ [confirmLabel] is the server label (D18) — the app does not invent one.
Future<bool> showClaimConfirmDialog(
  BuildContext context, {
  required String title,
  required List<String> lines,
  required String confirmLabel,
}) {
  final details = lines.length > 1 ? lines.sublist(0, lines.length - 1) : const <String>[];
  final warning = lines.isEmpty ? '' : lines.last;

  return showAppConfirmDialog(
    context,
    title: title,
    message: details.isEmpty ? warning : '${details.join('\n')}\n\n$warning',
    confirmText: confirmLabel,
    isDangerous: true,
  );
}

/// 송장 바텀시트가 돌려주는 입력값.
class _InvoiceInput {
  final String deliveryCompanyCode;
  final String invoiceNumber;

  const _InvoiceInput({
    required this.deliveryCompanyCode,
    required this.invoiceNumber,
  });
}

/// 택배사 + 송장번호 입력 바텀시트.
///
/// 전송은 하지 않는다 — 값만 모아 `Navigator.pop` 으로 돌려주고, 실행·에러 표시는
/// [ClaimActionSheet] 한 곳이 맡는다(전송 경로가 둘로 갈리면 잠금·가드도 둘이 된다).
class _InvoiceSheet extends StatefulWidget {
  final String title;

  /// 회수/재발송을 구분하는 한 줄. 반품 회수송장에는 없다(null).
  final String? subtitle;
  final List<CarrierOption> carriers;

  /// X3 의 이른 400 으로 다시 열릴 때만 채워진다 — 그 외에는 항상 null(빈 시트).
  final _InvoiceInput? initial;

  const _InvoiceSheet({
    required this.title,
    required this.carriers,
    this.subtitle,
    this.initial,
  });

  @override
  State<_InvoiceSheet> createState() => _InvoiceSheetState();
}

class _InvoiceSheetState extends State<_InvoiceSheet> {
  final TextEditingController _invoiceController = TextEditingController();
  String? _carrierCode;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    // 목록에 없는 코드를 넘기면 DropdownButtonFormField 가 assert 로 죽는다.
    final known = widget.carriers
        .any((o) => o.deliveryCompanyCode == initial.deliveryCompanyCode);
    if (known) _carrierCode = initial.deliveryCompanyCode;
    _invoiceController.text = initial.invoiceNumber;
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _carrierCode != null && _invoiceController.text.trim().isNotEmpty;

    return Padding(
      // 키보드가 입력칸을 가리지 않게 한다.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 값은 마켓 코드 자체다 — 쿠팡은 택배사 목록 API 가 없어 코드표 전량이 온다.
          // 서버가 등록 택배사를 맨 위로 정렬해 주므로 여기서 다시 정렬하지 않는다.
          DropdownButtonFormField<String>(
            value: _carrierCode,
            isExpanded: true, // 코드표가 길다 — 긴 이름이 overflow 하지 않게
            decoration: const InputDecoration(
              labelText: '택배사',
            ),
            items: widget.carriers
                .map(
                  (o) => DropdownMenuItem<String>(
                    value: o.deliveryCompanyCode,
                    child: Text(
                      o.registered ? '${o.carrierName} (등록)' : o.carrierName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _carrierCode = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _invoiceController,
            maxLength: 50, // 형식 검증은 하지 않는다(택배사마다 다르다)
            onChanged: (_) => setState(() {}), // 버튼 활성 갱신
            decoration: const InputDecoration(
              labelText: '송장번호',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: canSubmit
                ? () => Navigator.pop(
                      context,
                      _InvoiceInput(
                        deliveryCompanyCode: _carrierCode!,
                        invoiceNumber: _invoiceController.text.trim(),
                      ),
                    )
                : null,
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }
}
