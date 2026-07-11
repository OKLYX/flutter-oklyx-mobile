import 'dart:async';
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
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';

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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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

  /// 검색어 입력 시 300ms 디바운스 후 서버 검색을 요청한다.
  /// 상품 목록은 서버 페이지네이션(/api/products?search=)을 사용하므로
  /// 매 키 입력마다 호출하지 않고 디바운스로 요청 수를 줄인다.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ProductBloc>().add(SearchProducts(value));
    });
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
    title: '상품 조회',
    navBarIndex: 2,
    showDrawer: true,
    showAppBarDrawerButton: false,
    backgroundColor: Colors.white,
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '상품명 검색...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
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

                  if (products.isEmpty) {
                    return const Center(child: Text('조회 결과가 없습니다.'));
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    itemCount: products.length + (isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(height: 1),
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
          ),
        ],
      ),
    ),
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

    return InkWell(
      onTap: () => context.go(
        '${Routes.productDetailPath.replaceFirst(':productId', widget.product.id.toString())}',
      ),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                FutureBuilder<Uint8List?>(
                  future: _loadProductImage(widget.product.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      return ImageWithZoomButton(
                        image: MemoryImage(snapshot.data!),
                        // The whole image area zooms; the rest of the row still
                        // navigates to the detail page via its InkWell.
                        child: Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey[400],
                          child: Image.memory(
                            snapshot.data!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }

                    return Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[500]),
                    );
                  },
                )
              else
                Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[300],
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
                    if (widget.product.brand != null &&
                        widget.product.brand!.isNotEmpty) ...[
                      Text(
                        '브랜드: ${widget.product.brand}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (widget.product.barcodeId != null)
                      Text(
                        'Barcode: ${widget.product.barcodeId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.product.barcodeId != null)
                      const SizedBox(height: 4),
                    if (widget.product.price != null)
                      Text(
                        '가격: ${widget.product.price} 원',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
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
