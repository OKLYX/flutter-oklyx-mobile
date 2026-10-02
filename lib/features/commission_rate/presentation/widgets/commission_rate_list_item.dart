import 'package:flutter/material.dart';

import '../../domain/entities/commission_rate.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Commission rate list item widget
///
/// **Purpose**: shows one entry of the commission rate list
/// **Required rule**: use only in the SliverList of CommissionRateSearchPage
/// **File location**: lib/features/commission_rate/presentation/widgets/commission_rate_list_item.dart
///
/// **Usage**:
/// ```dart
/// CommissionRateListItem(
///   commissionRate: rate,
///   onTap: () => context.goNamed(Routes.commissionRateDetail, pathParameters: {'id': rate.id.toString()}),
/// )
/// ```
///
/// **Shown fields**:
/// - Platform: e.g. "COUPANG"
/// - Category: "카테고리 #{categoryId}" when categoryId is set, "기본값" when null
/// - Rate: "15.5%" format (rate * 100)
/// - IsDefault: shown as a badge
///
/// ⚠️ The onTap callback is required (navigation to the detail page)
class CommissionRateListItem extends StatelessWidget {
  final CommissionRate commissionRate;
  final VoidCallback onTap;

  const CommissionRateListItem({
    required this.commissionRate,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.row(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(commissionRate.platform),
        subtitle: Text(
          commissionRate.categoryId == null
              ? '기본값'
              : commissionRate.categoryName ?? '카테고리',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(commissionRate.rate * 100).toStringAsFixed(2)}%'),
            if (commissionRate.isDefault)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text('기본값'),
                  labelStyle: TextStyle(fontSize: 10),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
