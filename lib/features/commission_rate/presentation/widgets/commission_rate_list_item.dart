import 'package:flutter/material.dart';

import '../../domain/entities/commission_rate.dart';

/// 수수료 리스트 아이템 위젯
///
/// **용도**: Commission Rate 리스트의 각 항목을 표시
/// **필수 규칙**: CommissionRateSearchPage의 ListView에서만 사용
/// **파일 위치**: lib/features/commission_rate/presentation/widgets/commission_rate_list_item.dart
///
/// **사용 예제**:
/// ```dart
/// CommissionRateListItem(
///   commissionRate: rate,
///   onTap: () => context.goNamed(Routes.commissionRateDetail, pathParameters: {'id': rate.id.toString()}),
/// )
/// ```
///
/// **표시 정보**:
/// - Platform: 예) "COUPANG"
/// - Category: categoryId가 있으면 "카테고리 #{categoryId}", null이면 "기본값"
/// - Rate: "15.5%" 형식 (rate * 100)
/// - IsDefault: 배지 표시
///
/// ⚠️ onTap 콜백 필수 (상세 페이지 네비게이션)
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
    return Card(
      child: ListTile(
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
        onTap: onTap,
      ),
    );
  }
}
