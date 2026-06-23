import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/widgets/seller_channel_section.dart';

/// 판매자 리스트 항목.
///
/// 왼쪽 토글(▶/▼)을 누르면 판매채널 섹션이 인라인으로 펼쳐진다 (프론트엔드와 동일).
/// 카드 본문을 탭하면 판매자 상세 페이지로 이동한다.
class SellerListItem extends StatefulWidget {
  final Seller seller;
  final VoidCallback onTap;

  const SellerListItem({
    required this.seller,
    required this.onTap,
    super.key,
  });

  @override
  State<SellerListItem> createState() => _SellerListItemState();
}

class _SellerListItemState extends State<SellerListItem> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_more : Icons.chevron_right),
                    tooltip: _isExpanded ? '판매채널 접기' : '판매채널 펼치기',
                    onPressed: _toggleExpanded,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.seller.sellerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '사업자: ${widget.seller.businessRegistration}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            SellerChannelSection(
              sellerId: widget.seller.id,
              sellerName: widget.seller.sellerName,
            ),
        ],
    );
  }
}
