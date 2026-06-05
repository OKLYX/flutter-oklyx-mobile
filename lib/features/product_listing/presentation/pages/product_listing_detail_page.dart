import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class ProductListingDetailPage extends StatelessWidget {
  final int id;

  const ProductListingDetailPage({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매상품 상세',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.salesProductsPath),
      body: Center(
        child: Text('판매상품 상세 - Phase 4에서 구현 (ID: $id)'),
      ),
    );
  }
}
