import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import '../../domain/entities/purchase_share.dart';

/// Share words, the 「목표 수량 매입 완료」 tag, the share buttons and the two
/// pickers they open (FEATURE_2610_09 D24 · D57 · D61 · D67 · D79 · D80 · D83).
///
/// **Purpose**: one place for what a (product × seller) share shows — the
/// seller view draws it under the list card, 「전체」 draws it on each share row
/// of the product detail (D83).
/// **File**: lib/features/purchase_list/presentation/widgets/purchase_share_actions.dart
///
/// **Usage**:
/// ```dart
/// PurchaseShareActions(
///   share: share,
///   busy: busy,
///   onCheck: (status) => bloc.add(CheckShare(
///       productId: item.productId, sellerId: share.sellerId, status: status)),
///   onCancel: (checkId) => bloc.add(CancelShareCheck(checkId: checkId)),
/// )
/// final sellerId = await pickSellerSheet(context, sellers, exceptId: 3);
/// ```
///
/// ❌ Do not write the state words (「매입 완료」 · 「필요 없음」 · 「필요 0」 ·
/// 「내일 매입」) anywhere else.
const Map<String, String> shareStateLabel = {
  'SKIPPED_TODAY': '내일 매입',
  'PURCHASED': '매입 완료',
  'NOT_NEEDED': '필요 없음',
  'NEED_ZERO': '필요 0',
};

/// 「목표 수량 매입 완료」 — OPEN and SKIPPED_TODAY shares only (D57 ①).
class TargetMetTag extends StatelessWidget {
  final PurchaseShare share;

  const TargetMetTag({required this.share, super.key});

  @override
  Widget build(BuildContext context) {
    if (!share.targetMet ||
        (share.state != 'OPEN' && share.state != 'SKIPPED_TODAY')) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '목표 수량 매입 완료',
        style: TextStyle(fontSize: 11, color: AppColors.successForeground),
      ),
    );
  }
}

/// The words and buttons of one share, by state:
/// OPEN → [매입 완료] [오늘 매입 안 함] · SKIPPED_TODAY → 「내일 매입」 [되돌리기] ·
/// PURCHASED → 「매입 완료」 [완료 취소] · NOT_NEEDED → 「필요 없음」 [되돌리기] ·
/// NEED_ZERO → 「필요 0」.
class PurchaseShareActions extends StatelessWidget {
  final PurchaseShare share;
  final bool busy;

  /// `PURCHASED` · `NOT_NEEDED` · `TOMORROW`.
  final ValueChanged<String> onCheck;
  final ValueChanged<int> onCancel;

  const PurchaseShareActions({
    required this.share,
    required this.busy,
    required this.onCheck,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final checkId = share.checkId;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (share.state == 'OPEN') ...[
          FilledButton(
            onPressed: busy ? null : () => onCheck('PURCHASED'),
            style: _compact,
            child: const Text('매입 완료'),
          ),
          OutlinedButton(
            onPressed: busy ? null : () => _askSkip(context),
            style: _compact,
            child: const Text('오늘 매입 안 함'),
          ),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              shareStateLabel[share.state] ?? share.state,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        if (checkId != null && share.state != 'NEED_ZERO')
          TextButton(
            onPressed: busy ? null : () => onCancel(checkId),
            style: _compact,
            child: Text(share.state == 'PURCHASED' ? '완료 취소' : '되돌리기'),
          ),
      ],
    );
  }

  static final ButtonStyle _compact = ButtonStyle(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 10),
    ),
  );

  /// D61: 「내일 매입」 (off the list today only) or 「매입할 필요 없음」.
  Future<void> _askSkip(BuildContext context) async {
    final status = await showAppSheet<String>(
      context,
      builder: (sheetContext) => _ChoiceSheet(
        title: '오늘 매입 안 함',
        hint: '오늘 사지 않는 이유를 고르세요.',
        choices: const [
          MapEntry('TOMORROW', '내일 매입'),
          MapEntry('NOT_NEEDED', '매입할 필요 없음'),
        ],
      ),
    );
    if (status != null) onCheck(status);
  }
}

/// [판매자 바꾸기] picker — every seller except [exceptId], no 「전체」
/// (FEATURE_2610_09 D13 · D24). Returns the picked seller id or null.
Future<int?> pickSellerSheet(
  BuildContext context,
  List<Seller> sellers, {
  required int exceptId,
}) async {
  final picked = await showAppSheet<String>(
    context,
    builder: (sheetContext) => _ChoiceSheet(
      title: '판매자 바꾸기',
      hint: '이 수동 줄을 넘길 판매자를 고르세요.',
      choices: sellers
          .where((seller) => seller.id != exceptId)
          .map((seller) => MapEntry('${seller.id}', seller.sellerName))
          .toList(),
    ),
  );
  return picked == null ? null : int.parse(picked);
}

class _ChoiceSheet extends StatelessWidget {
  final String title;
  final String hint;

  /// value → label.
  final List<MapEntry<String, String>> choices;

  const _ChoiceSheet({
    required this.title,
    required this.hint,
    required this.choices,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ...choices.map(
            (choice) => ListTile(
              title: Text(choice.value),
              onTap: () => Navigator.of(context).pop(choice.key),
            ),
          ),
        ],
      ),
    );
  }
}
