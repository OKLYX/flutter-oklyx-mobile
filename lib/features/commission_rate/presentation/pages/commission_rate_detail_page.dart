import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router/routes.dart';
import '../../../../shared/widgets/scaffold_with_nav_bar.dart';

class CommissionRateDetailPage extends StatelessWidget {
  final int id;

  const CommissionRateDetailPage({required this.id});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '수수료 상세',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      onBackPressed: () => context.go(Routes.commissionRatePath),
      body: Center(
        child: Text('[수수료 상세 - ID: $id, 다음 프롬프트에서 구현]'),
      ),
    );
  }
}
