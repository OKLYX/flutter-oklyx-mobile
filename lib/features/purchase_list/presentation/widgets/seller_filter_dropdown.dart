import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

/// 판매자 드롭다운.
///
/// [includeAll] 이 true 면 '전체'(null) 옵션을 맨 위에 둔다(표시 필터용).
/// 🔴 입고 카드는 **반드시 한 명을 골라야** 하므로 `includeAll: false` 로 쓴다
/// (PLAN 2609_29 D0 — 매입 귀속 판매자). 그때 값이 null 이면 '선택' 힌트를 보여준다.
///
/// 선택 시 [onChanged]에 sellerId 를 전달한다. [enabled]가 false면 비활성화.
class SellerFilterDropdown extends StatelessWidget {
  final List<Seller> sellers;
  final int? selectedSellerId;
  final ValueChanged<int?> onChanged;
  final bool enabled;
  final bool includeAll;
  final String labelText;

  const SellerFilterDropdown({
    required this.sellers,
    required this.selectedSellerId,
    required this.onChanged,
    this.enabled = true,
    this.includeAll = true,
    this.labelText = '판매자',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: selectedSellerId,
      isExpanded: true,
      hint: includeAll ? null : const Text('선택'),
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        if (includeAll)
          const DropdownMenuItem<int?>(value: null, child: Text('전체')),
        ...sellers.map(
          (Seller seller) => DropdownMenuItem<int?>(
            value: seller.id,
            child: Text(seller.sellerName, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
