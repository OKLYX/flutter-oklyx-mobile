import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class CarrierRateSearchPage extends StatelessWidget {
  const CarrierRateSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScaffoldWithNavBar(
      title: '택배비',
      navBarIndex: 2,
      body: Center(child: Text('Coming Soon')),
    );
  }
}
