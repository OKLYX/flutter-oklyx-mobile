import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_state.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'product_thumbnail.dart';
import 'seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// Manual add dialog.
///
/// Search and pick a product, pick the seller it is bought for and enter a
/// quantity (>= 1); [onSubmit] receives (productId, sellerId, quantity). The
/// seller is required and starts empty on every opening (FEATURE_2610_09 D11 ·
/// D12); with one seller the field is hidden and that seller is used (D53).
/// Product search reuses [ProductBloc] (getIt factory) — the same search field
/// + 300 ms debounce + infinite scroll as product_search_page.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => AddManualItemDialog(
///     sellers: state.sellers,
///     onSubmit: (productId, sellerId, qty) => bloc.add(AddManualItem(
///         productId: productId, sellerId: sellerId, quantity: qty)),
///   ),
/// );
/// ```
class AddManualItemDialog extends StatelessWidget {
  final List<Seller> sellers;
  final void Function(int productId, int sellerId, int quantity) onSubmit;

  const AddManualItemDialog({
    required this.sellers,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductBloc>()..add(const LoadProducts()),
      child: _AddManualItemView(sellers: sellers, onSubmit: onSubmit),
    );
  }
}

class _AddManualItemView extends StatefulWidget {
  final List<Seller> sellers;
  final void Function(int productId, int sellerId, int quantity) onSubmit;

  const _AddManualItemView({required this.sellers, required this.onSubmit});

  @override
  State<_AddManualItemView> createState() => _AddManualItemViewState();
}

class _AddManualItemViewState extends State<_AddManualItemView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  Product? _selected;
  late int? _sellerId =
      widget.sellers.length == 1 ? widget.sellers.first.id : null;

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
    final sellerId = _sellerId;
    if (sellerId == null) {
      _toast('판매자를 선택하세요.');
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 1) {
      _toast('수량은 1 이상의 정수여야 합니다.');
      return;
    }
    widget.onSubmit(_selected!.id, sellerId, qty);
    Navigator.of(context).pop();
  }

  /// Only input prompts pass through here — kind = input notice
  /// (FEATURE_2610_02 · N13).
  void _toast(String message) {
    showInputNoticeToast(context, message);
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
                            selectedTileColor: AppColors.infoSurface,
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
                                    color: AppColors.brandMain)
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
              if (widget.sellers.length != 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SellerFilterDropdown(
                    sellers: widget.sellers,
                    selectedSellerId: _sellerId,
                    includeAll: false,
                    onChanged: (value) => setState(() => _sellerId = value),
                  ),
                ),
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
                  FilledButton(
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
