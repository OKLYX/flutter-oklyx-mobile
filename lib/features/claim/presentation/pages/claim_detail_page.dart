import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import '../../domain/entities/claim.dart';
import '../widgets/claim_action_sheet.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';

/// Claim detail page (FEATURE_2609_18).
///
/// **Data**: shows the [Claim] received from the list as go_router `extra` as
/// it is (no detail API re-read).
/// → When [claim] is null (deep link · hot reload) a panel offers the way back
/// to the list.
///
/// ⚠️ Never **navigate automatically** with `context.go` / `pop` during
/// `build` — navigating while building throws. The user taps a button to go
/// back.
/// ⚠️ Returns and exchanges are 80% the same, so the page is **not split** —
/// it branches only on [Claim.claimType].
///
/// **Actions** (FEATURE_2609_21): the [ClaimActionSheet] at the bottom draws
/// the server's [Claim.availableActions] as buttons — **the server decides**
/// what shows (D1). An owner is needed for the single re-read after an
/// action, so this page is a [StatefulWidget] and every card and the action
/// area read the local [_claim].
/// **Return invoice** (FEATURE_2609_70): a value only in our own ledger gets
/// the 「우리 기록」 badge, and a return the customer sends themselves (**no
/// invoice to enter at all**) gets a gray notice instead of a value (D3).
/// 🔴 No decision here — it only reads the server's `collectInvoiceSource` ·
/// `returnDeliveryType`; what can be tapped is still `availableActions` (D1).
///
/// ⚠️ The list (`ClaimListBloc`) is not touched — the detail cannot reach that
/// instance, and the list card does not draw the value an action changes
/// (`availableActions`) (04 Step 5).
class ClaimDetailPage extends StatefulWidget {
  final Claim? claim;

  const ClaimDetailPage({super.key, this.claim});

  @override
  State<ClaimDetailPage> createState() => _ClaimDetailPageState();
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  /// 화면이 그리는 클레임. 시작값은 목록이 `extra` 로 넘긴 객체이고,
  /// 액션 성공(또는 409) 뒤 단건 재조회 결과로 교체된다(D8).
  Claim? _claim;

  @override
  void initState() {
    super.initState();
    _claim = widget.claim;
  }

  @override
  Widget build(BuildContext context) {
    final claim = _claim;
    return ScaffoldWithNavBar(
      // ⚠️ claim 은 여기서 nullable 이다(_buildContent 안이 아니다) — null 분기가 필요하다.
      title: claim == null
          ? '반품/교환 상세'
          : '${getClaimTypeLabel(claim.claimType)} 상세',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.claimListPath),
      body: claim == null
          ? _buildMissing(context)
          : _buildContent(context, claim),
    );
  }

  // extra 로 전달된 클레임 정보가 없는 경우(딥링크/새로고침) 목록 복귀를 유도한다.
  Widget _buildMissing(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('반품 정보를 찾을 수 없습니다.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go(Routes.claimListPath),
            child: const Text('반품/교환으로'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Claim c) {
    // 교환은 반품비가 항상 null 이라 그 행을 아예 그리지 않는다(06).
    final isExchange = c.claimType == ClaimType.exchange;

    // 회수·재발송 송장이 같은 조립을 쓰게 하는 지역 함수. 둘 다 없으면 '-'.
    String invoiceText(String? carrier, String? invoice) {
      final text = '${carrier ?? ''} ${invoice ?? ''}'.trim();
      return text.isEmpty ? '-' : text;
    }

    // 회수송장 한 줄 — 2609_70 에서 세 갈래가 됐다(반품·교환이 같은 줄을 쓴다):
    // ① 우리 장부에만 있는 값(D6) → 「우리 기록」 뱃지. null·PLATFORM 은 아무 표시도 없다
    // ② 반품인데 고객이 직접 보내 **넣을 송장이 아예 없는** 건(D3) → 회색 안내로 바꾼다.
    //    🔴 회수종류가 null(아직 안 읽은 옛 행)일 때는 그리지 않는다 — 판단할 근거가 없다
    // ③ 그 밖 → 기존 그대로
    _InfoRow collectInvoiceRow() {
      if (c.collectInvoiceNotApplicable) {
        return const _InfoRow(
          '회수송장',
          '고객이 직접 보낸 건이라 넣을 송장이 없습니다',
          muted: true,
        );
      }
      return _InfoRow(
        '회수송장',
        invoiceText(c.collectCarrierCode, c.collectInvoiceNo),
        badge: c.collectInvoiceLocalOnly ? '우리 기록' : null,
      );
    }

    return AppPageBody.scroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(
            title: '접수',
            rows: [
              _InfoRow('접수번호', c.externalClaimId),
              _InfoRow('접수일',
                  formatOrderDateTime(c.receivedAt.toIso8601String())),
              _InfoRow(
                '상태',
                c.statusNote == null
                    ? getClaimStatusLabel(c.status)
                    : '${getClaimStatusLabel(c.status)} · ${c.statusNote}',
              ),
              _InfoRow('플랫폼', platformName(c.platform)),
            ],
            // 원문 상태 코드는 정보 손실 방지용 — 목록 카드에는 내지 않는다.
            footnote: c.platformStatus.isEmpty
                ? null
                : '플랫폼 원문 상태: ${c.platformStatus}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: '주문/상품',
            rows: [
              _InfoRow('주문번호', c.externalOrderId),
              _InfoRow('상품명', c.itemName ?? '-'),
              _InfoRow('수량', '${c.quantity}'),
              _InfoRow('판매자', c.sellerName ?? '-'),
              _InfoRow('고객명', c.requesterName ?? '-'),
            ],
            // 매칭에 실패해도 클레임 자체는 저장된다(D12) — 왜 비어 있는지 알려준다.
            footnote: c.linked
                ? null
                : '주문 라인에 연결되지 않은 접수입니다 — 상품·판매자 정보가 비어 있을 수 있습니다.',
          ),
          const SizedBox(height: 12),
          if (isExchange) ...[
            // 교환은 회수(고객→판매자)와 재발송(판매자→고객)이 별개 흐름이라 카드를 나눈다.
            _InfoCard(
              title: '회수',
              rows: [
                _InfoRow('사유', c.reasonText ?? c.reasonCode ?? '-'),
                // ⚠️ 맵을 직접 읽지 않는다 — 미지정 값이 빈칸이 된다.
                _InfoRow('귀책', faultTypeText(c.faultType)),
                // 회수상태(05) — 이 한 줄이 "왜 재발송 버튼이 없나"를 화면에서 설명한다.
                // ⚠️ 반품 카드에는 넣지 않는다(반품은 항상 null 이라 '-' 만 늘어난다).
                _InfoRow('회수상태', collectStatusText(c.collectStatus)),
                collectInvoiceRow(),
              ],
            ),
            const SizedBox(height: 12),
            // ⚠️ 값이 비어도 숨기지 않는다 — '아직 재발송 안 됨'과 '재발송 개념이 없음'은 다르다.
            _InfoCard(
              title: '재발송',
              rows: [
                _InfoRow('재발송송장',
                    invoiceText(c.reshipCarrierCode, c.reshipInvoiceNo)),
              ],
            ),
          ] else
            _InfoCard(
              title: '처리',
              rows: [
                _InfoRow('사유', c.reasonText ?? c.reasonCode ?? '-'),
                // ⚠️ 맵을 직접 읽지 않는다 — 미지정 값이 빈칸이 된다.
                _InfoRow('귀책', faultTypeText(c.faultType)),
                _InfoRow(
                  '반품비',
                  c.returnShippingCharge == null
                      ? '-'
                      : '${c.returnShippingCharge}원',
                ),
                collectInvoiceRow(),
              ],
            ),
          // 액션 영역 — 서버가 준 목록이 비면 영역 자체를 만들지 않는다(위 여백도 함께 빠진다).
          if (c.availableActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClaimActionSheet(
              claim: c,
              // 재조회 결과를 로컬 상태로 받는다. 낙관적 갱신은 하지 않는다(D7).
              onActionDone: (updated) => setState(() => _claim = updated),
            ),
          ],
        ],
      ),
    );
  }
}

/// 정보 카드 (제목 + 라벨/값 행 목록 + 선택적 각주). 주문 상세와 동일한 스타일.
class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  /// 카드 하단 회색 안내문(원문 상태·미연결 안내). null 이면 그리지 않는다.
  final String? footnote;

  const _InfoCard({required this.title, required this.rows, this.footnote});

  @override
  Widget build(BuildContext context) {
    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows,
            if (footnote != null)
              Text(
                footnote!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  /// 값 옆의 작은 뱃지(「우리 기록」 등). null 이면 그리지 않는다.
  final String? badge;

  /// 값이 아니라 **안내 문구**일 때 켠다 — 회색 보조문으로 그린다(값처럼 굵게 쓰면
  /// 사용자가 그 문장을 송장번호로 읽는다).
  final bool muted;

  const _InfoRow(this.label, this.value, {this.badge, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final badgeText = badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: muted
                      ? TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warningForeground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
