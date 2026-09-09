import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_state.dart';

/// 물품 선택 다이얼로그 (입고·조정 화면의 [상품] 칸).
///
/// 상품 검색은 기존 [ProductBloc](getIt factory)을 재사용한다 —
/// 구매목록의 수동항목 추가 다이얼로그와 같은 방식(검색 + 300ms 디바운스 + 무한스크롤)이다.
///
/// 사용 예:
/// ```dart
/// final product = await showDialog<Product>(
///   context: context,
///   builder: (_) => const StockProductPickerDialog(),
/// );
/// ```
class StockProductPickerDialog extends StatelessWidget {
  const StockProductPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductBloc>()..add(const LoadProducts()),
      child: const _StockProductPickerView(),
    );
  }
}

class _StockProductPickerView extends StatefulWidget {
  const _StockProductPickerView();

  @override
  State<_StockProductPickerView> createState() =>
      _StockProductPickerViewState();
}

class _StockProductPickerViewState extends State<_StockProductPickerView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<ProductBloc>().add(SearchProducts(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '물품 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '상품명 검색...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ProductError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is ProductLoaded || state is ProductLoadingMore) {
                      final products = state is ProductLoaded
                          ? state.products
                          : (state as ProductLoadingMore).products;
                      final isLoadingMore = state is ProductLoadingMore;
                      if (products.isEmpty) {
                        return const Center(child: Text('조회 결과가 없습니다.'));
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: products.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == products.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final Product product = products[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              product.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: product.barcodeId != null
                                ? Text('Barcode: ${product.barcodeId}',
                                    style: const TextStyle(fontSize: 11))
                                : null,
                            onTap: () => Navigator.of(context).pop(product),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
