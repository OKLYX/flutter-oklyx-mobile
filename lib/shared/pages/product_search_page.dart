import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_state.dart';

class ProductSearchPage extends StatelessWidget {
  const ProductSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProductBloc>()..add(const LoadProducts()),
      child: const _ProductSearchView(),
    );
  }
}

class _ProductSearchView extends StatefulWidget {
  const _ProductSearchView();

  @override
  State<_ProductSearchView> createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<_ProductSearchView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final state = context.read<ProductBloc>().state;
      if (state is ProductLoaded && state.hasMore) {
        context.read<ProductBloc>().add(const LoadMoreProducts());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Scaffold(
        key: _scaffoldKey,
        drawerScrimColor: Colors.black.withOpacity(0.3),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('상품 조회'),
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
          selectedItemColor: const Color(0xffffc417),
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
                break;
              case 3:
                context.go(Routes.notificationPath);
                break;
            }
          },
        ),
      ),
    ],
  );
}

class _ProductCard extends StatefulWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  Future<Uint8List?> _loadProductImage(int productId) async {
    try {
      final response = await getIt<DioClient>().get(
        '/api/products/$productId/image',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return response.data as Uint8List;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.product.imageUrl != null &&
        widget.product.imageUrl.toString().isNotEmpty &&
        widget.product.imageUrl != 'null';

    return GestureDetector(
      onTap: () => context.go(
        '${Routes.productDetailPath.replaceFirst(':productId', widget.product.id.toString())}',
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (hasImage)
                FutureBuilder<Uint8List?>(
                  future: _loadProductImage(widget.product.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          snapshot.data!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      );
                    }

                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.image, color: Colors.grey[500]),
                    );
                  },
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image, color: Colors.grey[500]),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barcode: ${widget.product.barcodeId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.product.price != null)
                      Text(
                        '${widget.product.price} 원',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
