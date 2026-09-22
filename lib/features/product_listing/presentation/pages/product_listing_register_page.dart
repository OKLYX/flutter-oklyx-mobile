import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_event.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_state.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/domain/entities/product_listing.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/product_listing_refresh.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

const List<String> PLATFORMS = ['COUPANG', 'GMARKET', 'AUCTION', 'SMARTSTORE'];

// ── 마진 계산 헬퍼 ──
// margin = 판매가 − (판매가 × 수수료율 × 1.1) − 배송료 − 패키지비
// ⚠️ 구성품 비용은 빠져 있다. 구성품은 마스터 상품이 소유하고 이 폼은 물품 가격을
// 받아오지 않으므로, 여기서 계산할 수 있는 것은 물류·수수료까지다.
int _calculateMargin({
  required int sellingPrice,
  required int carrierCost,
  required int packageCost,
  required double commissionRate,
}) {
  final commissionFee = sellingPrice * commissionRate * 1.1;
  final totalCost = carrierCost + packageCost;
  return (sellingPrice - commissionFee - totalCost).round();
}

// 판매가 = 총비용 / (1 − 마진율/100 − 수수료율 × 1.1). 불가능하면 0.
int _calcSellingPriceFromMarginRate({
  required double marginRate,
  required int carrierCost,
  required int packageCost,
  required double commissionRate,
}) {
  final totalCost = carrierCost + packageCost;
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

/// 판매상품 **수정 전용** 단일 폼 페이지.
///
/// 신규 등록 경로는 제거됐다 - 판매상품(채널 셀)은 마스터 상품을 통해서만 생긴다.
/// [editListing] 은 필수이며, 그 데이터로 폼을 프리필하고 제출 시 update를 호출한다.
///
/// ⚠️ 옵션의 구성품은 **읽기 전용**이다. 구성품은 마스터 상품(마스터 옵션 → 물품 → 수량)이
/// 소유하므로 이 폼에서 고르거나 전송하지 않는다.
/// ⚠️ 마스터에 연결된 판매상품은 서버가 수정을 거부한다(400). 이 폼은 마스터 미연결 셀 전용이다.
class ProductListingRegisterPage extends StatefulWidget {
  final ProductListing editListing;

  const ProductListingRegisterPage({super.key, required this.editListing});

  @override
  State<ProductListingRegisterPage> createState() =>
      _ProductListingRegisterPageState();
}

class _ProductListingRegisterPageState extends State<ProductListingRegisterPage> {
  final _nameCtrl = TextEditingController();
  final _platformProductIdCtrl = TextEditingController();

  // 수정 진행 중 여부 (프론트 isSubmitting과 동일한 로컬 상태)
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProductListingCreateBloc>();
    bloc.add(const ResetCreateForm());
    // 이름/플랫폼 상품 ID 컨트롤러를 즉시 채우고, lookup 로드 시점에
    // 나머지 필드(드롭다운/옵션)도 함께 프리필되도록 editListing 을 전달한다.
    _nameCtrl.text = widget.editListing.name;
    _platformProductIdCtrl.text = widget.editListing.platformProductId;
    bloc.add(FetchLookupData(editListing: widget.editListing));
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
        state.formData['categoryId']?.isNotEmpty == true &&
        state.formData['carrierId']?.isNotEmpty == true &&
        state.formData['packageId']?.isNotEmpty == true &&
        state.optionsData.isNotEmpty &&
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
      title: '판매상품 수정',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocListener<ProductListingCreateBloc, ProductListingCreateState>(
        listener: (context, state) {
          if (state is ProductListingCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('판매상품이 수정되었습니다!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
              ),
            );
            // 조회 페이지가 변경 내용을 반영하도록 갱신 신호 발행
            notifyProductListingChanged();
            Future.delayed(const Duration(milliseconds: 500), () {
              context.go(Routes.salesProductsPath);
            });
          } else if (state is ProductListingCreateError) {
            // 수정/서버 실패를 사용자에게 표시 (프론트의 에러 배너와 동일 역할).
            // 마스터에 연결된 셀이면 서버가 400 으로 거부하며 그 메시지가 여기에 뜬다.
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
            // 폼으로 복귀(검증 실패 등) 시 수정 진행 상태 해제
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
                    Text(_submitting ? '수정 중...' : '데이터를 불러오는 중...'),
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
                // 줘서 마지막 '수정 완료' 버튼이 nav bar에 가려지지 않도록 한다.
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
                          color: AppColors.warningSurface,
                          border: Border.all(
                            color: AppColors.warningForeground,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ 일부 데이터 로드 실패',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warningForeground,
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
                                // 재로드 때도 editListing 을 넘겨야 프리필이 유지된다.
                                context
                                    .read<ProductListingCreateBloc>()
                                    .add(FetchLookupData(
                                      editListing: widget.editListing,
                                    ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warningForeground,
                                foregroundColor: AppColors.warningSurface,
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

                    // Section 2: Platform Product ID & Category
                    _buildSection(
                      title: '플랫폼 상품 ID 및 카테고리',
                      sectionNumber: '2',
                      isComplete:
                          formData['platformProductId']?.isNotEmpty == true &&
                              formData['categoryId']?.isNotEmpty == true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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

                    // Section 4: Options (구성품은 읽기 전용)
                    _buildSection(
                      title: '옵션 관리',
                      sectionNumber: '4',
                      isComplete: state.optionsData.isNotEmpty,
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
                            onPressed: (formData['categoryId']?.isEmpty ??
                                        true) ||
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

                    // Submit Button
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
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_submitting ? '수정 중...' : '수정 완료'),
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
        commissionRate: state.commissionRate,
        carrierCost: _findCarrierCost(state),
        packageCost: _findPackageCost(state),
        editing: editing,
      ),
    );
  }

  // 옵션 카드: 옵션명/판매가, 수정·삭제, 구성품 목록(읽기 전용), 마진 계산
  Widget _buildOptionCard(
    ProductListingCreateLoaded state,
    ProductListingCreateBloc bloc,
    OptionWithProducts optionData,
  ) {
    final carrierCost = _findCarrierCost(state);
    final packageCost = _findPackageCost(state);
    final margin = _calculateMargin(
      sellingPrice: optionData.option.sellingPrice,
      carrierCost: carrierCost,
      packageCost: packageCost,
      commissionRate: state.commissionRate,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                      backgroundColor: AppColors.infoSurface,
                      foregroundColor: AppColors.infoForeground,
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
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.error,
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
          const SizedBox(height: 8),
          _buildOptionProducts(optionData.products),
          const SizedBox(height: 8),
          _buildMarginBox(
            sellingPrice: optionData.option.sellingPrice,
            commissionRate: state.commissionRate,
            margin: margin,
          ),
        ],
      ),
    );
  }

  // 마진 요약 박스 (판매가 / 수수료 / 마진).
  // 구성품 비용은 마스터가 소유하므로 여기서는 계산하지 않는다.
  Widget _buildMarginBox({
    required int sellingPrice,
    required double commissionRate,
    required num margin,
  }) {
    final marginColor = margin > 0
        ? AppColors.successForeground
        : Theme.of(context).colorScheme.error;
    final commissionFee = (sellingPrice * commissionRate * 1.1).round();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _marginRow('판매가:', '₩${_comma(sellingPrice)}'),
          _marginRow('수수료 (+ 10%):', '₩${_comma(commissionFee)}'),
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
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              )),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOptionProducts(List<ProductQuantity> products) =>
      _OptionProductsView(products: products);

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
                color: isComplete
                    ? AppColors.brandGreen
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isComplete ? '✓' : sectionNumber,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
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

/// 옵션 추가/수정 다이얼로그.
///
/// - 옵션명 / 판매가 / 플랫폼 옵션 ID 입력
/// - 실시간 마진 계산 (판매가 − 수수료(×1.1) − 배송료 − 패키지비)
/// - 마진율 입력으로 판매가 역산 (10원 올림)
/// - 판매가 포커스 해제 시 10원 단위 내림
///
/// ⚠️ 구성품은 **고를 수 없다**(읽기 전용 표시만). 구성품은 마스터 상품이 소유한다.
///
/// editing == null 이면 추가, 아니면 수정.
class _OptionFormDialog extends StatefulWidget {
  final ProductListingCreateBloc bloc;
  final double commissionRate;
  final int carrierCost;
  final int packageCost;
  final OptionWithProducts? editing;

  const _OptionFormDialog({
    required this.bloc,
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

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();

    final editing = widget.editing;
    if (editing != null) {
      _nameCtrl.text = editing.option.optionName;
      _priceCtrl.text = editing.option.sellingPrice.toString();
      _platformIdCtrl.text = editing.platformOptionId ?? '';
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

    final platformOptionId =
        _platformIdCtrl.text.trim().isEmpty ? null : _platformIdCtrl.text.trim();

    if (_isEdit) {
      widget.bloc.add(UpdateOption(
        optionId: widget.editing!.option.id,
        optionName: _nameCtrl.text.trim(),
        sellingPrice: _sellingPrice,
        platformOptionId: platformOptionId,
      ));
    } else {
      widget.bloc.add(AddOption(
        optionName: _nameCtrl.text.trim(),
        sellingPrice: _sellingPrice,
        platformOptionId: platformOptionId,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final margin = _calculateMargin(
      sellingPrice: _sellingPrice,
      carrierCost: widget.carrierCost,
      packageCost: widget.packageCost,
      commissionRate: widget.commissionRate,
    );
    final marginRate =
        _sellingPrice > 0 ? (margin / _sellingPrice * 100) : 0.0;
    final commissionFee =
        (_sellingPrice * widget.commissionRate * 1.1).round();
    final marginColor = margin > 0
        ? AppColors.successForeground
        : Theme.of(context).colorScheme.error;

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
              const Text('구성품 (읽기 전용)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _OptionProductsView(
                products: widget.editing?.products ?? const [],
              ),
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
                  color: AppColors.infoSurface,
                  border: Border.all(color: AppColors.infoBorder),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
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
                            backgroundColor: AppColors.brandTeal,
                            foregroundColor:
                                Theme.of(context).colorScheme.onTertiary,
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

/// 옵션의 구성품 표시 (읽기 전용).
///
/// 구성품은 마스터 상품(마스터 옵션 → 물품 → 수량)이 소유한다. 이 폼에서는 고를 수 없고
/// 서버가 내려준 값을 그대로 보여주기만 한다.
///
/// ⚠️ 비어 있으면 「구성품 0개」가 아니라 **마스터에 연결되지 않아 알 수 없는 상태**다.
/// 빈 목록으로 두면 0개처럼 보이므로 안내 문구를 띄운다.
class _OptionProductsView extends StatelessWidget {
  final List<ProductQuantity> products;

  const _OptionProductsView({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          border: Border.all(color: AppColors.warningForeground),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '연결된 마스터가 없어 구성품을 알 수 없습니다',
          style: TextStyle(fontSize: 12, color: AppColors.warningForeground),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: products
            .map(
              (pq) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${pq.productName} × ${pq.quantity}개',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
