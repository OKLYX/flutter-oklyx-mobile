import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_drawer.dart';
import 'package:flutter_oklyn_mobile/core/constants/app_constants.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/unit.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/widgets/stock_card.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailBloc _productDetailBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _storeController;
  late TextEditingController _unitController;
  late TextEditingController _heightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _weightController;

  Unit? _selectedUnit;

  ProductDetailState? _previousState;

  @override
  void initState() {
    super.initState();
    _productDetailBloc = getIt<ProductDetailBloc>()..add(LoadProductDetail(widget.productId));
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _storeController = TextEditingController();
    _unitController = TextEditingController();
    _heightController = TextEditingController();
    _lengthController = TextEditingController();
    _widthController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _unitController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _weightController.dispose();
    _productDetailBloc.close();
    super.dispose();
  }

  void _populateControllers(dynamic product) {
    _nameController.text = product.productName ?? '';
    _brandController.text = product.brand ?? '';
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price?.toString() ?? '';
    _storeController.text = product.store ?? '';
    _selectedUnit = Unit.fromString(product.unit);
    _heightController.text = product.volumeHeight?.toString() ?? '';
    _lengthController.text = product.volumeLong?.toString() ?? '';
    _widthController.text = product.volumeShort?.toString() ?? '';
    _weightController.text = product.weight?.toString() ?? '';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 삭제'),
        content: const Text('정말로 이 상품을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _productDetailBloc.add(const DeleteProductRequested());
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    _productDetailBloc.add(UpdateProductRequested(
      productName: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      price: _priceController.text.isEmpty ? null : int.tryParse(_priceController.text),
      store: _storeController.text.trim().isEmpty ? null : _storeController.text.trim(),
      unit: _selectedUnit,
      volumeHeight: _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
      volumeLong: _lengthController.text.isEmpty ? null : double.tryParse(_lengthController.text),
      volumeShort: _widthController.text.isEmpty ? null : double.tryParse(_widthController.text),
      weight: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
    ));
  }

  void _onCancel() {
    _productDetailBloc.add(const EditModeToggled());
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _productDetailBloc,
    child: BlocListener<ProductDetailBloc, ProductDetailState>(
      listenWhen: (previous, current) =>
          current is ProductDetailLoaded ||
          current is ProductDetailEditing ||
          current is ProductDetailDeleteSuccess ||
          current is ProductDetailDeleteError ||
          current is ProductDetailImageError,
      listener: (context, state) {
        if (state is ProductDetailLoaded) {
          _populateControllers(state.product);
          if (_previousState is ProductDetailUpdating) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('상품이 수정되었습니다')),
            );
          }
        }
        if (state is ProductDetailEditing && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state is ProductDetailDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품이 삭제되었습니다')),
          );
          context.go(Routes.productSearchPath);
        }
        if (state is ProductDetailDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is ProductDetailImageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        _previousState = state;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerScrimColor: Colors.black.withOpacity(0.3),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go(Routes.productSearchPath),
          ),
          title: const Text('상품상세'),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            BlocBuilder<ProductDetailBloc, ProductDetailState>(
              builder: (context, state) {
                if (state is ProductDetailLoaded) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black),
                        onPressed: () => _productDetailBloc.add(const EditModeToggled()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black),
                        onPressed: () => _showDeleteDialog(context),
                      ),
                    ],
                  );
                } else if (state is ProductDetailEditing) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _onSave,
                        child: const Text('저장'),
                      ),
                      TextButton(
                        onPressed: _onCancel,
                        child: const Text('취소'),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            BlocBuilder<ProductDetailBloc, ProductDetailState>(
              buildWhen: (previous, current) =>
                  current is ProductDetailLoading ||
                  current is ProductDetailError ||
                  current is ProductDetailLoaded ||
                  current is ProductDetailEditing,
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

                if (state is ProductDetailLoaded || state is ProductDetailEditing) {
                  final product = state is ProductDetailLoaded ? state.product : (state as ProductDetailEditing).product;
                  final isEditing = state is ProductDetailEditing;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _ImageSection(product: product),
                        const SizedBox(height: 12),
                        _EditableBasicInfoCard(
                          product: product,
                          isEditing: isEditing,
                          nameController: _nameController,
                        ),
                        const SizedBox(height: 12),
                        _EditablePricingCard(
                          product: product,
                          isEditing: isEditing,
                          priceController: _priceController,
                          storeController: _storeController,
                          selectedUnit: _selectedUnit,
                          onUnitChanged: (Unit? unit) {
                            setState(() {
                              _selectedUnit = unit;
                            });
                          },
                        ),
                        if (product.volumeHeight != null ||
                            product.volumeLong != null ||
                            product.volumeShort != null ||
                            product.weight != null) ...[
                          const SizedBox(height: 12),
                          _EditableDimensionsCard(
                            product: product,
                            isEditing: isEditing,
                            heightController: _heightController,
                            lengthController: _lengthController,
                            widthController: _widthController,
                            weightController: _weightController,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _EditableDetailsCard(
                          product: product,
                          isEditing: isEditing,
                          brandController: _brandController,
                          descriptionController: _descriptionController,
                        ),
                        const SizedBox(height: 12),
                        _TimestampsCard(product: product),
                        if (!isEditing) ...[
                          const SizedBox(height: 12),
                          BlocProvider.value(
                            value: getIt<StockBloc>(),
                            child: StockCard(
                              barcodeId: product.barcodeId,
                              productName: product.productName,
                            ),
                          ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            BlocBuilder<ProductDetailBloc, ProductDetailState>(
              buildWhen: (previous, current) {
                final isLoadingOrDeleting = current is ProductDetailUpdating ||
                    current is ProductDetailDeleting ||
                    current is ProductDetailImageUploading ||
                    current is ProductDetailImageDeleting;
                final wasLoadingOrDeleting = previous is ProductDetailUpdating ||
                    previous is ProductDetailDeleting ||
                    previous is ProductDetailImageUploading ||
                    previous is ProductDetailImageDeleting;
                return isLoadingOrDeleting || (wasLoadingOrDeleting && !isLoadingOrDeleting);
              },
              builder: (context, state) {
                if (state is ProductDetailUpdating ||
                    state is ProductDetailDeleting ||
                    state is ProductDetailImageUploading ||
                    state is ProductDetailImageDeleting) {
                  return Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xffffc417),
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
        drawer: const AppDrawer(),
      ),
    ),
  );
}

class _ImageSection extends StatefulWidget {
  final dynamic product;

  const _ImageSection({required this.product});

  @override
  State<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<_ImageSection> {
  final _picker = ImagePicker();

  void _showImageDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _pickAndUpload(BuildContext context) async {
    try {
      final xFile = await _picker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;
      if (!context.mounted) return;
      context.read<ProductDetailBloc>().add(UploadImageRequested(File(xFile.path)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  Widget _buildPlaceholder({bool showPlus = false}) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        showPlus ? Icons.add : Icons.image,
        color: Colors.grey[500],
        size: 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      buildWhen: (previous, current) =>
          current is ProductDetailLoaded ||
          current is ProductDetailEditing ||
          current is ProductDetailImageUploading ||
          current is ProductDetailImageDeleting,
      builder: (context, state) {
        final product = state is ProductDetailLoaded
            ? state.product
            : state is ProductDetailEditing
                ? state.product
                : widget.product;

        final isLoading = state is ProductDetailImageUploading ||
            state is ProductDetailImageDeleting;
        final hasImage = product?.imageUrl != null &&
            product!.imageUrl.toString().isNotEmpty &&
            product.imageUrl != 'null';

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            children: [
              if (hasImage)
                FutureBuilder<Uint8List?>(
                  future: _loadProductImage(product!.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      return GestureDetector(
                        onTap: () => _showImageDialog(context, snapshot.data!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            snapshot.data!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildPlaceholder(),
                    );
                  },
                )
              else
                GestureDetector(
                  onTap: isLoading ? null : () => _pickAndUpload(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPlaceholder(showPlus: true),
                  ),
                ),
              if (hasImage && !isLoading)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => context
                        .read<ProductDetailBloc>()
                        .add(const DeleteImageRequested()),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              if (isLoading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.black38,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EditableBasicInfoCard extends StatelessWidget {
  final product;
  final bool isEditing;
  final TextEditingController nameController;

  const _EditableBasicInfoCard({
    required this.product,
    required this.isEditing,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditing)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '상품명',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              )
            else
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

class _EditablePricingCard extends StatefulWidget {
  final product;
  final bool isEditing;
  final TextEditingController priceController;
  final TextEditingController storeController;
  final Unit? selectedUnit;
  final Function(Unit?) onUnitChanged;

  const _EditablePricingCard({
    required this.product,
    required this.isEditing,
    required this.priceController,
    required this.storeController,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  @override
  State<_EditablePricingCard> createState() => _EditablePricingCardState();
}

class _EditablePricingCardState extends State<_EditablePricingCard> {
  Widget _buildField(String label, TextEditingController controller) {
    if (widget.isEditing) {
      return TextField(
        controller: controller,
        keyboardType: label == '가격' ? TextInputType.number : TextInputType.text,
        inputFormatters: label == '가격'
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
    } else {
      final value = controller.text;
      if (value.isEmpty) return const SizedBox.shrink();
      return Row(
        children: [
          Text('$label: '),
          Text(
            label == '가격' ? '$value 원' : value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      );
    }
  }

  Widget _buildUnitField() {
    if (widget.isEditing) {
      return DropdownButtonFormField<Unit>(
        value: widget.selectedUnit,
        decoration: InputDecoration(
          labelText: '단위',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: Unit.values
            .map((unit) => DropdownMenuItem(
              value: unit,
              child: Text(unit.displayName),
            ))
            .toList(),
        onChanged: widget.onUnitChanged,
      );
    } else {
      if (widget.product.unit == null) return const SizedBox.shrink();
      return Row(
        children: [
          const Text('단위: '),
          Text(
            widget.product.unit,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing) ...[
              _buildField('가격', widget.priceController),
              if (widget.priceController.text.isNotEmpty)
                const SizedBox(height: 12),
              _buildField('상점', widget.storeController),
              if (widget.storeController.text.isNotEmpty)
                const SizedBox(height: 12),
              _buildUnitField(),
            ] else ...[
              if (widget.product.price != null) ...[
                _buildField('가격', widget.priceController),
                const SizedBox(height: 8),
              ],
              if (widget.product.store != null) ...[
                _buildField('상점', widget.storeController),
                const SizedBox(height: 8),
              ],
              if (widget.product.unit != null) _buildUnitField(),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditableDimensionsCard extends StatelessWidget {
  final product;
  final bool isEditing;
  final TextEditingController heightController;
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController weightController;

  const _EditableDimensionsCard({
    required this.product,
    required this.isEditing,
    required this.heightController,
    required this.lengthController,
    required this.widthController,
    required this.weightController,
  });

  Widget _buildField(String label, TextEditingController controller) {
    if (isEditing) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        keyboardType: TextInputType.number,
      );
    } else {
      final value = controller.text;
      if (value.isEmpty) return const SizedBox.shrink();
      return Row(
        children: [
          SizedBox(width: 80, child: Text('$label:')),
          Text(value),
        ],
      );
    }
  }

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
            if (isEditing) ...[
              _buildField('높이', heightController),
              const SizedBox(height: 12),
              _buildField('길이', lengthController),
              const SizedBox(height: 12),
              _buildField('너비', widthController),
              const SizedBox(height: 12),
              _buildField('무게', weightController),
            ] else ...[
              if (product.volumeHeight != null) ...[
                _buildField('높이', heightController),
                const SizedBox(height: 4),
              ],
              if (product.volumeLong != null) ...[
                _buildField('길이', lengthController),
                const SizedBox(height: 4),
              ],
              if (product.volumeShort != null) ...[
                _buildField('너비', widthController),
                const SizedBox(height: 4),
              ],
              if (product.weight != null) _buildField('무게', weightController),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditableDetailsCard extends StatelessWidget {
  final product;
  final bool isEditing;
  final TextEditingController brandController;
  final TextEditingController descriptionController;

  const _EditableDetailsCard({
    required this.product,
    required this.isEditing,
    required this.brandController,
    required this.descriptionController,
  });

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    if (isEditing) {
      return TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
    } else {
      final value = controller.text;
      if (value.isEmpty) return const SizedBox.shrink();
      return Row(
        children: [
          Text('$label: '),
          Expanded(
            child: Text(value),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditing) ...[
              _buildField('브랜드', brandController),
              const SizedBox(height: 12),
              _buildField('설명', descriptionController, maxLines: 3),
              const SizedBox(height: 12),
            ] else ...[
              if (product.brand != null) ...[
                _buildField('브랜드', brandController),
                const SizedBox(height: 8),
              ],
              if (product.description != null) ...[
                _buildField('설명', descriptionController),
                const SizedBox(height: 8),
              ],
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
