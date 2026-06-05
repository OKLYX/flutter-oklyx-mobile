import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_event.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class ProductListingRegisterPage extends StatefulWidget {
  const ProductListingRegisterPage({super.key});

  @override
  State<ProductListingRegisterPage> createState() =>
      _ProductListingRegisterPageState();
}

class _ProductListingRegisterPageState extends State<ProductListingRegisterPage> {
  final _platformCtrl = TextEditingController();
  final _platformProductIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _categoryIdCtrl = TextEditingController();
  final _carrierIdCtrl = TextEditingController();
  final _packageIdCtrl = TextEditingController();
  final _sellerIdCtrl = TextEditingController();

  final _initialFormData = {
    'platform': '',
    'platformProductId': '',
    'name': '',
    'categoryId': '',
    'carrierId': '',
    'packageId': '',
    'sellerId': '',
  };

  @override
  void initState() {
    super.initState();
    context.read<ProductListingCreateBloc>().add(const ResetCreateForm());
  }

  @override
  void dispose() {
    _platformCtrl.dispose();
    _platformProductIdCtrl.dispose();
    _nameCtrl.dispose();
    _categoryIdCtrl.dispose();
    _carrierIdCtrl.dispose();
    _packageIdCtrl.dispose();
    _sellerIdCtrl.dispose();
    super.dispose();
  }

  bool _isSubmitEnabled(ProductListingCreateLoaded state) {
    final hasErrors = state.validationErrors.values.any((e) => e != null);
    final isChanged = state.formData != _initialFormData;
    return !hasErrors && isChanged;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매상품 등록',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.salesProductsPath),
      body: BlocListener<ProductListingCreateBloc, ProductListingCreateState>(
        listener: (context, state) {
          if (state is ProductListingCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('판매상품이 등록되었습니다.'),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              context.go(Routes.salesProductsPath);
            });
          } else if (state is ProductListingCreateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
              ),
            );
          }
        },
        child: BlocBuilder<ProductListingCreateBloc, ProductListingCreateState>(
          builder: (context, state) {
            if (state is! ProductListingCreateLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final isSubmitting = state is ProductListingCreateLoading;
            final isEnabled = _isSubmitEnabled(state);
            final bloc = context.read<ProductListingCreateBloc>();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _platformCtrl,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: '플랫폼 *',
                        hintText: '예: COUPANG',
                        errorText: state.validationErrors['platform'],
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(
                        UpdateFormField(field: 'platform', value: v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _platformProductIdCtrl,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: '플랫폼 상품 ID *',
                        errorText: state.validationErrors['platformProductId'],
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(
                        UpdateFormField(field: 'platformProductId', value: v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      enabled: !isSubmitting,
                      maxLength: 255,
                      decoration: InputDecoration(
                        labelText: '상품명 *',
                        errorText: state.validationErrors['name'],
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(
                        UpdateFormField(field: 'name', value: v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _categoryIdCtrl,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: '카테고리 ID (선택)',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(
                        UpdateFormField(field: 'categoryId', value: v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _carrierIdCtrl,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: '택배사 ID (선택)',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(
                        UpdateFormField(field: 'carrierId', value: v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _packageIdCtrl,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: '상자비 ID (선택)',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(
                        UpdateFormField(field: 'packageId', value: v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sellerIdCtrl,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: '판매자 ID (선택)',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(
                        UpdateFormField(field: 'sellerId', value: v),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                isSubmitting ? null : () => context.go(Routes.salesProductsPath),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (isSubmitting || !isEnabled)
                                ? null
                                : () => bloc.add(
                                      const SubmitProductListingCreate(),
                                    ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('등록'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
