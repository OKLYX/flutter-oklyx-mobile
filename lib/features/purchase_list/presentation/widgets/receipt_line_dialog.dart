import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_state.dart';
import '../../data/models/create_receipt_params.dart';
import 'product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// Amount input mode (PLAN 2609_28 D2) — total or unit price, like the intake
/// card.
enum _AmountMode { total, unit }

/// One product line of the receipt popup (FEATURE_2610_18 D76 · D96 · D97).
///
/// Search and pick any product (D96), quantity 1 or more (D97), amount
/// (total/unit, blank = not entered, D41) and 「상품 기준가에 반영」. Pops a
/// [ReceiptLineParams], or null on [취소]. No seller — every line belongs to
/// the payer seller (D89).
/// Product search reuses [ProductBloc] (getIt factory) — the same search
/// field + 300 ms debounce + infinite scroll as `add_manual_item_dialog.dart`.
///
/// ⚠️ [toastContext] = the receipt sheet's context. This dialog opens above
/// the sheet, so a toast on the dialog's own context would land on the page
/// messenger behind the sheet (`app_sheet.dart`).
///
/// Usage:
/// ```dart
/// final line = await showDialog<ReceiptLineParams>(
///   context: context,
///   builder: (_) => ReceiptLineDialog(toastContext: context),
/// );
/// ```
class ReceiptLineDialog extends StatelessWidget {
  final BuildContext toastContext;

  const ReceiptLineDialog({required this.toastContext, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductBloc>()..add(const LoadProducts()),
      child: _ReceiptLineView(toastContext: toastContext),
    );
  }
}

class _ReceiptLineView extends StatefulWidget {
  final BuildContext toastContext;

  const _ReceiptLineView({required this.toastContext});

  @override
  State<_ReceiptLineView> createState() => _ReceiptLineViewState();
}

class _ReceiptLineViewState extends State<_ReceiptLineView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _amountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  Product? _selected;
  _AmountMode _amountMode = _AmountMode.total;
  bool _reflectToBasePrice = true;

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
    _amountController.dispose();
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
    final selected = _selected;
    if (selected == null) {
      _toast('상품을 선택하세요.');
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 1) {
      _toast('수량은 1 이상의 정수여야 합니다.');
      return;
    }
    final rawAmount = _amountController.text.trim().replaceAll(',', '');
    final amount = rawAmount.isEmpty ? null : double.tryParse(rawAmount);
    if (rawAmount.isNotEmpty && (amount == null || amount < 0)) {
      _toast('금액은 0 이상의 숫자여야 합니다.');
      return;
    }
    Navigator.of(context).pop(ReceiptLineParams(
      productId: selected.id,
      productName: selected.productName,
      quantity: qty,
      totalAmount: _amountMode == _AmountMode.total ? amount : null,
      unitPrice: _amountMode == _AmountMode.unit ? amount : null,
      reflectToBasePrice: _reflectToBasePrice,
    ));
  }

  /// Only input prompts pass through here — kind = input notice
  /// (FEATURE_2610_02 · N13). Shown on the sheet's messenger
  /// (`widget.toastContext`).
  void _toast(String message) {
    showInputNoticeToast(widget.toastContext, message);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '상품 줄 추가',
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
                    width: 80,
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
                  const SizedBox(width: 8),
                  SegmentedButton<_AmountMode>(
                    segments: const [
                      ButtonSegment(
                          value: _AmountMode.total, label: Text('총액')),
                      ButtonSegment(value: _AmountMode.unit, label: Text('단가')),
                    ],
                    selected: {_amountMode},
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity:
                          VisualDensity(horizontal: -3, vertical: -3),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle:
                          WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                    ),
                    onSelectionChanged: (set) =>
                        setState(() => _amountMode = set.first),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '모르면 비움',
                        suffixText: '원',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                value: _reflectToBasePrice,
                onChanged: (v) =>
                    setState(() => _reflectToBasePrice = v ?? true),
                title: const Text('상품 기준가에 반영', style: TextStyle(fontSize: 13)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
