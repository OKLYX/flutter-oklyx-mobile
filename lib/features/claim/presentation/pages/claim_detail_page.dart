import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/claim.dart';

// Platform display labels — same shape as order_detail_page;
// unknown codes fall back to the raw value.
const Map<String, String> _platformLabels = {'COUPANG': '쿠팡'};

/// 클레임 상세 페이지 (FEATURE_2609_18).
///
/// **데이터 출처**: 주문 상세와 동일하게 목록에서 받은 [Claim] 을 go_router `extra` 로
/// 전달받아 그대로 표시한다(상세 API 재조회 없음).
/// → 딥링크·핫리로드로 [claim] 이 null 이면 목록 복귀 안내 패널을 띄운다.
///
/// ⚠️ `build` 중에 `context.go`/`pop` 으로 **자동 이동하지 않는다** — 빌드 중 네비게이션은
/// 예외를 던진다. 사용자가 버튼을 눌러 돌아간다.
/// ⚠️ **처리 버튼(승인·입고확인·재발송 송장)을 만들지 말 것** — 조회 전용이다(PLAN D4).
/// ⚠️ 반품/교환은 8할이 같아 **페이지를 나누지 않는다** — [Claim.claimType] 한 축으로만 분기한다.
class ClaimDetailPage extends StatelessWidget {
  final Claim? claim;

  const ClaimDetailPage({super.key, this.claim});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      // ⚠️ claim 은 여기서 nullable 이다(_buildContent 안이 아니다) — null 분기가 필요하다.
      title: claim == null
          ? '반품/교환 상세'
          : '${getClaimTypeLabel(claim!.claimType)} 상세',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.claimListPath),
      body: claim == null
          ? _buildMissing(context)
          : _buildContent(context, claim!),
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
          ElevatedButton(
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(
            title: '접수',
            rows: [
              _InfoRow('접수번호', c.externalClaimId),
              _InfoRow('접수일',
                  formatOrderDateTime(c.receivedAt.toIso8601String())),
              _InfoRow('상태', getClaimStatusLabel(c.status)),
              _InfoRow('플랫폼', _platformLabels[c.platform] ?? c.platform),
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
                _InfoRow('회수송장',
                    invoiceText(c.collectCarrierCode, c.collectInvoiceNo)),
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
                _InfoRow('회수송장',
                    invoiceText(c.collectCarrierCode, c.collectInvoiceNo)),
              ],
            ),
          // ScaffoldWithNavBar 는 내비바를 오버레이하므로 하단 여백을 확보한다.
          SizedBox(
            height: kBottomNavigationBarHeight +
                MediaQuery.paddingOf(context).bottom +
                16,
          ),
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
