import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/scaffold_with_nav_bar.dart';

class CommissionRateDetailPage extends StatefulWidget {
  final int id;

  const CommissionRateDetailPage({
    super.key,
    required this.id,
  });

  @override
  State<CommissionRateDetailPage> createState() => _CommissionRateDetailPageState();
}

class _CommissionRateDetailPageState extends State<CommissionRateDetailPage> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '수수료 상세',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      onBackPressed: () => context.pop(),
      body: Center(
        child: Text('[수수료 상세 - ID: ${widget.id}, 다음 프롬프트에서 구현]'),
      ),
    );
  }
}
