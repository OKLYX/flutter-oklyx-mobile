import 'package:flutter/material.dart';

import '../../../../shared/widgets/scaffold_with_nav_bar.dart';

class CommissionRateSearchPage extends StatefulWidget {
  const CommissionRateSearchPage({super.key});

  @override
  State<CommissionRateSearchPage> createState() => _CommissionRateSearchPageState();
}

class _CommissionRateSearchPageState extends State<CommissionRateSearchPage> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '수수료',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: const Center(
        child: Text('[수수료 관리 - 다음 프롬프트에서 구현]'),
      ),
    );
  }
}
