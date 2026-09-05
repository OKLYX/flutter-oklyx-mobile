import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/carrier_option.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/domain/usecases/shipping_label_usecase.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/claim_usecase.dart';
import 'claim_reject_sheet.dart';

/// 클레임 상세의 처리 액션 영역 (FEATURE_2609_21 / 04).
///
/// **용도**: 서버가 내려준 [Claim.availableActions] 를 버튼으로 그리고, 실행 후 단건 재조회
/// 결과를 [onActionDone] 으로 올린다.
/// **파일**: lib/features/claim/presentation/widgets/claim_action_sheet.dart
///
/// **사용 예제**:
/// ```dart
/// ClaimActionSheet(
///   claim: _claim,
///   onActionDone: (updated) => setState(() => _claim = updated),
/// )
/// ```
///
/// 🔴 **상태 코드로 분기하지 않는다.** 무엇을 보여줄지는 서버의 `availableActions` 가 정하고
/// (D1), 분기는 `requires` 로만 한다 — `action` 코드로 `switch` 하면 교환 4종이 붙는 날 화면을
/// 다시 짜야 하고, 웹(03)과 같은 클레임에 다른 버튼이 보인다.
///
/// ⚠️ **BLoC 을 쓰지 않는다**(D9 / 04 Step 5). 목록 `ClaimListBloc` 은 목록 화면의
/// `BlocProvider(create:)` 가 만들어 상세에서 닿을 수 없고(`registerFactory` 라 `getIt` 은 다른
/// 인스턴스다), 액션이 바꾸는 값은 상세에서만 쓰는 `availableActions` 하나다.
/// ⚠️ **낙관적 갱신 금지**(D7) — 상태 라벨을 미리 바꾸지 않는다. 쿠팡 상태는 다음 동기화가 가져온다.
/// ⚠️ 모바일엔 ADMIN 게이트가 없다 — 서버가 비-ADMIN 에게 빈 목록을 주고, 그래도 눌리면 403 이
/// 유일한 방어선이다(D13). role 조회를 새로 만들지 말 것.
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
  static const _rawResponseTitle = '쿠팡 응답 보기';

  /// X3(재발송 송장)의 400 안내 꼬리말. **클라이언트가 붙이는 유일한 문구**다 —
  /// 05 Step 5 의 박스 alias 가 실제 스키마와 다르면 10분이 지나도 같은 400 이 오는데,
  /// 이 줄이 없으면 사용자는 "아직 이른가 보다" 하며 무한히 재시도한다.
  static const _reshipRetryHint = '여러 번 반복되면 관리자에게 알려주세요.';

  /// 🔴 **`action` 코드로 분기하는 곳은 이 위젯에서 딱 두 곳**이다 —
  /// ① 송장 시트의 보조 문구([_invoiceSubtitles]) ② X3 의 400 톤([_execute]).
  /// "분기는 `requires` 로만" 규칙의 **의도적 예외**이고, 늘리지 말 것 — 세 번째가 생기려 하면
  /// 그건 서버가 내려줄 것이 하나 빠진 것이다.
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
        // 선택지가 비면 고를 것이 없다 → 시트가 아니라 **버튼 자체**를 그리지 않는다.
        // 시트 안에서 막으면 눌러도 아무것도 안 열리는 죽은 버튼이 남는다(07 Step 1).
        .where((a) =>
            a.requires != ClaimActionRequires.rejectCode || a.choices.isNotEmpty)
        .toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
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
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
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
    if (action.irreversible && !await _confirm(action)) return;
    await _execute(ClaimActionRequest(action: action.action));
  }

  /// 거부 사유 시트(07). **자기 확인 다이얼로그를 띄우지 않는다** — 확인은 시트가 소유한다.
  /// 둘 다 띄우면 확인이 2단이 아니라 3단이 되고, 사유가 안 보이는 확인이 하나 낀다.
  Future<void> _openRejectSheet(ClaimAction action) async {
    String? rejectCode;
    await showModalBottomSheet<void>(
      context: context,
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
        // 03 문구 표. 교환 거부(07)의 문구는 `ClaimRejectSheet` 가 같은 함수에 넘긴다.
        '이 반품을 승인하면 환불이 확정되며 되돌릴 수 없습니다.',
      ],
      confirmLabel: action.label.isEmpty ? action.action : action.label,
    );
  }

  /// 송장 입력 바텀시트. `isScrollControlled` + `viewInsets` 로 키보드에 가리지 않게 한다.
  ///
  /// X3(재발송 송장)의 400 은 **이른 요청**이라 재시도가 정상 경로다 — 그래서 그 400 에서만
  /// 입력값을 그대로 담아 시트를 다시 연다(사용자가 택배사·송장번호를 다시 치지 않게).
  /// 전송 중에 시트를 열어 두지는 않는다 — 시트 안은 부모의 `setState` 로 다시 그려지지 않아
  /// `isSending` 이 갱신되지 않는다.
  Future<void> _openInvoiceSheet(ClaimAction action) async {
    _InvoiceInput? prefill;
    while (true) {
      final input = await showModalBottomSheet<_InvoiceInput>(
        context: context,
        isScrollControlled: true,
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
      (_) async {
        _snack(_successMessage);
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
      _snack(_conflictMessage);
      await _reload();
      return false;
    }
    if (status == 502) {
      // 쿠팡 원문 그대로(D15). 번역·요약 금지.
      _showRawResponse(f);
      return false;
    }
    if (status == 401 || status == 403) {
      _snack(_forbiddenMessage, isError: true);
      return false;
    }
    // 400(입력값·미등록 택배사·현재 상태에서 불가) 은 서버 메시지가 사유를 담고 있다.
    final message = f?.message ?? failure.message;
    if (status == 400 && request.action == _actionExchangeReshipInvoice) {
      // 재발송 송장은 입고확인 후 **약 10분** 뒤에 받아진다 — 그 전의 400 은 잘못이 아니라
      // 이른 것이다. 에러색으로 띄우지 않고, 꼬리말을 붙여 무한 재시도를 막는다.
      //
      // ⚠️ 톤 판정이 **액션 단위**라 재발송송장의 다른 400(미매핑 택배사 등)도 안내색으로 나온다.
      // 문구는 서버 메시지 그대로라 내용은 맞고 색만 순해진다 — 감수한다.
      // 🔴 색으로 원인을 구분하려고 서버 문구를 파싱하지 말 것(문구가 바뀌면 조용히 깨진다).
      _snack('$message\n$_reshipRetryHint');
      return true;
    }
    _snack(message, isError: true);
    return false;
  }

  /// 502 는 원문이 길 수 있어 다이얼로그로 편다(짧으면 SnackBar 로 충분하다).
  void _showRawResponse(ClaimActionFailure? f) {
    final raw = [
      if (f?.resultCode != null) f!.resultCode!,
      if (f?.resultMessage != null) f!.resultMessage!,
    ].join('\n');
    final body = raw.isEmpty ? (f?.message ?? '쿠팡 처리에 실패했습니다.') : raw;
    if (body.length <= 60) {
      _snack(body);
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

  /// [isError] = 사용자가 **잘못한** 결과(일반 400·권한). 안내(성공·409·X3 이른 요청)는 보통 톤이다 —
  /// 잘못이 아닌 것을 붉게 띄우면 사용자가 재시도를 멈춘다.
  void _snack(String message, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError ? TextStyle(color: scheme.onError) : null,
        ),
        backgroundColor: isError ? scheme.error : null,
        // ScaffoldWithNavBar 가 내비바를 오버레이한다 — 기본값이면 SnackBar 가 가린다.
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
      ),
    );
  }
}

/// 되돌릴 수 없는 액션의 2단 확인 다이얼로그 (D10).
///
/// **용도**: [ClaimActionSheet](반품 승인 등)와 [ClaimRejectSheet](교환 거부)가 **같은** 확인을
/// 쓰게 한다 — 복사해 두 벌을 만들면 기본 강조·바깥 탭 규칙이 조용히 갈린다.
/// **파일**: lib/features/claim/presentation/widgets/claim_action_sheet.dart
///
/// **사용 예제**:
/// ```dart
/// final ok = await showClaimConfirmDialog(
///   context,
///   title: claim.itemName ?? '-',
///   lines: ['수량 3개', '사유: 고객이 교환요청을 철회함', '거부하면 되돌릴 수 없습니다.'],
///   confirmLabel: action.label,
/// );
/// ```
///
/// [lines] 는 **마지막 줄이 경고 문구**다 — 앞줄들(수량·반품비·사유)은 회색 상세로, 마지막 줄만
/// 본문 색으로 그린다. 반품에는 반품비가 있고 교환 거부에는 사유가 있어 **줄 목록을 인자로 받는다**
/// (확정되는 금액이 없는 교환에서는 그 자리를 사유가 대신한다).
///
/// ⚠️ 기본 강조는 **취소**다 — 확정 버튼을 강조하면 오탭 한 번이 환불 확정이 된다.
/// ⚠️ [confirmLabel] 은 **서버 라벨**을 넘긴다(D18) — 앱이 '승인' 같은 말을 지어내지 않는다.
Future<bool> showClaimConfirmDialog(
  BuildContext context, {
  required String title,
  required List<String> lines,
  required String confirmLabel,
}) async {
  final details = lines.length > 1 ? lines.sublist(0, lines.length - 1) : const <String>[];
  final warning = lines.isEmpty ? '' : lines.last;

  final confirmed = await showDialog<bool>(
    context: context,
    // 바깥 탭이 곧 취소가 되게 둔다.
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...details.map(
            (line) => Text(line, style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(height: 12),
          Text(warning),
        ],
      ),
      actions: [
        // 기본 강조는 취소다.
        FilledButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: Theme.of(ctx).colorScheme.error),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
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
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
              border: OutlineInputBorder(),
              isDense: true,
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
              border: OutlineInputBorder(),
              isDense: true,
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
