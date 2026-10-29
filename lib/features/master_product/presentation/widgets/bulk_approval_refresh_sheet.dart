import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_row.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';

/// FEATURE_2610_38 / D3: the statuses whose row menu shows [승인 새로고침].
const List<String> kRefreshableStatuses = [
  ListingStatusCode.submitted,
  ListingStatusCode.selling,
  ListingStatusCode.rejected,
];

/// FEATURE_2610_38 / D6: the markets the server can refresh (Coupang · 11st ·
/// ESM).
const List<String> kRefreshablePlatforms = ['COUPANG', 'ELEVENST', 'ESM'];

/// FEATURE_2610_38 / D18: shown above the run button while a SELLING listing
/// is checked.
const String kSellingPriceNotice =
    '판매중인 판매상품은 마켓에 올라가 있는 가격을 읽어 와 시스템 판매가를 그 가격으로 바꿉니다.';

/// One listing the sheet can pick. [label] = `{seller name}/{market name} —
/// {status screen text}` (D16). Web `BulkRefreshCandidate`.
class BulkRefreshCandidate {
  final int productListingId;
  final String label;
  final String status;

  const BulkRefreshCandidate({
    required this.productListingId,
    required this.label,
    required this.status,
  });
}

/// FEATURE_2610_38 / D5: the summary line of the result box. Web
/// `bulkRefreshSummaryText`.
String bulkRefreshSummaryText(MasterApprovalRefreshResult res) =>
    '대상 ${res.requested} · 새로고침 ${res.refreshed} · '
    '건너뜀 ${res.skipped} · 실패 ${res.failed}';

/// FEATURE_2610_38 / D5: one picked listing's line of the result box. Web
/// `bulkRefreshResultLine`.
String bulkRefreshResultLine(String sellerName, MasterApprovalRefreshLine r) {
  final head = '$sellerName/${platformName(r.platform)}';
  final status = r.status;
  if (r.outcome != 'REFRESHED' || status == null) {
    return '$head — ${r.message ?? ''}';
  }
  final note = r.reviewNote;
  return '$head — ${kListingStatusLabel[status] ?? status}'
      '${note != null && note.isNotEmpty ? ' · 심사 사유: $note' : ''}';
}

/// Opens the 「전체 승인 새로고침」 picking sheet of the master detail
/// (FEATURE_2610_38 / D12 · D16 · D17 · D18).
///
/// **File**: lib/features/master_product/presentation/widgets/bulk_approval_refresh_sheet.dart
/// **Web original**: `master-products/[id]/components/BulkApprovalRefreshDialog.tsx`
///
/// - The picks start over on every open — SUBMITTED · REJECTED checked,
///   SELLING unchecked (D17). Nothing is remembered between opens.
/// - 「전체 선택」 checks or clears every line, SELLING included (D17).
/// - The price notice sits right above the run button while a SELLING line is
///   checked (D18).
///
/// Returns the picked ids in [candidates] order on [새로고침 (n)], `null` on
/// [취소] / dismiss — nothing is called then (D12).
///
/// **Usage**:
/// ```dart
/// final ids = await showBulkApprovalRefreshSheet(context,
///     candidates: _refreshCandidates);
/// if (ids != null) await _handleBulkRefresh(ids);
/// ```
///
/// ❌ No server call here — the page's head button shows 「새로고침 중...」 while
///    it runs (D12).
Future<List<int>?> showBulkApprovalRefreshSheet(
  BuildContext context, {
  required List<BulkRefreshCandidate> candidates,
}) =>
    showAppSheet<List<int>>(
      context,
      builder: (_) => _BulkApprovalRefreshSheet(candidates: candidates),
    );

class _BulkApprovalRefreshSheet extends StatefulWidget {
  final List<BulkRefreshCandidate> candidates;

  const _BulkApprovalRefreshSheet({required this.candidates});

  @override
  State<_BulkApprovalRefreshSheet> createState() =>
      _BulkApprovalRefreshSheetState();
}

class _BulkApprovalRefreshSheetState extends State<_BulkApprovalRefreshSheet> {
  late Set<int> _checked = widget.candidates
      .where((c) => c.status != ListingStatusCode.selling)
      .map((c) => c.productListingId)
      .toSet();

  List<BulkRefreshCandidate> get _picked => widget.candidates
      .where((c) => _checked.contains(c.productListingId))
      .toList();

  bool get _allChecked =>
      widget.candidates.isNotEmpty &&
      _picked.length == widget.candidates.length;

  void _toggle(int listingId) {
    setState(() {
      final next = {..._checked};
      if (!next.remove(listingId)) {
        next.add(listingId);
      }
      _checked = next;
    });
  }

  void _toggleAll() {
    setState(() {
      _checked = _allChecked
          ? {}
          : widget.candidates.map((c) => c.productListingId).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picked = _picked;
    final sellingPicked =
        picked.any((c) => c.status == ListingStatusCode.selling);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            '전체 승인 새로고침',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CheckboxListTile(
                value: _allChecked,
                onChanged: (_) => _toggleAll(),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '전체 선택',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              for (final c in widget.candidates)
                CheckboxListTile(
                  value: _checked.contains(c.productListingId),
                  onChanged: (_) => _toggle(c.productListingId),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.label, style: const TextStyle(fontSize: 14)),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (sellingPicked) ...[
                const Text(
                  kSellingPriceNotice,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warningForeground,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: picked.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(
                              picked.map((c) => c.productListingId).toList(),
                            ),
                    child: Text('새로고침 (${picked.length})'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
