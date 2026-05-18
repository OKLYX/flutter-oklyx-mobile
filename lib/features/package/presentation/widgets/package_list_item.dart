import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

class PackageListItem extends StatelessWidget {
  final Package package;
  final VoidCallback onTap;

  const PackageListItem({required this.package, required this.onTap});

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
                  Text(package.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (package.isDefault)
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
                  Text('비용: ${costFormatter.format(package.cost)}원'),
                ],
              ),
              const SizedBox(height: 4),
              Text('유효일: ${package.effectiveDate}'),
            ],
          ),
        ),
      ),
    );
  }
}
