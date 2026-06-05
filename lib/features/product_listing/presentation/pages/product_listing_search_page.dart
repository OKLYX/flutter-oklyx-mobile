import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class ProductListingSearchPage extends StatelessWidget {
  const ProductListingSearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매상품 조회',
      navBarIndex: 2,
      showDrawer: true,
      body: const Center(
        child: Text('판매상품 조회 - Phase 2에서 구현'),
      ),
    );
  }
}
