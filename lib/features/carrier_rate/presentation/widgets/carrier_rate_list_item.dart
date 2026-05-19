import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';

class CarrierRateListItem extends StatelessWidget {
  final CarrierRate carrierRate;
  final VoidCallback onTap;

  const CarrierRateListItem({
    required this.carrierRate,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final costFormatter = NumberFormat('###,##0', 'ko_KR');
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(carrierRate.carrier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (carrierRate.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('기본값', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('비용: ${costFormatter.format(carrierRate.cost.toInt())}원'),
                ],
              ),
              const SizedBox(height: 4),
              Text('유형: ${carrierRate.type}'),
              const SizedBox(height: 4),
              Text('유효일: ${carrierRate.effectiveDate}'),
            ],
          ),
        ),
      ),
    );
  }
}
