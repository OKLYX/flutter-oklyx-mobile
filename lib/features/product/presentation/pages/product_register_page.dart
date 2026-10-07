import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/count_unit.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/unit.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_state.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/purchase_place_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/purchase_place_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/widgets/purchase_place_checkboxes.dart';

class ProductRegisterPage extends StatefulWidget {
  const ProductRegisterPage({super.key});

  @override
  State<ProductRegisterPage> createState() => _ProductRegisterPageState();
}

class _ProductRegisterPageState extends State<ProductRegisterPage> {
  late final ProductRegisterBloc _bloc;
  late final PurchasePlaceBloc _purchasePlaceBloc;

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _countQuantityController;
  late TextEditingController _heightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _netContentController;

  Unit? _selectedUnit;
  String? _selectedCountUnit;
  List<int> _selectedPlaceIds = [];

  bool _barcodeChecked = false;
  bool _barcodeAvailable = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductRegisterBloc>();
    _purchasePlaceBloc = getIt<PurchasePlaceBloc>()..add(const PurchasePlacesRequested());
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _brandController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _countQuantityController = TextEditingController();
    _heightController = TextEditingController();
    _lengthController = TextEditingController();
    _widthController = TextEditingController();
    _netContentController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _countQuantityController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _netContentController.dispose();
    _bloc.close();
    _purchasePlaceBloc.close();
    super.dispose();
  }

  void _onCheckBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      showInputNoticeToast(context, '바코드를 입력해주세요');
      return;
    }
    _bloc.add(CheckBarcodeRequested(barcode));
  }

  /// Picks a photo (camera or gallery) and sends it for barcode reading.
  Future<void> _onScanBarcodeImage(ImageSource source) async {
    try {
      // Downscale large camera photos; barcodes stay readable at this size.
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (xFile == null || !mounted) {
        return;
      }
      _bloc.add(ScanBarcodeFromImageRequested(File(xFile.path)));
    } on Exception {
      if (!mounted) {
        return;
      }
      showErrorToast(context, '이미지를 불러오지 못했습니다.');
    }
  }

  void _onReset() {
    setState(() {
      _nameController.clear();
      _barcodeController.clear();
      _brandController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _countQuantityController.clear();
      _selectedUnit = null;
      _selectedCountUnit = null;
      _selectedPlaceIds = [];
      _heightController.clear();
      _lengthController.clear();
      _widthController.clear();
      _netContentController.clear();
      _barcodeChecked = false;
      _barcodeAvailable = false;
    });
  }

  void _onSubmit() {
    final productName = _nameController.text.trim();
    if (productName.isEmpty) {
      showInputNoticeToast(context, '상품명을 입력해주세요');
      return;
    }

    final barcode = _barcodeController.text.trim();
    if (barcode.isNotEmpty && (!_barcodeChecked || !_barcodeAvailable)) {
      showInputNoticeToast(context, '바코드 중복 체크를 하세요');
      return;
    }

    final measureError = productMeasureInputError(
      netContent: _netContentController.text,
      hasNetContentUnit: _selectedUnit != null,
      countQuantity: _countQuantityController.text,
      countUnit: _selectedCountUnit,
    );
    if (measureError != null) {
      showNoticeToast(context, measureError);
      return;
    }

    _bloc.add(RegisterProductRequested(
      productName: productName,
      barcodeId: barcode.isEmpty ? null : barcode,
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      price: _priceController.text.isEmpty ? null : int.tryParse(_priceController.text),
      purchasePlaceIds: _selectedPlaceIds,
      netContentUnit: _selectedUnit,
      packageHeight: _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
      packageLength: _lengthController.text.isEmpty ? null : double.tryParse(_lengthController.text),
      packageWidth: _widthController.text.isEmpty ? null : double.tryParse(_widthController.text),
      netContent: _netContentController.text.isEmpty ? null : double.tryParse(_netContentController.text),
      countQuantity: int.tryParse(_countQuantityController.text.trim()),
      countUnit: _selectedCountUnit,
    ));
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: ScaffoldWithNavBar(
      title: '상품등록',
      navBarIndex: 2,
      showAppBarDrawerButton: false,
      body: BlocListener<ProductRegisterBloc, ProductRegisterState>(
            listenWhen: (previous, current) =>
                current is BarcodeAvailable ||
                current is BarcodeUnavailable ||
                current is BarcodeCheckError ||
                current is BarcodeScanSuccess ||
                current is BarcodeScanNotFound ||
                current is BarcodeScanError ||
                current is ProductRegisterSuccess ||
                current is ProductRegisterError,
            listener: (context, state) {
              if (state is ProductRegisterSuccess) {
                showSuccessToast(context, '상품이 등록되었습니다');
                context.go(Routes.productSearchPath);
              } else if (state is ProductRegisterError) {
                showErrorToast(context, state.message);
              } else if (state is BarcodeAvailable) {
                setState(() {
                  _barcodeChecked = true;
                  _barcodeAvailable = true;
                });
                showSuccessToast(context, '사용 가능한 바코드입니다');
              } else if (state is BarcodeUnavailable) {
                setState(() {
                  _barcodeChecked = true;
                  _barcodeAvailable = false;
                });
                showNoticeToast(context, state.message);
              } else if (state is BarcodeCheckError) {
                showErrorToast(context, state.message);
              } else if (state is BarcodeScanSuccess) {
                // Replace the field and require a fresh duplicate check.
                setState(() {
                  _barcodeController.text = state.barcode;
                  _barcodeChecked = false;
                  _barcodeAvailable = false;
                });
                showSuccessToast(context, '바코드를 읽었습니다. 중복 확인을 해주세요.');
              } else if (state is BarcodeScanNotFound) {
                showNoticeToast(
                  context,
                  '바코드를 읽지 못했습니다. 바코드가 잘 보이는 사진으로 다시 시도해 주세요.',
                );
              } else if (state is BarcodeScanError) {
                showErrorToast(context, state.message);
              }
            },
            child: BlocBuilder<ProductRegisterBloc, ProductRegisterState>(
              builder: (context, state) {
                if (state is ProductRegisterLoading) {
                  return const AppPageBody(children: [AppLoading()]);
                }

                return AppPageBody.scroll(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('기본 정보'),
                      const SizedBox(height: 12),
                      _buildTextField('상품명 *', _nameController),
                      const SizedBox(height: 12),
                      _buildBarcodeField(),
                      const SizedBox(height: 12),
                      _buildTextField('브랜드', _brandController),
                      const SizedBox(height: 12),
                      _buildTextField('설명', _descriptionController, maxLines: 3),
                      const SizedBox(height: 24),
                      _buildSectionTitle('가격 및 구매처'),
                      const SizedBox(height: 12),
                      _buildTextField('가격', _priceController, keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      PurchasePlaceCheckboxes(
                        bloc: _purchasePlaceBloc,
                        selectedIds: _selectedPlaceIds,
                        onChanged: (ids) => setState(() => _selectedPlaceIds = ids),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField('내용물 양', _netContentController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 12),
                      _buildUnitDropdown(),
                      const SizedBox(height: 12),
                      _buildTextField('개수', _countQuantityController, keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildCountUnitDropdown(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('치수'),
                      const SizedBox(height: 12),
                      _buildTextField('높이', _heightController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 12),
                      _buildTextField('길이', _lengthController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 12),
                      _buildTextField('너비', _widthController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _bloc.state is ProductRegisterLoading ? null : _onSubmit,
                          child: const Text('상품 등록'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
      inputFormatters: label == '가격' || label == '개수'
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildCountUnitDropdown() => DropdownButtonFormField<String>(
        value: _selectedCountUnit,
        decoration: InputDecoration(
          labelText: '개수 단위',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: [
          const DropdownMenuItem<String>(child: Text('선택 안 함')),
          ...kCountUnits.map(
            (unit) => DropdownMenuItem<String>(value: unit, child: Text(unit)),
          ),
        ],
        onChanged: (value) => setState(() => _selectedCountUnit = value),
      );

  Widget _buildBarcodeField() {
    final isCheckingInProgress = _bloc.state is BarcodeCheckLoading;
    final isScanning = _bloc.state is BarcodeScanLoading;
    final showResetButton = _barcodeChecked && _barcodeAvailable;

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              _buildTextField('바코드', _barcodeController, enabled: !showResetButton),
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
        _buildScanImageButton(
          enabled: !showResetButton && !isCheckingInProgress && !isScanning,
          isScanning: isScanning,
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: isCheckingInProgress || isScanning
                ? null
                : (showResetButton ? _onReset : _onCheckBarcode),
            child: Text(showResetButton ? '리셋' : '확인'),
          ),
        ),
      ],
    );
  }

  /// "이미지로 스캔" — opens a camera / gallery menu, then uploads the photo.
  /// Disabled while the barcode is locked by a passed duplicate check.
  Widget _buildScanImageButton({
    required bool enabled,
    required bool isScanning,
  }) =>
      MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.photo_camera_outlined),
            onPressed: () => _onScanBarcodeImage(ImageSource.camera),
            child: const Text('카메라로 촬영'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.photo_library_outlined),
            onPressed: () => _onScanBarcodeImage(ImageSource.gallery),
            child: const Text('앨범에서 선택'),
          ),
        ],
        builder: (context, controller, _) => SizedBox(
          height: 56,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: enabled
                ? () => controller.isOpen
                    ? controller.close()
                    : controller.open()
                : null,
            child: isScanning
                ? const AppBusyLabel('이미지로 스캔')
                : const Text('이미지로 스캔'),
          ),
        ),
      );

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<Unit>(
      value: _selectedUnit,
      decoration: InputDecoration(
        labelText: '단위',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: Unit.values
          .map((unit) => DropdownMenuItem(
            value: unit,
            child: Text(unit.displayName),
          ))
          .toList(),
      onChanged: (Unit? value) {
        setState(() {
          _selectedUnit = value;
        });
      },
    );
  }
}
