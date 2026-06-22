import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_state.dart';
import 'product_thumbnail.dart';

/// 수동항목 추가 다이얼로그.
///
/// 상품을 검색·선택하고 수량(>=1)을 입력하면 [onSubmit]에 (productId, quantity)를
/// 전달한다. 상품 검색은 기존 [ProductBloc](getIt factory)을 재사용한다
/// (product_search_page와 동일: 검색필드 + 300ms 디바운스 + 무한스크롤).
///
/// 호출 예:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => AddManualItemDialog(
///     onSubmit: (productId, qty) =>
///         bloc.add(AddManualItem(productId: productId, quantity: qty)),
///   ),
/// );
/// ```
class AddManualItemDialog extends StatelessWidget {
  final void Function(int productId, int quantity) onSubmit;

  const AddManualItemDialog({required this.onSubmit, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductBloc>()..add(const LoadProducts()),
      child: _AddManualItemView(onSubmit: onSubmit),
    );
  }
}

class _AddManualItemView extends StatefulWidget {
  final void Function(int productId, int quantity) onSubmit;

  const _AddManualItemView({required this.onSubmit});

  @override
  State<_AddManualItemView> createState() => _AddManualItemViewState();
}

class _AddManualItemViewState extends State<_AddManualItemView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  Product? _selected;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _qtyController.dispose();
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
      context.read<ProductBloc>().add(SearchProducts(value));
    });
  }

  void _submit() {
    if (_selected == null) {
      _toast('상품을 선택하세요.');
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 1) {
      _toast('수량은 1 이상의 정수여야 합니다.');
      return;
    }
    widget.onSubmit(_selected!.id, qty);
    Navigator.of(context).pop();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
        ),
      );
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
                '수동항목 추가',
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
                          final product = products[index];
                          final selected = _selected?.id == product.id;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor: Colors.blue[50],
                            leading: ProductThumbnail(
                                productId: product.id, size: 40),
                            title: Text(
                              product.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: product.barcodeId != null
                                ? Text('Barcode: ${product.barcodeId}',
                                    style: const TextStyle(fontSize: 11))
                                : null,
                            trailing: selected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.blue)
                                : null,
                            onTap: () => setState(() => _selected = product),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const Divider(),
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '선택: ${_selected!.productName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '수량',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('추가'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
