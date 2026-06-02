import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

class SellerListItem extends StatelessWidget {
  final Seller seller;
  final VoidCallback onTap;

  const SellerListItem({
    required this.seller,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seller.sellerName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '사업자: ${seller.businessRegistration}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
