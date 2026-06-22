import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

/// 판매자 필터 드롭다운 ('전체' + 각 판매자).
///
/// 선택 시 [onChanged]에 sellerId(null = 전체)를 전달한다. [enabled]가 false면
/// 비활성화(조회/재적재 중).
class SellerFilterDropdown extends StatelessWidget {
  final List<Seller> sellers;
  final int? selectedSellerId;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  const SellerFilterDropdown({
    required this.sellers,
    required this.selectedSellerId,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: selectedSellerId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '판매자',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
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
