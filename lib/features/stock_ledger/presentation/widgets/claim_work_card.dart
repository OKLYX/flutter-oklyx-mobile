import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import '../../../claim/domain/entities/claim.dart';
import '../../../purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/name_text.dart';
import '../../domain/entities/stock_work.dart';
import '../bloc/claim_work_cubit.dart';

/// One opened claim of a claim work tab (FEATURE_2611_34 D19 · D20 · R15).
///
/// **Purpose**: the claim head (type · order · channel · seller · requester
/// · status · collect) and one quantity field per product.
/// **File**: stock_ledger/presentation/widgets/claim_work_card.dart
/// **Used by**: `ClaimWorkSection` — 「입고 작업」 「반품 재입고」 and
/// 「출고 작업」 「교환 발송」.
///
/// ```dart
/// ClaimWorkCard(
///   claim: claim,
///   text: cubit.text,
///   entered: state.entered,
///   onChanged: cubit.changeEntered,
/// )
/// ```
///
/// ⚠️ A claim with a `failure` shows only the head and [ClaimWorkText]
/// `unknownItems` — nothing can be collected on it (D31 · R27).
/// ❌ Do not write the tab texts here — they come in [text].
class ClaimWorkCard extends StatelessWidget {
  final ClaimWork claim;
  final ClaimWorkText text;
  final Map<String, String> entered;
  final void Function(String key, String text) onChanged;

  const ClaimWorkCard({
    required this.claim,
    required this.text,
    required this.entered,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final head = [
      getClaimTypeLabel(parseClaimType(claim.claimType)),
      claim.externalOrderId,
      salesChannelLabel(claim.platform, claim.accountAlias),
      '판매자 ${claim.sellerName ?? '-'}',
      '요청자 ${claim.requesterName ?? '-'}',
      '상태 ${getClaimStatusLabel(parseClaimStatus(claim.claimStatus))}',
      '회수 ${collectStatusText(claim.collectStatus)}',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              for (var i = 0; i < head.length; i++)
                Text(
                  i == 0 ? head[i] : ' · ${head[i]}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 4),
          NameText(
            name: claim.itemName,
            kind: NameKind.product,
            expandable: true,
          ),
          const SizedBox(height: 8),
          if (claim.failure != null)
            Text(
              text.unknownItems,
              style: const TextStyle(color: AppColors.warningForeground),
            )
          else
            for (final item in claim.items)
              _row(claimItemKey(claim.orderClaimId, item.productId), item),
        ],
      ),
    );
  }

  Widget _row(String key, ClaimWorkItem item) => _ItemRow(
        key: ValueKey(key),
        item: item,
        itemKey: key,
        value: entered[key] ?? '0',
        onChanged: onChanged,
        text: text,
      );
}

/// One product of a claim and its 「이번 수량」 field (D20).
class _ItemRow extends StatefulWidget {
  final ClaimWorkItem item;
  final String itemKey;
  final String value;
  final void Function(String key, String text) onChanged;
  final ClaimWorkText text;

  const _ItemRow({
    required this.item,
    required this.itemKey,
    required this.value,
    required this.onChanged,
    required this.text,
    super.key,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  final TextEditingController _qty = TextEditingController();

  @override
  void initState() {
    super.initState();
    _qty.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant _ItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A scan adds 1 to this field — show the new count (R16).
    if (widget.value != _qty.text) {
      _qty.text = widget.value;
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final text = widget.text;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductThumbnail(productId: widget.item.productId, size: 40),
              const SizedBox(width: 8),
              Expanded(
                child: NameText(
                  name: item.productName,
                  kind: NameKind.product,
                  expandable: true,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '바코드 ${item.barcode ?? '-'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${text.requiredLabel} ${item.requiredQty} · '
            '${text.doneLabel} ${item.doneQty} · 남은 ${item.remainingQty}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: text.enteredLabel),
              onChanged: (v) => widget.onChanged(widget.itemKey, v),
            ),
          ),
        ],
      ),
    );
  }
}
