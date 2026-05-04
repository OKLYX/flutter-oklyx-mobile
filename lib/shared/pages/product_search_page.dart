import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_state.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  late final ProductBloc _productBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _productBloc = getIt<ProductBloc>()..add(const LoadProducts());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _productBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      if (_productBloc.state is ProductLoaded &&
          (_productBloc.state as ProductLoaded).hasMore) {
        _productBloc.add(const LoadMoreProducts());
      }
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _productBloc,
    child: Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawerScrimColor: Colors.black.withOpacity(0.3),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Product Search'),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: Colors.grey[100],
          body: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is ProductError) {
                return Center(
                  child: Text(state.message),
                );
              }

              if (state is ProductLoaded || state is ProductLoadingMore) {
                final products = state is ProductLoaded
                    ? state.products
                    : (state as ProductLoadingMore).products;
                final isLoadingMore = state is ProductLoadingMore;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: products.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _ProductCard(product: products[index]);
                  },
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
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.checklist),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.notifications),
                label: '',
              ),
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
                  // Already on product pages
                  setState(() {});
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

class _ProductCard extends StatelessWidget {
  final product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.image, color: Colors.grey[500]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.brand != null)
                    Text(
                      product.brand!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.price != null)
                        Text(
                          '${product.price} 원',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      if (product.price != null && product.store != null)
                        const Text(' • '),
                      if (product.store != null)
                        Expanded(
                          child: Text(
                            product.store!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Barcode: ${product.barcodeId}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
