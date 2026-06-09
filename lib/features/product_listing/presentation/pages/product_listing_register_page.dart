import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_event.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_state.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/domain/entities/product_listing.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/product_listing_refresh.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

const List<String> PLATFORMS = ['COUPANG', 'GMARKET', 'AUCTION', 'SMARTSTORE'];

// ── 마진 계산 헬퍼 (프론트 ProductListingSinglePageForm과 동일 공식) ──
// margin = 판매가 − (판매가 × 수수료율 × 1.1) − 상품비용 − 배송료 − 패키지비
int _calculateMargin({
  required int sellingPrice,
  required int productCost,
  required int carrierCost,
  required int packageCost,
  required double commissionRate,
}) {
  final commissionFee = sellingPrice * commissionRate * 1.1;
  final totalCost = productCost + carrierCost + packageCost;
  return (sellingPrice - commissionFee - totalCost).round();
}

// 판매가 = 총비용 / (1 − 마진율/100 − 수수료율 × 1.1). 불가능하면 0.
int _calcSellingPriceFromMarginRate({
  required double marginRate,
  required int productCost,
  required int carrierCost,
  required int packageCost,
  required double commissionRate,
}) {
  final totalCost = productCost + carrierCost + packageCost;
  final denominator = 1 - marginRate / 100 - commissionRate * 1.1;
  if (denominator <= 0) return 0;
  return (totalCost / denominator).round();
}

int _roundDownTo10(int value) => (value ~/ 10) * 10;
int _roundUpTo10(int value) => ((value + 9) ~/ 10) * 10;

// 천 단위 콤마 (프론트 toLocaleString과 동일 표기)
String _comma(num value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return negative ? '-$buf' : buf.toString();
}

/// 판매상품 등록/수정 공용 단일 폼 페이지.
///
/// - [editListing] == null → 신규 등록(create). 프론트 ProductListingSinglePageForm.
/// - [editListing] != null → 수정(update). 프론트 ProductListingEditSinglePageForm.
///   기존 데이터로 폼을 프리필하고 제출 시 update를 호출한다.
class ProductListingRegisterPage extends StatefulWidget {
  final ProductListing? editListing;

  const ProductListingRegisterPage({super.key, this.editListing});

  @override
  State<ProductListingRegisterPage> createState() =>
      _ProductListingRegisterPageState();
}

class _ProductListingRegisterPageState extends State<ProductListingRegisterPage> {
  final _nameCtrl = TextEditingController();
  final _platformProductIdCtrl = TextEditingController();

  // 최종 등록 진행 중 여부 (프론트 isSubmitting과 동일한 로컬 상태)
  bool _submitting = false;

  bool get _isEdit => widget.editListing != null;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProductListingCreateBloc>();
    bloc.add(const ResetCreateForm());
    // 수정 모드: 이름/플랫폼 상품 ID 컨트롤러를 즉시 채우고, lookup 로드 시점에
    // 나머지 필드(드롭다운/옵션)도 함께 프리필되도록 editListing 을 전달한다.
    if (_isEdit) {
      _nameCtrl.text = widget.editListing!.name;
      _platformProductIdCtrl.text = widget.editListing!.platformProductId;
      bloc.add(FetchLookupData(editListing: widget.editListing));
    } else {
      bloc.add(const FetchLookupData());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _platformProductIdCtrl.dispose();
    super.dispose();
  }

  bool _isFormComplete(ProductListingCreateLoaded state) {
    return state.formData['sellerId']?.isNotEmpty == true &&
        state.formData['platform']?.isNotEmpty == true &&
        state.formData['name']?.isNotEmpty == true &&
        state.formData['platformProductId']?.isNotEmpty == true &&
        state.selectedProducts.isNotEmpty &&
        state.formData['categoryId']?.isNotEmpty == true &&
        state.formData['carrierId']?.isNotEmpty == true &&
        state.formData['packageId']?.isNotEmpty == true &&
        state.optionsData.isNotEmpty &&
        state.optionsData.every((o) => o.products.isNotEmpty) &&
        state.validationErrors.values.every((e) => e == null);
  }

  List<DropdownMenuItem<String>> _buildSellerItems(List<dynamic> sellers) {
    final seenIds = <String>{};
    return sellers
        .where((seller) {
          final id = seller['id'].toString();
          if (seenIds.contains(id)) return false;
          seenIds.add(id);
          return true;
        })
        .map((seller) {
          final sellerId = seller['id'].toString();
          final sellerName = seller['sellerName'] as String? ?? 'Unknown';
          final businessReg = seller['businessRegistration'] as String? ?? '';

          return DropdownMenuItem<String>(
            value: sellerId,
            child: businessReg.isNotEmpty
                ? Text('$sellerName ($businessReg)')
                : Text(sellerName),
          );
        })
        .toList();
  }

  // 배송사 목록 (중복 제거) - 프론트의 uniqueCarriers와 동일
  List<DropdownMenuItem<String>> _buildCarrierItems(List<dynamic> carrierRates) {
    final seen = <String>{};
    final items = <DropdownMenuItem<String>>[];
    for (final rate in carrierRates) {
      final carrier = rate['carrier']?.toString() ?? '';
      if (carrier.isEmpty || seen.contains(carrier)) continue;
      seen.add(carrier);
      items.add(DropdownMenuItem<String>(
        value: carrier,
        child: Text(carrier),
      ));
    }
    return items;
  }

  // 선택된 배송사의 택배비만 필터링 - 프론트의 filteredCarrierRates와 동일
  List<DropdownMenuItem<String>> _buildFilteredCarrierRateItems(
    List<dynamic> carrierRates,
    String selectedCarrier,
  ) {
    if (selectedCarrier.isEmpty) return [];
    final seenIds = <String>{};
    return carrierRates
        .where((item) => (item['carrier']?.toString() ?? '') == selectedCarrier)
        .where((item) {
          final id = item['id'].toString();
          if (seenIds.contains(id)) return false;
          seenIds.add(id);
          return true;
        })
        .map((item) {
          final carrierRateId = item['id'].toString();
          final cost = (item['cost'] as num?)?.toInt() ?? 0;
          return DropdownMenuItem<String>(
            value: carrierRateId,
            child: Text('$cost원'),
          );
        })
        .toList();
  }

  List<DropdownMenuItem<String>> _buildUniqueCategoryItems(List<dynamic> items) {
    final seenIds = <String>{};
    return items
        .where((item) {
          final id = item['id'].toString();
          if (seenIds.contains(id)) return false;
          seenIds.add(id);
          return true;
        })
        .map((item) {
          final categoryId = item['id'].toString();
          final name = item['name'] ?? 'Unknown';
          return DropdownMenuItem<String>(
            value: categoryId,
            child: Text(name),
          );
        })
        .toList();
  }

  List<DropdownMenuItem<String>> _buildUniquePackageItems(List<dynamic> items) {
    final seenIds = <String>{};
    return items
        .where((item) {
          final id = item['id'].toString();
          if (seenIds.contains(id)) return false;
          seenIds.add(id);
          return true;
        })
        .map((item) {
          final packageId = item['id'].toString();
          final type = item['type'] ?? 'Unknown';
          final cost = (item['cost'] as num?)?.toInt() ?? 0;
          return DropdownMenuItem<String>(
            value: packageId,
            child: Text('$type - $cost원'),
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: _isEdit ? '판매상품 수정' : '판매상품 등록',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.salesProductsPath),
      body: BlocListener<ProductListingCreateBloc, ProductListingCreateState>(
        listener: (context, state) {
          if (state is ProductListingCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEdit ? '판매상품이 수정되었습니다!' : '판매상품이 생성되었습니다!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
              ),
            );
            // 조회 페이지가 변경 내용을 반영하도록 갱신 신호 발행 (등록/수정 공통)
            notifyProductListingChanged();
            Future.delayed(const Duration(milliseconds: 500), () {
              context.go(Routes.salesProductsPath);
            });
          } else if (state is ProductListingCreateError) {
            // 등록/서버 실패를 사용자에게 표시 (프론트의 에러 배너와 동일 역할)
            if (_submitting) setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
              ),
            );
          } else if (state is ProductListingCreateLoaded) {
            // 폼으로 복귀(검증 실패 등) 시 등록 진행 상태 해제
            if (_submitting) setState(() => _submitting = false);
          }
        },
        child: BlocBuilder<ProductListingCreateBloc, ProductListingCreateState>(
          builder: (context, state) {
            if (state is ProductListingCreateLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_submitting
                        ? (_isEdit ? '수정 중...' : '등록 중...')
                        : '데이터를 불러오는 중...'),
                  ],
                ),
              );
            }

            if (state is! ProductListingCreateLoaded) {
              return const Center(child: Text('오류가 발생했습니다'));
            }

            final bloc = context.read<ProductListingCreateBloc>();
            final formData = state.formData;
            final isFormComplete = _isFormComplete(state);

            // Show warning if lookup data is missing
            final hasSellers = state.sellers.isNotEmpty;
            final hasCategories = state.categories.isNotEmpty;
            final hasCarrierRates = state.carrierRates.isNotEmpty;
            final hasPackages = state.packages.isNotEmpty;

            return SingleChildScrollView(
              child: Padding(
                // 하단은 floating bottom nav bar(높이 + safe area)보다 넉넉히 여백을
                // 줘서 마지막 '완료 및 등록' 버튼이 nav bar에 가려지지 않도록 한다.
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  32 +
                      kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasSellers ||
                        !hasCategories ||
                        !hasCarrierRates ||
                        !hasPackages)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ 일부 데이터 로드 실패',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!hasSellers)
                              const Text('• 판매자 목록을 로드하지 못했습니다'),
                            if (!hasCategories)
                              const Text('• 카테고리 목록을 로드하지 못했습니다'),
                            if (!hasCarrierRates)
                              const Text('• 배송사 목록을 로드하지 못했습니다'),
                            if (!hasPackages)
                              const Text('• 패키지 목록을 로드하지 못했습니다'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<ProductListingCreateBloc>()
                                    .add(const FetchLookupData());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('데이터 다시 불러오기'),
                            ),
                          ],
                        ),
                      ),

                    // Section 0: Seller Selection
                    _buildSection(
                      title: '판매자 선택',
                      sectionNumber: '0',
                      isComplete: formData['sellerId']?.isNotEmpty == true,
                      child: state.sellers.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('판매자 데이터를 불러오는 중입니다...'),
                            )
                          : DropdownButtonFormField<String>(
                              value: (formData['sellerId']?.isEmpty ?? true)
                                  ? ''
                                  : formData['sellerId'],
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: '판매자 *',
                                errorText: state.validationErrors['sellerId'],
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('판매자 선택...'),
                                ),
                                ..._buildSellerItems(state.sellers),
                              ],
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  bloc.add(UpdateFormField(
                                    field: 'sellerId',
                                    value: value,
                                  ));
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Platform Selection
                    _buildSection(
                      title: '플랫폼 선택',
                      sectionNumber: '1',
                      isComplete: formData['platform']?.isNotEmpty == true,
                      child: DropdownButtonFormField<String>(
                        value: (formData['platform']?.isEmpty ?? true)
                            ? ''
                            : formData['platform'],
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: '플랫폼 *',
                          errorText: state.validationErrors['platform'],
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('플랫폼 선택...'),
                          ),
                          ...PLATFORMS.map((platform) {
                            return DropdownMenuItem(
                              value: platform,
                              child: Text(platform),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          if (value != null && value.isNotEmpty) {
                            bloc.add(UpdateFormField(
                              field: 'platform',
                              value: value,
                            ));
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1-1: Product Listing Name
                    _buildSection(
                      title: '판매상품 이름',
                      sectionNumber: '1-1',
                      isComplete: formData['name']?.isNotEmpty == true,
                      child: TextField(
                        controller: _nameCtrl,
                        maxLength: 255,
                        decoration: InputDecoration(
                          labelText: '판매상품 이름 *',
                          hintText: '판매상품의 이름을 입력해주세요',
                          errorText: state.validationErrors['name'],
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                        onChanged: (v) {
                          bloc.add(UpdateFormField(
                            field: 'name',
                            value: v,
                          ));
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Product Selection (NEW)
                    _buildSection(
                      title: '구성 상품 선택',
                      sectionNumber: '2',
                      isComplete: state.selectedProducts.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.selectedProducts.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: state.selectedProducts
                                    .map((product) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.productName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (product.price != null)
                                                      Text(
                                                        '₩${product.price}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  bloc.add(RemoveProduct(
                                                    productId: product.id,
                                                  ));
                                                },
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                                child: const Text(
                                                  '제거',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: () {
                              _showProductSearchModal(context, state, bloc);
                            },
                            child: Text(state.selectedProducts.isNotEmpty
                                ? '상품 추가'
                                : '상품 검색 및 선택'),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _platformProductIdCtrl,
                            decoration: InputDecoration(
                              labelText: '플랫폼 상품 ID *',
                              errorText:
                                  state.validationErrors['platformProductId'],
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              bloc.add(UpdateFormField(
                                field: 'platformProductId',
                                value: v,
                              ));
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: (formData['categoryId']?.isEmpty ?? true)
                                ? ''
                                : formData['categoryId'],
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: '카테고리 *',
                              errorText: state.validationErrors['categoryId'],
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('카테고리 선택...'),
                              ),
                              ..._buildUniqueCategoryItems(state.categories
                                  .where((category) =>
                                      category['platform'] ==
                                      formData['platform'])
                                  .toList()),
                            ],
                            onChanged: formData['platform']?.isEmpty ?? true
                                ? null
                                : (value) {
                                    if (value != null && value.isNotEmpty) {
                                      bloc.add(UpdateFormField(
                                        field: 'categoryId',
                                        value: value,
                                      ));
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Carrier & Package Selection (UPDATED)
                    _buildSection(
                      title: '배송사, 택배비 및 패키지',
                      sectionNumber: '3',
                      isComplete: formData['carrierId']?.isNotEmpty == true &&
                          formData['packageId']?.isNotEmpty == true,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: (formData['carrier']?.isEmpty ?? true)
                                ? ''
                                : formData['carrier'],
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: '배송사 *',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('배송사 선택...'),
                              ),
                              ..._buildCarrierItems(state.carrierRates),
                            ],
                            onChanged: (value) {
                              bloc.add(UpdateFormField(
                                field: 'carrier',
                                value: value ?? '',
                              ));
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: (formData['carrierId']?.isEmpty ?? true)
                                ? ''
                                : formData['carrierId'],
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: '택배비 *',
                              errorText: state.validationErrors['carrierId'],
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('택배비 선택...'),
                              ),
                              ..._buildFilteredCarrierRateItems(
                                state.carrierRates,
                                formData['carrier'] ?? '',
                              ),
                            ],
                            onChanged: (formData['carrier']?.isEmpty ?? true)
                                ? null
                                : (value) {
                                    if (value != null && value.isNotEmpty) {
                                      bloc.add(UpdateFormField(
                                        field: 'carrierId',
                                        value: value,
                                      ));
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: (formData['packageId']?.isEmpty ?? true)
                                ? ''
                                : formData['packageId'],
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: '패키지 *',
                              errorText: state.validationErrors['packageId'],
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('패키지 선택...'),
                              ),
                              ..._buildUniquePackageItems(state.packages),
                            ],
                            onChanged: (value) {
                              if (value != null && value.isNotEmpty) {
                                bloc.add(UpdateFormField(
                                  field: 'packageId',
                                  value: value,
                                ));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Options Management & Bundle (NEW)
                    _buildSection(
                      title: '옵션 관리 및 상품 번들 구성',
                      sectionNumber: '4',
                      isComplete: state.optionsData.isNotEmpty &&
                          state.optionsData
                              .every((o) => o.products.isNotEmpty),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.optionsData.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: state.optionsData
                                    .map((optionData) =>
                                        _buildOptionCard(state, bloc, optionData))
                                    .toList(),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: state.selectedProducts.isEmpty ||
                                    (formData['categoryId']?.isEmpty ?? true) ||
                                    (formData['carrierId']?.isEmpty ?? true) ||
                                    (formData['packageId']?.isEmpty ?? true)
                                ? null
                                : () {
                                    _showOptionFormDialog(context, state, bloc);
                                  },
                            child: const Text('+ 옵션 추가'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button (취소는 AppBar 뒤로가기 버튼으로 대체)
                    ElevatedButton(
                      onPressed: (!isFormComplete || _submitting)
                          ? null
                          : () {
                              setState(() => _submitting = true);
                              bloc.add(
                                const SubmitProductListingCreate(),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_submitting
                          ? (_isEdit ? '수정 중...' : '등록 중...')
                          : (_isEdit ? '수정 완료' : '완료 및 등록')),
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

  void _showProductSearchModal(
    BuildContext context,
    ProductListingCreateLoaded state,
    ProductListingCreateBloc bloc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductSearchModal(
        bloc: bloc,
        initialState: state,
      ),
    );
  }

  void _showOptionFormDialog(
    BuildContext context,
    ProductListingCreateLoaded state,
    ProductListingCreateBloc bloc, {
    OptionWithProducts? editing,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _OptionFormDialog(
        bloc: bloc,
        selectedProducts: state.selectedProducts,
        commissionRate: state.commissionRate,
        carrierCost: _findCarrierCost(state),
        packageCost: _findPackageCost(state),
        editing: editing,
      ),
    );
  }

  // 옵션 카드: 옵션명/판매가, 수정·삭제, 구성 상품 목록(상품명+수량), 마진 계산
  // 프론트 ProductListingSinglePageForm Section 4 옵션 카드와 동일한 정보 표시.
  Widget _buildOptionCard(
    ProductListingCreateLoaded state,
    ProductListingCreateBloc bloc,
    OptionWithProducts optionData,
  ) {
    final carrierCost = _findCarrierCost(state);
    final packageCost = _findPackageCost(state);
    final productCost = _optionProductCost(state, optionData.products);
    final margin = _calculateMargin(
      sellingPrice: optionData.option.sellingPrice,
      productCost: productCost,
      carrierCost: carrierCost,
      packageCost: packageCost,
      commissionRate: state.commissionRate,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      optionData.option.optionName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '판매가: ${_comma(optionData.option.sellingPrice)}원',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _showOptionFormDialog(
                      context,
                      state,
                      bloc,
                      editing: optionData,
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('수정', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        bloc.add(RemoveOption(optionId: optionData.option.id)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('삭제', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          if (optionData.products.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: optionData.products.map((pq) {
                  final name = _productName(state, pq.productId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('수량: ${pq.quantity}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildMarginBox(
            sellingPrice: optionData.option.sellingPrice,
            commissionRate: state.commissionRate,
            productCost: productCost,
            margin: margin,
          ),
        ],
      ),
    );
  }

  // 마진 요약 박스 (판매가 / 수수료 / 상품 비용 / 마진)
  Widget _buildMarginBox({
    required int sellingPrice,
    required double commissionRate,
    required int productCost,
    required num margin,
  }) {
    final marginColor = margin > 0 ? Colors.green[700] : Colors.red[700];
    final commissionFee = (sellingPrice * commissionRate * 1.1).round();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _marginRow('판매가:', '₩${_comma(sellingPrice)}'),
          _marginRow('수수료 (+ 10%):', '₩${_comma(commissionFee)}'),
          _marginRow('상품 비용:', '₩${_comma(productCost)}'),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('마진:',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text('₩${_comma(margin)}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: marginColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _marginRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _productName(ProductListingCreateLoaded state, int productId) {
    for (final p in state.selectedProducts) {
      if (p.id == productId) return p.productName;
    }
    return '상품 $productId';
  }

  int _optionProductCost(
    ProductListingCreateLoaded state,
    List<ProductQuantity> products,
  ) {
    int total = 0;
    for (final pq in products) {
      for (final p in state.selectedProducts) {
        if (p.id == pq.productId && p.price != null) {
          total += p.price! * pq.quantity;
          break;
        }
      }
    }
    return total;
  }

  int _findCarrierCost(ProductListingCreateLoaded state) {
    final id = state.formData['carrierId'];
    if (id == null || id.isEmpty) return 0;
    for (final r in state.carrierRates) {
      if (r is Map && r['id'].toString() == id) {
        return (r['cost'] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  int _findPackageCost(ProductListingCreateLoaded state) {
    final id = state.formData['packageId'];
    if (id == null || id.isEmpty) return 0;
    for (final p in state.packages) {
      if (p is Map && p['id'].toString() == id) {
        return (p['cost'] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  Widget _buildSection({
    required String title,
    required String sectionNumber,
    required bool isComplete,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isComplete ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isComplete ? '✓' : sectionNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ProductSearchModal extends StatefulWidget {
  final ProductListingCreateBloc bloc;
  final ProductListingCreateLoaded initialState;

  const _ProductSearchModal({
    required this.bloc,
    required this.initialState,
  });

  @override
  State<_ProductSearchModal> createState() => _ProductSearchModalState();
}

class _ProductSearchModalState extends State<_ProductSearchModal> {
  final TextEditingController _localSearchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _localSearchCtrl.dispose();
    widget.bloc.add(const SearchProducts(query: ''));
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // 디바운스: 입력이 멈춘 뒤에만 검색 (포커스된 TextField가 매 키 입력마다
    // 리빌드/detach 되는 것을 막아 캐럿 스케줄링 assertion 방지)
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.bloc.add(SearchProducts(query: value.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('상품 검색'),
      // 고정 크기 콘텐츠: 검색 결과가 로드돼도 TextField의 위치/레이아웃이
      // 변하지 않도록 하여 EditableText 캐럿 스케줄링(_scheduleShowCaretOnScreen)
      // assertion을 방지한다. SingleChildScrollView로 감싸면 결과 개수에 따라
      // 높이가 바뀌어 포커스된 TextField가 캐럿 콜백을 재예약하면서 detach된다.
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TextField는 BlocBuilder 밖에 두어 검색 결과 emit 시 리빌드되지 않음
            TextField(
              controller: _localSearchCtrl,
              decoration: const InputDecoration(
                hintText: '상품명 검색...',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            // 결과 영역만 리빌드 (다이얼로그 전체 setState 금지)
            Expanded(
              child: BlocBuilder<ProductListingCreateBloc,
                  ProductListingCreateState>(
                bloc: widget.bloc,
                builder: (context, state) {
                  final products = state is ProductListingCreateLoaded
                      ? state.searchedProducts
                      : widget.initialState.searchedProducts;

                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        _localSearchCtrl.text.isEmpty
                            ? '상품을 검색해주세요'
                            : '검색 결과가 없습니다',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        dense: true,
                        title: Text(product.productName),
                        subtitle: Text(
                          product.price != null
                              ? '₩${product.price?.toInt()}'
                              : '가격 미정',
                        ),
                        onTap: () {
                          widget.bloc.add(SelectProduct(product: product));
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

/// 옵션 추가/수정 다이얼로그.
///
/// 프론트 ProductListingSinglePageForm의 Section 4 "옵션 관리 및 상품 번들 구성"과
/// 동일하게 동작한다:
/// - 구성 상품별 수량 입력 (수정 모드는 체크박스로 포함/제외)
/// - 실시간 마진 계산 (판매가 − 수수료(×1.1) − 상품비용 − 배송료 − 패키지비)
/// - 마진율 입력으로 판매가 역산 (10원 올림)
/// - 판매가 포커스 해제 시 10원 단위 내림
///
/// editing == null 이면 추가, 아니면 수정.
class _OptionFormDialog extends StatefulWidget {
  final ProductListingCreateBloc bloc;
  final List<Product> selectedProducts;
  final double commissionRate;
  final int carrierCost;
  final int packageCost;
  final OptionWithProducts? editing;

  const _OptionFormDialog({
    required this.bloc,
    required this.selectedProducts,
    required this.commissionRate,
    required this.carrierCost,
    required this.packageCost,
    this.editing,
  });

  @override
  State<_OptionFormDialog> createState() => _OptionFormDialogState();
}

class _OptionFormDialogState extends State<_OptionFormDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _platformIdCtrl = TextEditingController();
  final TextEditingController _marginRateCtrl = TextEditingController();
  final FocusNode _priceFocus = FocusNode();

  final Map<int, int> _quantities = {};
  final Map<int, bool> _included = {};

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();

    for (final product in widget.selectedProducts) {
      _quantities[product.id] = 1;
      _included[product.id] = true;
    }

    final editing = widget.editing;
    if (editing != null) {
      _nameCtrl.text = editing.option.optionName;
      _priceCtrl.text = editing.option.sellingPrice.toString();
      _platformIdCtrl.text = editing.platformOptionId ?? '';
      // 수정 모드: 옵션에 포함된 상품만 체크 + 기존 수량 반영
      for (final product in widget.selectedProducts) {
        _included[product.id] = false;
      }
      for (final pq in editing.products) {
        _quantities[pq.productId] = pq.quantity;
        _included[pq.productId] = true;
      }
    }

    // 판매가 포커스 해제 시 10원 단위로 내림 (프론트 onBlur와 동일)
    _priceFocus.addListener(() {
      if (!_priceFocus.hasFocus) {
        final v = int.tryParse(_priceCtrl.text);
        if (v != null) {
          _priceCtrl.text = _roundDownTo10(v).toString();
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _platformIdCtrl.dispose();
    _marginRateCtrl.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  int get _sellingPrice => int.tryParse(_priceCtrl.text) ?? 0;

  int get _productCost {
    int total = 0;
    for (final product in widget.selectedProducts) {
      if (_included[product.id] != true) continue;
      if (product.price == null) continue;
      total += product.price! * (_quantities[product.id] ?? 1);
    }
    return total;
  }

  void _applyMarginRate() {
    final rate = double.tryParse(_marginRateCtrl.text);
    if (rate == null || rate < 0 || rate >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마진율은 0 이상 100 미만이어야 합니다')),
      );
      return;
    }
    final price = _calcSellingPriceFromMarginRate(
      marginRate: rate,
      productCost: _productCost,
      carrierCost: widget.carrierCost,
      packageCost: widget.packageCost,
      commissionRate: widget.commissionRate,
    );
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해당 마진율로는 판매가를 계산할 수 없습니다')),
      );
      return;
    }
    setState(() {
      _priceCtrl.text = _roundUpTo10(price).toString();
      _marginRateCtrl.clear();
    });
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('옵션명과 판매가를 입력해주세요')),
      );
      return;
    }

    final quantities = <int, int>{};
    for (final product in widget.selectedProducts) {
      if (_included[product.id] == true) {
        quantities[product.id] = _quantities[product.id] ?? 1;
      }
    }

    if (quantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 상품을 포함해주세요')),
      );
      return;
    }

    final platformOptionId =
        _platformIdCtrl.text.trim().isEmpty ? null : _platformIdCtrl.text.trim();

    if (_isEdit) {
      widget.bloc.add(UpdateOption(
        optionId: widget.editing!.option.id,
        optionName: _nameCtrl.text.trim(),
        sellingPrice: _sellingPrice,
        platformOptionId: platformOptionId,
        productQuantities: quantities,
      ));
    } else {
      widget.bloc.add(AddOption(
        optionName: _nameCtrl.text.trim(),
        sellingPrice: _sellingPrice,
        platformOptionId: platformOptionId,
        productQuantities: quantities,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final margin = _calculateMargin(
      sellingPrice: _sellingPrice,
      productCost: _productCost,
      carrierCost: widget.carrierCost,
      packageCost: widget.packageCost,
      commissionRate: widget.commissionRate,
    );
    final marginRate =
        _sellingPrice > 0 ? (margin / _sellingPrice * 100) : 0.0;
    final commissionFee =
        (_sellingPrice * widget.commissionRate * 1.1).round();
    final marginColor = margin > 0 ? Colors.green[700] : Colors.red[700];

    return AlertDialog(
      title: Text(_isEdit ? '옵션 수정' : '옵션 추가'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '옵션명 *',
                  hintText: 'Blue M',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('물품 수량 *',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (widget.selectedProducts.isEmpty)
                const Text('선택된 상품이 없습니다',
                    style: TextStyle(color: Colors.grey))
              else
                ...widget.selectedProducts.map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (_isEdit)
                          Checkbox(
                            value: _included[product.id] ?? false,
                            onChanged: (checked) {
                              setState(() {
                                _included[product.id] = checked ?? false;
                              });
                            },
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.productName,
                                  overflow: TextOverflow.ellipsis),
                              if (product.price != null)
                                Text('₩${_comma(product.price!)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue:
                                (_quantities[product.id] ?? 1).toString(),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _quantities[product.id] =
                                    int.tryParse(value) ?? 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
              TextField(
                controller: _priceCtrl,
                focusNode: _priceFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '판매가 *',
                  hintText: '29900',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // 마진 계산
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('마진 계산',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    _row('판매가:', '₩${_comma(_sellingPrice)}'),
                    _row('- 수수료 (+ 10%):', '₩${_comma(commissionFee)}'),
                    _row('- 상품 비용:', '₩${_comma(_productCost)}'),
                    _row('- 배송료:', '₩${_comma(widget.carrierCost)}'),
                    _row('- 패키지:', '₩${_comma(widget.packageCost)}'),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('= 마진:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₩${_comma(margin)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: marginColor)),
                      ],
                    ),
                    _row('마진율:',
                        '${(marginRate * 100).round() / 100}%'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 마진율로 판매가 설정
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  border: Border.all(color: Colors.purple.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('마진율로 판매가 설정',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _marginRateCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '목표 마진율 (%)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _applyMarginRate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          child: const Text('적용'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _platformIdCtrl,
                decoration: const InputDecoration(
                  labelText: '플랫폼 옵션 ID',
                  hintText: 'option_abc123',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? '저장' : '옵션 설정 완료'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
