import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/unit.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_state.dart';

class ProductRegisterPage extends StatefulWidget {
  const ProductRegisterPage({super.key});

  @override
  State<ProductRegisterPage> createState() => _ProductRegisterPageState();
}

class _ProductRegisterPageState extends State<ProductRegisterPage> {
  late final ProductRegisterBloc _bloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _storeController;
  late TextEditingController _heightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _weightController;

  Unit? _selectedUnit;

  bool _barcodeChecked = false;
  bool _barcodeAvailable = false;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductRegisterBloc>();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _brandController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _storeController = TextEditingController();
    _heightController = TextEditingController();
    _lengthController = TextEditingController();
    _widthController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _weightController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onCheckBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('바코드를 입력해주세요')),
      );
      return;
    }
    _bloc.add(CheckBarcodeRequested(barcode));
  }

  void _onReset() {
    setState(() {
      _nameController.clear();
      _barcodeController.clear();
      _brandController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _storeController.clear();
      _selectedUnit = null;
      _heightController.clear();
      _lengthController.clear();
      _widthController.clear();
      _weightController.clear();
      _barcodeChecked = false;
      _barcodeAvailable = false;
    });
  }

  void _onSubmit() {
    if (!_barcodeAvailable || !_barcodeChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('바코드 확인을 먼저 해주세요')),
      );
      return;
    }

    final productName = _nameController.text.trim();
    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품명을 입력해주세요')),
      );
      return;
    }

    _bloc.add(RegisterProductRequested(
      productName: productName,
      barcodeId: _barcodeController.text.trim(),
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

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.black.withOpacity(0.3),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('상품등록'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: BlocListener<ProductRegisterBloc, ProductRegisterState>(
            listenWhen: (previous, current) =>
                current is BarcodeAvailable ||
                current is BarcodeUnavailable ||
                current is BarcodeCheckError ||
                current is ProductRegisterSuccess ||
                current is ProductRegisterError,
            listener: (context, state) {
              if (state is ProductRegisterSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('상품이 등록되었습니다')),
                );
                context.go(Routes.productSearchPath);
              } else if (state is ProductRegisterError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is BarcodeAvailable) {
                setState(() {
                  _barcodeChecked = true;
                  _barcodeAvailable = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('사용 가능한 바코드입니다')),
                );
              } else if (state is BarcodeUnavailable) {
                setState(() {
                  _barcodeChecked = true;
                  _barcodeAvailable = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is BarcodeCheckError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            child: BlocBuilder<ProductRegisterBloc, ProductRegisterState>(
              builder: (context, state) {
                if (state is ProductRegisterLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('기본 정보'),
                      const SizedBox(height: 12),
                      _buildBarcodeField(),
                      const SizedBox(height: 12),
                      _buildTextField('상품명 *', _nameController, enabled: _barcodeAvailable),
                      const SizedBox(height: 12),
                      _buildTextField('브랜드', _brandController, enabled: _barcodeAvailable),
                      const SizedBox(height: 12),
                      _buildTextField('설명', _descriptionController, maxLines: 3, enabled: _barcodeAvailable),
                      const SizedBox(height: 24),
                      _buildSectionTitle('가격 및 판매처'),
                      const SizedBox(height: 12),
                      _buildTextField('가격', _priceController, keyboardType: TextInputType.number, enabled: _barcodeAvailable),
                      const SizedBox(height: 12),
                      _buildTextField('판매처', _storeController, enabled: _barcodeAvailable),
                      const SizedBox(height: 12),
                      _buildUnitDropdown(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('치수'),
                      const SizedBox(height: 12),
                      _buildTextField('높이', _heightController, keyboardType: TextInputType.number, enabled: _barcodeAvailable),
                      const SizedBox(height: 12),
                      _buildTextField('길이', _lengthController, keyboardType: TextInputType.number, enabled: _barcodeAvailable),
                      const SizedBox(height: 12),
                      _buildTextField('너비', _widthController, keyboardType: TextInputType.number, enabled: _barcodeAvailable),
                      const SizedBox(height: 12),
                      _buildTextField('무게', _weightController, keyboardType: TextInputType.number, enabled: _barcodeAvailable),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_bloc.state is ProductRegisterLoading || !_barcodeAvailable) ? null : _onSubmit,
                          child: const Text('상품 등록'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
        ),
    );

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: maxLines == 1,
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
  }

  Widget _buildBarcodeField() {
    final isCheckingInProgress = _bloc.state is BarcodeCheckLoading;
    final showResetButton = _barcodeChecked && _barcodeAvailable;

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              _buildTextField('바코드 *', _barcodeController, enabled: !showResetButton),
              if (!showResetButton)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _barcodeController.clear();
                        });
                      },
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isCheckingInProgress ? null : (showResetButton ? _onReset : _onCheckBarcode),
            child: Text(showResetButton ? '리셋' : '확인'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<Unit>(
      value: _selectedUnit,
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
      onChanged: _barcodeAvailable
          ? (Unit? value) {
            setState(() {
              _selectedUnit = value;
            });
          }
          : null,
    );
  }
}
