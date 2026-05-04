import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_state.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailBloc _productDetailBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _productDetailBloc = getIt<ProductDetailBloc>()..add(LoadProductDetail(widget.productId));
  }

  @override
  void dispose() {
    _productDetailBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _productDetailBloc,
    child: Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawerScrimColor: Colors.black.withOpacity(0.3),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('상품상세'),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: Colors.grey[100],
          body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (context, state) {
              if (state is ProductDetailLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is ProductDetailError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _productDetailBloc.add(RetryLoadProductDetail(widget.productId)),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }

              if (state is ProductDetailLoaded) {
                final product = state.product;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _ImageSection(),
                      const SizedBox(height: 12),
                      _BasicInfoCard(product: product),
                      const SizedBox(height: 12),
                      _PricingCard(product: product),
                      if (product.volumeHeight != null ||
                          product.volumeLong != null ||
                          product.volumeShort != null ||
                          product.weight != null) ...[
                        const SizedBox(height: 12),
                        _DimensionsCard(product: product),
                      ],
                      const SizedBox(height: 12),
                      _DetailsCard(product: product),
                      const SizedBox(height: 12),
                      _TimestampsCard(product: product),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          bottomNavigationBar: SizedBox.shrink(),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ExpansionTile(
                  shape: const Border(),
                  title: const Text('상품관리'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ListTile(
                        title: const Text('상품등록'),
                        onTap: () {
                          Navigator.pop(context);
                          context.go(Routes.productRegisterPath);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ListTile(
                        title: const Text('상품조회'),
                        onTap: () {
                          Navigator.pop(context);
                          context.go(Routes.productSearchPath);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 2,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.menu), label: ''),
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: ''),
              BottomNavigationBarItem(icon: const Icon(Icons.checklist), label: ''),
              BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: ''),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  } else {
                    _scaffoldKey.currentState?.openDrawer();
                  }
                  break;
                case 1:
                  context.go(Routes.dashboardPath);
                  break;
                case 2:
                  context.go(Routes.productSearchPath);
                  break;
                case 3:
                  context.go(Routes.notificationPath);
                  break;
              }
            },
          ),
        ),
      ],
    ),
  );
}

class _ImageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: Colors.grey[500], size: 60),
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  final product;

  const _BasicInfoCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Barcode: ${product.barcodeId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final product;

  const _PricingCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.price != null) ...[
              Row(
                children: [
                  const Text('가격: '),
                  Text(
                    '${product.price} 원',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (product.store != null) ...[
              Row(
                children: [
                  const Text('상점: '),
                  Text(product.store),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (product.unit != null)
              Row(
                children: [
                  const Text('단위: '),
                  Text(product.unit),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DimensionsCard extends StatelessWidget {
  final product;

  const _DimensionsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '치수',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (product.volumeHeight != null) ...[
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('높이:')),
                  Text(product.volumeHeight),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (product.volumeLong != null) ...[
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('길이:')),
                  Text(product.volumeLong),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (product.volumeShort != null) ...[
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('너비:')),
                  Text(product.volumeShort),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (product.weight != null)
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('무게:')),
                  Text(product.weight),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final product;

  const _DetailsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand != null) ...[
              Row(
                children: [
                  const Text('브랜드: '),
                  Text(product.brand),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (product.description != null) ...[
              Row(
                children: [
                  const Text('설명: '),
                  Expanded(
                    child: Text(product.description),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Text('상태: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.active ? Colors.green[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.active ? '활성' : '비활성',
                    style: TextStyle(
                      color: product.active ? Colors.green : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimestampsCard extends StatelessWidget {
  final product;

  const _TimestampsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('생성: '),
                Text(
                  product.createdDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('수정: '),
                Text(
                  product.modifiedDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
