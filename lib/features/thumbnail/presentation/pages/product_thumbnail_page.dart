import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/product_thumbnail_bloc.dart';
import '../bloc/product_thumbnail_event.dart';
import '../bloc/product_thumbnail_state.dart';
import '../widgets/field_value_panel.dart';
import '../widgets/thumbnail_seller_card.dart';

/// Per-seller thumbnail page (consume-only). Reached from the product detail page
/// with `productId` + `product.brand` / `product.productName` (GoRouter `extra`),
/// used to pre-fill the generation panel's reserved fields.
class ProductThumbnailPage extends StatefulWidget {
  final int productId;
  final String? productBrand;
  final String? productName;

  const ProductThumbnailPage({
    super.key,
    required this.productId,
    this.productBrand,
    this.productName,
  });

  @override
  State<ProductThumbnailPage> createState() => _ProductThumbnailPageState();
}

class _ProductThumbnailPageState extends State<ProductThumbnailPage> {
  final ImagePicker _picker = ImagePicker();
  int? _selectedSellerId;
  String? _shownError;

  void _reload() {
    context.read<ProductThumbnailBloc>().add(LoadThumbnails(
          productId: widget.productId,
          productBrand: widget.productBrand,
          productName: widget.productName,
        ));
  }

  Future<void> _pickAndOverride(int sellerId) async {
    try {
      final xFile = await _picker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;
      if (!mounted) return;
      context
          .read<ProductThumbnailBloc>()
          .add(OverrideThumbnail(sellerId, File(xFile.path)));
    } catch (e) {
      if (!mounted) return;
      _showSnack('이미지 선택 실패: $e');
    }
  }

  Future<void> _confirmDelete(int sellerId, String sellerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('썸네일 삭제'),
        content: Text('$sellerName 판매자의 썸네일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ProductThumbnailBloc>().add(DeleteThumbnail(sellerId));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매자별 썸네일',
      navBarIndex: 2,
      onBackPressed: () => context.pop(),
      body: BlocConsumer<ProductThumbnailBloc, ProductThumbnailState>(
        listenWhen: (previous, current) =>
            current is ProductThumbnailLoaded && current.actionError != null,
        listener: (context, state) {
          if (state is ProductThumbnailLoaded && state.actionError != null) {
            // Guard against re-showing the same transient message on rebuild.
            if (state.actionError != _shownError) {
              _shownError = state.actionError;
              _showSnack(state.actionError!);
            }
          }
        },
        builder: (context, state) {
          if (state is ProductThumbnailLoading ||
              state is ProductThumbnailInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductThumbnailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (state is ProductThumbnailLoaded) {
            return _buildLoaded(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoaded(ProductThumbnailLoaded state) {
    final selected = _selectedSellerId ??
        (state.sellers.isNotEmpty ? state.sellers.first.id : null);

    return ListView(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: kBottomNavigationBarHeight + 40,
      ),
      children: [
        // Generation panel.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.fields.isNotEmpty) ...[
                FieldValuePanel(
                  key: const ValueKey('thumbnail-field-panel'),
                  fields: state.fields,
                  initialValues: state.fieldValues,
                  onChanged: (key, value) => context
                      .read<ProductThumbnailBloc>()
                      .add(UpdateFieldValue(key, value)),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: '판매자',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: state.sellers
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.sellerName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSellerId = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (selected == null || state.actionSellerId != null)
                        ? null
                        : () => context
                            .read<ProductThumbnailBloc>()
                            .add(GenerateThumbnail(selected)),
                    child: const Text('썸네일 생성'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // Per-seller thumbnail cards.
        if (state.thumbnails.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                '생성된 썸네일이 없습니다.\n판매자를 선택하고 "썸네일 생성"을 눌러주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...state.thumbnails.map((thumbnail) => ThumbnailSellerCard(
                thumbnail: thumbnail,
                isBusy: state.actionSellerId == thumbnail.sellerId,
                onRegenerate: () => context
                    .read<ProductThumbnailBloc>()
                    .add(GenerateThumbnail(thumbnail.sellerId)),
                onUpload: () => _pickAndOverride(thumbnail.sellerId),
                onDelete: () =>
                    _confirmDelete(thumbnail.sellerId, thumbnail.sellerName),
              )),
      ],
    );
  }
}
