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
    _unitController.text = product.unit ?? '';
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
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
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
          current is ProductDetailDeleteError,
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
                        _ImageSection(),
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
                          unitController: _unitController,
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
                final isLoadingOrDeleting = current is ProductDetailUpdating || current is ProductDetailDeleting;
                final wasLoadingOrDeleting = previous is ProductDetailUpdating || previous is ProductDetailDeleting;
                return isLoadingOrDeleting || (wasLoadingOrDeleting && !isLoadingOrDeleting);
              },
              builder: (context, state) {
                if (state is ProductDetailUpdating || state is ProductDetailDeleting) {
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

class _EditablePricingCard extends StatelessWidget {
  final product;
  final bool isEditing;
  final TextEditingController priceController;
  final TextEditingController storeController;
  final TextEditingController unitController;

  const _EditablePricingCard({
    required this.product,
    required this.isEditing,
    required this.priceController,
    required this.storeController,
    required this.unitController,
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
        keyboardType: label == '가격' ? TextInputType.number : TextInputType.text,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('가격', priceController),
            if (isEditing && priceController.text.isNotEmpty)
              const SizedBox(height: 12),
            if (isEditing) _buildField('상점', storeController),
            if (isEditing && storeController.text.isNotEmpty)
              const SizedBox(height: 12),
            if (isEditing) _buildField('단위', unitController),
            if (!isEditing) ...[
              if (product.price != null) ...[
                _buildField('가격', priceController),
                const SizedBox(height: 8),
              ],
              if (product.store != null) ...[
                _buildField('상점', storeController),
                const SizedBox(height: 8),
              ],
              if (product.unit != null) _buildField('단위', unitController),
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
