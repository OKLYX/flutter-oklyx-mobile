import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_listing_request.dart';
import '../../domain/usecases/product_listing_usecase.dart';
import '../../domain/entities/product_listing.dart';
import '../../../product/domain/entities/product.dart';
import 'product_listing_create_event.dart';
import 'product_listing_create_state.dart';

class ProductListingCreateBloc
    extends Bloc<ProductListingCreateEvent, ProductListingCreateState> {
  final ProductListingUseCase productListingUseCase;

  // 수정 모드일 때 대상 판매상품 ID. null 이면 신규 등록(create), 값이 있으면 수정(update).
  // 이 BLoC은 factory로 등록되어 화면마다 새 인스턴스이므로 인스턴스 필드로 안전하게 보관한다.
  int? editingListingId;

  static const _initialData = {
    'sellerId': '',
    'platform': '',
    'name': '',
    'platformProductId': '',
    'categoryId': '',
    'carrier': '',
    'carrierId': '',
    'packageId': '',
  };

  ProductListingCreateBloc({required this.productListingUseCase})
      : super(const ProductListingCreateLoaded(formData: _initialData)) {
    on<ResetCreateForm>(_onResetForm);
    on<UpdateFormField>(_onUpdateField);
    on<SubmitProductListingCreate>(_onSubmit);
    on<FetchLookupData>(_onFetchLookupData);
    on<SearchProducts>(_onSearchProducts);
    on<SelectProduct>(_onSelectProduct);
    on<RemoveProduct>(_onRemoveProduct);
    on<AddOption>(_onAddOption);
    on<UpdateOption>(_onUpdateOption);
    on<RemoveOption>(_onRemoveOption);
    on<UpdateCommissionRate>(_onUpdateCommissionRate);
  }

  void _onResetForm(ResetCreateForm event, Emitter<ProductListingCreateState> emit) {
    editingListingId = null;
    if (state is! ProductListingCreateLoaded) {
      emit(const ProductListingCreateLoaded(formData: _initialData));
      return;
    }
    final current = state as ProductListingCreateLoaded;
    emit(ProductListingCreateLoaded(
      formData: _initialData,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
    ));
  }

  // 수정 모드 프리필: 로드된 lookup 데이터 + 기존 listing 으로 채워진 Loaded 를 만든다.
  // 프론트 ProductListingEditSinglePageForm의 fetchData 초기화 로직과 동일.
  // [editingListingId] 도 함께 설정해 이후 제출이 update 로 분기되게 한다.
  ProductListingCreateLoaded _buildEditLoaded(
    ProductListing listing, {
    required List<dynamic> sellers,
    required List<dynamic> categories,
    required List<dynamic> carrierRates,
    required List<dynamic> packages,
    required List<dynamic> commissionRates,
  }) {
    editingListingId = listing.id;

    // 택배비 ID(deliveryId)로 배송사명을 역추적 (프론트의 selectedCarrierRateId→carrier useEffect와 동일)
    String carrier = '';
    final deliveryId = listing.deliveryId;
    if (deliveryId != null) {
      final match = carrierRates.firstWhere(
        (r) => r is Map && r['id'].toString() == deliveryId.toString(),
        orElse: () => null,
      );
      if (match != null && match is Map) {
        carrier = match['carrier']?.toString() ?? '';
      }
    }

    final formData = {
      'sellerId': listing.sellerId?.toString() ?? '',
      'platform': listing.platform,
      'name': listing.name,
      'platformProductId': listing.platformProductId,
      'categoryId': listing.categoryId?.toString() ?? '',
      'carrier': carrier,
      'carrierId': deliveryId?.toString() ?? '',
      'packageId': listing.packageId?.toString() ?? '',
    };

    // 옵션 + 구성상품 복원. 구성상품은 가격 정보가 없으므로(상세 응답 미포함)
    // price=null 로 selectedProducts에 채워 옵션 편집 다이얼로그가 동작하도록 한다.
    final selectedProductsMap = <int, Product>{};
    final optionsData = <OptionWithProducts>[];
    for (final opt in listing.options ?? const <ProductListingOption>[]) {
      final pqs = <ProductQuantity>[];
      for (final p in opt.products ?? const <ProductListingProduct>[]) {
        pqs.add(ProductQuantity(productId: p.productId, quantity: p.quantity));
        selectedProductsMap.putIfAbsent(
          p.productId,
          () => Product(
            id: p.productId,
            productName: p.productName,
            active: true,
            createdDate: '',
            modifiedDate: '',
          ),
        );
      }
      optionsData.add(OptionWithProducts(
        option: ProductListingOption(
          id: opt.id,
          optionName: opt.optionName,
          sellingPrice: opt.sellingPrice,
        ),
        products: pqs,
        platformOptionId: opt.platformOptionId,
      ));
    }

    final commissionRate = _computeCommissionRate(
      commissionRates,
      formData['platform'] ?? '',
      formData['categoryId'] ?? '',
    );

    return ProductListingCreateLoaded(
      formData: formData,
      sellers: sellers,
      categories: categories,
      carrierRates: carrierRates,
      packages: packages,
      commissionRates: commissionRates,
      selectedProducts: selectedProductsMap.values.toList(),
      optionsData: optionsData,
      commissionRate: commissionRate,
    );
  }

  void _onUpdateField(UpdateFormField event, Emitter<ProductListingCreateState> emit) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;
    final updated = {...current.formData, event.field: event.value};

    // 기존 에러를 유지하면서 변경된 필드만 재검증한다.
    // 전체 폼을 검증하면 아직 건드리지 않은 필드에도 에러가 표시되므로,
    // 입력을 막 시작한 사용자에게 잘못된 알림이 뜨는 것을 방지한다.
    final errors = {...current.validationErrors};

    // 플랫폼 변경 시 카테고리 초기화 (재선택 전까지 에러도 제거)
    if (event.field == 'platform') {
      updated['categoryId'] = '';
      errors.remove('categoryId');
    }

    // 배송사 변경 시 택배비 초기화 (프론트와 동일하게 배송사 선택 후 택배비 선택)
    if (event.field == 'carrier') {
      updated['carrierId'] = '';
      errors.remove('carrierId');
    }

    // 사용자가 건드린(변경한) 필드만 검증하여 에러를 갱신한다.
    final fieldError = _validateField(event.field, updated);
    if (fieldError != null) {
      errors[event.field] = fieldError;
    } else {
      errors.remove(event.field);
    }

    // 플랫폼/카테고리 변경 시 수수료율을 재계산한다 (프론트의 useEffect와 동일).
    // 카테고리 전용 수수료율이 있으면 우선 적용하고, 없으면 플랫폼 기본값을 사용한다.
    double commissionRate = current.commissionRate;
    if (event.field == 'platform' || event.field == 'categoryId') {
      commissionRate = _computeCommissionRate(
        current.commissionRates,
        updated['platform'] ?? '',
        updated['categoryId'] ?? '',
      );
    }

    emit(ProductListingCreateLoaded(
      formData: updated,
      validationErrors: errors,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
      selectedProducts: current.selectedProducts,
      optionsData: current.optionsData,
      searchedProducts: current.searchedProducts,
      commissionRate: commissionRate,
    ));
  }

  Future<void> _onSubmit(
    SubmitProductListingCreate event,
    Emitter<ProductListingCreateState> emit,
  ) async {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;
    final errors = _validateForm(current.formData);

    // 추가 검증: 상품 선택, 옵션 추가 확인
    if (current.selectedProducts.isEmpty) {
      emit(ProductListingCreateLoaded(
        formData: current.formData,
        validationErrors: {...errors, 'products': '최소 1개 이상의 상품을 선택해주세요.'},
        sellers: current.sellers,
        categories: current.categories,
        carrierRates: current.carrierRates,
        packages: current.packages,
        commissionRates: current.commissionRates,
        selectedProducts: current.selectedProducts,
        optionsData: current.optionsData,
        searchedProducts: current.searchedProducts,
        commissionRate: current.commissionRate,
      ));
      return;
    }

    if (current.optionsData.isEmpty) {
      emit(ProductListingCreateLoaded(
        formData: current.formData,
        validationErrors: {...errors, 'options': '최소 1개 이상의 옵션을 추가해주세요.'},
        sellers: current.sellers,
        categories: current.categories,
        carrierRates: current.carrierRates,
        packages: current.packages,
        commissionRates: current.commissionRates,
        selectedProducts: current.selectedProducts,
        optionsData: current.optionsData,
        searchedProducts: current.searchedProducts,
        commissionRate: current.commissionRate,
      ));
      return;
    }

    if (errors.isNotEmpty) {
      emit(ProductListingCreateLoaded(
        formData: current.formData,
        validationErrors: errors,
        sellers: current.sellers,
        categories: current.categories,
        carrierRates: current.carrierRates,
        packages: current.packages,
        commissionRates: current.commissionRates,
        selectedProducts: current.selectedProducts,
        optionsData: current.optionsData,
        searchedProducts: current.searchedProducts,
        commissionRate: current.commissionRate,
      ));
      return;
    }

    emit(const ProductListingCreateLoading());

    // 옵션 데이터 구성
    final options = current.optionsData.map((optionData) {
      final products = optionData.products
          .map((pq) => CreateProductListingProductRequest(
                productId: pq.productId,
                quantity: pq.quantity,
              ))
          .toList();

      return CreateProductListingOptionRequest(
        optionName: optionData.option.optionName,
        sellingPrice: optionData.option.sellingPrice,
        platformOptionId: optionData.platformOptionId,
        products: products,
      );
    }).toList();

    final categoryId = current.formData['categoryId']?.isEmpty ?? true
        ? null
        : current.formData['categoryId'];
    final carrierId = current.formData['carrierId']?.isEmpty ?? true
        ? null
        : current.formData['carrierId'];
    final packageId = current.formData['packageId']?.isEmpty ?? true
        ? null
        : current.formData['packageId'];
    final sellerId = current.formData['sellerId']?.isEmpty ?? true
        ? null
        : current.formData['sellerId'];

    // 수정 모드면 update(id), 아니면 create. (프론트의 handleFinalSubmit과 동일 분기)
    final result = editingListingId != null
        ? await productListingUseCase.update(
            editingListingId!,
            UpdateProductListingRequest(
              platform: current.formData['platform']!,
              platformProductId: current.formData['platformProductId']!,
              name: current.formData['name']!,
              categoryId: categoryId,
              carrierId: carrierId,
              packageId: packageId,
              sellerId: sellerId,
              options: options,
            ),
          )
        : await productListingUseCase.create(
            CreateProductListingRequest(
              platform: current.formData['platform']!,
              platformProductId: current.formData['platformProductId']!,
              name: current.formData['name']!,
              categoryId: categoryId,
              carrierId: carrierId,
              packageId: packageId,
              sellerId: sellerId,
              options: options,
            ),
          );

    result.fold(
      (failure) {
        emit(ProductListingCreateError(failure.message));
        emit(ProductListingCreateLoaded(
          formData: current.formData,
          validationErrors: const {},
          sellers: current.sellers,
          categories: current.categories,
          carrierRates: current.carrierRates,
          packages: current.packages,
          commissionRates: current.commissionRates,
          selectedProducts: current.selectedProducts,
          optionsData: current.optionsData,
          searchedProducts: current.searchedProducts,
          commissionRate: current.commissionRate,
        ));
      },
      (productListing) => emit(ProductListingCreateSuccess(productListing)),
    );
  }

  Future<void> _onFetchLookupData(
    FetchLookupData event,
    Emitter<ProductListingCreateState> emit,
  ) async {
    emit(const ProductListingCreateLoading());

    List<dynamic> sellers = [];
    List<dynamic> categories = [];
    List<dynamic> carrierRates = [];
    List<dynamic> packages = [];
    List<dynamic> commissionRates = [];
    List<String> errors = [];

    try {
      // 모든 데이터를 병렬로 로드 (하나 실패해도 나머지는 계속)
      final results = await Future.wait([
        productListingUseCase.getSellers(),
        productListingUseCase.getCategories(),
        productListingUseCase.getCarrierRates(),
        productListingUseCase.getPackages(),
        productListingUseCase.getCommissionRates(),
      ], eagerError: false);

      if (results.isNotEmpty) {
        results[0].fold(
          (failure) => errors.add('판매자: ${failure.message}'),
          (data) => sellers = data,
        );
      }

      if (results.length > 1) {
        results[1].fold(
          (failure) => errors.add('카테고리: ${failure.message}'),
          (data) => categories = data,
        );
      }

      if (results.length > 2) {
        results[2].fold(
          (failure) => errors.add('배송사: ${failure.message}'),
          (data) => carrierRates = data,
        );
      }

      if (results.length > 3) {
        results[3].fold(
          (failure) => errors.add('패키지: ${failure.message}'),
          (data) => packages = data,
        );
      }

      if (results.length > 4) {
        results[4].fold(
          (failure) => errors.add('수수료율: ${failure.message}'),
          (data) => commissionRates = data,
        );
      }

      // 수수료율 계산 (플랫폼 기본값)
      double commissionRate = 0.05;
      if (commissionRates is List && (commissionRates as List).isNotEmpty) {
        final defaultRate = (commissionRates as List)
            .firstWhere(
              (r) => r is Map && r['categoryId'] == null,
              orElse: () => null,
            );
        if (defaultRate != null && defaultRate is Map) {
          commissionRate = (defaultRate['rate'] as num?)?.toDouble() ?? 0.05;
        }
      }

      // 수정 모드면 lookup + 기존 데이터 프리필을 한 번에 emit (순서 경합 방지),
      // 신규 등록이면 빈 폼으로 emit.
      final state = event.editListing != null
          ? _buildEditLoaded(
              event.editListing!,
              sellers: sellers,
              categories: categories,
              carrierRates: carrierRates,
              packages: packages,
              commissionRates: commissionRates,
            )
          : ProductListingCreateLoaded(
              formData: _initialData,
              sellers: sellers,
              categories: categories,
              carrierRates: carrierRates,
              packages: packages,
              commissionRates: commissionRates,
              commissionRate: commissionRate,
            );

      if (errors.isNotEmpty) {
        emit(ProductListingCreateError(
          '일부 데이터 로드 실패:\n${errors.join("\n")}',
        ));
      }

      emit(state);
    } catch (e) {
      // 예외가 발생해도 빈 폼이라도 보여줌
      emit(ProductListingCreateLoaded(
        formData: _initialData,
        sellers: sellers,
        categories: categories,
        carrierRates: carrierRates,
        packages: packages,
        commissionRates: commissionRates,
      ));

      emit(ProductListingCreateError('데이터 로드 오류: ${e.toString()}'));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductListingCreateState> emit,
  ) async {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    if (event.query.isEmpty) {
      emit(ProductListingCreateLoaded(
        formData: current.formData,
        validationErrors: current.validationErrors,
        sellers: current.sellers,
        categories: current.categories,
        carrierRates: current.carrierRates,
        packages: current.packages,
        commissionRates: current.commissionRates,
        selectedProducts: current.selectedProducts,
        optionsData: current.optionsData,
        searchedProducts: const [],
        commissionRate: current.commissionRate,
      ));
      return;
    }

    final result = await productListingUseCase.searchProducts(
      query: event.query,
      page: 0,
      size: 50,
    );

    result.fold(
      (failure) {
        emit(ProductListingCreateLoaded(
          formData: current.formData,
          validationErrors: current.validationErrors,
          sellers: current.sellers,
          categories: current.categories,
          carrierRates: current.carrierRates,
          packages: current.packages,
          commissionRates: current.commissionRates,
          selectedProducts: current.selectedProducts,
          optionsData: current.optionsData,
          searchedProducts: const [],
          commissionRate: current.commissionRate,
        ));
      },
      (data) {
        final products = <dynamic>[];
        if (data is Map && data['content'] is List) {
          products.addAll(data['content'] as List);
        } else if (data is List) {
          products.addAll(data);
        }

        final convertedProducts = products
            .map((p) {
              if (p is Map<String, dynamic>) {
                return _mapToProduct(p);
              }
              return null;
            })
            .whereType<Product>()
            .toList();

        emit(ProductListingCreateLoaded(
          formData: current.formData,
          validationErrors: current.validationErrors,
          sellers: current.sellers,
          categories: current.categories,
          carrierRates: current.carrierRates,
          packages: current.packages,
          commissionRates: current.commissionRates,
          selectedProducts: current.selectedProducts,
          optionsData: current.optionsData,
          searchedProducts: convertedProducts,
          commissionRate: current.commissionRate,
        ));
      },
    );
  }

  void _onSelectProduct(
    SelectProduct event,
    Emitter<ProductListingCreateState> emit,
  ) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    // 이미 선택된 상품이면 무시
    if (current.selectedProducts.any((p) => p.id == event.product.id)) {
      return;
    }

    final updatedProducts = [...current.selectedProducts, event.product];

    emit(ProductListingCreateLoaded(
      formData: current.formData,
      validationErrors: current.validationErrors,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
      selectedProducts: updatedProducts,
      optionsData: current.optionsData,
      searchedProducts: current.searchedProducts,
      commissionRate: current.commissionRate,
    ));
  }

  void _onRemoveProduct(
    RemoveProduct event,
    Emitter<ProductListingCreateState> emit,
  ) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    final updatedProducts = current.selectedProducts
        .where((p) => p.id != event.productId)
        .toList();

    emit(ProductListingCreateLoaded(
      formData: current.formData,
      validationErrors: current.validationErrors,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
      selectedProducts: updatedProducts,
      optionsData: current.optionsData,
      searchedProducts: current.searchedProducts,
      commissionRate: current.commissionRate,
    ));
  }

  void _onAddOption(
    AddOption event,
    Emitter<ProductListingCreateState> emit,
  ) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    final newOption = ProductListingOption(
      id: DateTime.now().millisecondsSinceEpoch,
      optionName: event.optionName,
      sellingPrice: event.sellingPrice,
    );

    final productQuantities = <ProductQuantity>[];
    event.productQuantities.forEach((productId, quantity) {
      productQuantities.add(ProductQuantity(
        productId: productId,
        quantity: quantity,
      ));
    });

    final newOptionWithProducts = OptionWithProducts(
      option: newOption,
      products: productQuantities,
      platformOptionId: event.platformOptionId,
    );

    final updatedOptions = [...current.optionsData, newOptionWithProducts];

    emit(ProductListingCreateLoaded(
      formData: current.formData,
      validationErrors: current.validationErrors,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
      selectedProducts: current.selectedProducts,
      optionsData: updatedOptions,
      searchedProducts: current.searchedProducts,
      commissionRate: current.commissionRate,
    ));
  }

  void _onUpdateOption(
    UpdateOption event,
    Emitter<ProductListingCreateState> emit,
  ) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    final productQuantities = <ProductQuantity>[];
    event.productQuantities.forEach((productId, quantity) {
      productQuantities.add(ProductQuantity(
        productId: productId,
        quantity: quantity,
      ));
    });

    final updatedOptions = current.optionsData.map((optionData) {
      if (optionData.option.id != event.optionId) return optionData;
      return OptionWithProducts(
        option: ProductListingOption(
          id: optionData.option.id,
          optionName: event.optionName,
          sellingPrice: event.sellingPrice,
        ),
        products: productQuantities,
        platformOptionId: event.platformOptionId,
      );
    }).toList();

    emit(ProductListingCreateLoaded(
      formData: current.formData,
      validationErrors: current.validationErrors,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
      selectedProducts: current.selectedProducts,
      optionsData: updatedOptions,
      searchedProducts: current.searchedProducts,
      commissionRate: current.commissionRate,
    ));
  }

  void _onRemoveOption(
    RemoveOption event,
    Emitter<ProductListingCreateState> emit,
  ) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    final updatedOptions = current.optionsData
        .where((o) => o.option.id != event.optionId)
        .toList();

    emit(ProductListingCreateLoaded(
      formData: current.formData,
      validationErrors: current.validationErrors,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
      selectedProducts: current.selectedProducts,
      optionsData: updatedOptions,
      searchedProducts: current.searchedProducts,
      commissionRate: current.commissionRate,
    ));
  }

  void _onUpdateCommissionRate(
    UpdateCommissionRate event,
    Emitter<ProductListingCreateState> emit,
  ) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    emit(ProductListingCreateLoaded(
      formData: current.formData,
      validationErrors: current.validationErrors,
      sellers: current.sellers,
      categories: current.categories,
      carrierRates: current.carrierRates,
      packages: current.packages,
      commissionRates: current.commissionRates,
      selectedProducts: current.selectedProducts,
      optionsData: current.optionsData,
      searchedProducts: current.searchedProducts,
      commissionRate: event.rate,
    ));
  }

  Product _mapToProduct(Map<String, dynamic> json) {
    // price는 double 또는 int로 올 수 있으므로 유연하게 처리
    int? price;
    final priceValue = json['price'];
    if (priceValue != null) {
      if (priceValue is int) {
        price = priceValue;
      } else if (priceValue is double) {
        price = priceValue.toInt();
      } else if (priceValue is String) {
        price = int.tryParse(priceValue);
      }
    }

    return Product(
      id: json['id'] as int,
      productName: json['productName'] as String,
      barcodeId: json['barcodeId'] as String?,
      brand: json['brand'] as String?,
      price: price,
      store: json['store'] as String?,
      unit: json['unit'] as String?,
      volumeHeight: json['volumeHeight'] as String?,
      volumeLong: json['volumeLong'] as String?,
      volumeShort: json['volumeShort'] as String?,
      weight: json['weight'] as String?,
      description: json['description'] as String?,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      active: json['active'] as bool? ?? true,
      createdDate: json['createdDate'] as String? ?? '',
      modifiedDate: json['modifiedDate'] as String? ?? '',
    );
  }

  // 플랫폼/카테고리에 해당하는 수수료율 계산 (프론트의 useEffect 로직과 동일).
  // 1) platform + categoryId 일치 항목, 2) platform의 기본값(categoryId == null),
  // 3) 둘 다 없으면 0.05.
  double _computeCommissionRate(
    List<dynamic> rates,
    String platform,
    String categoryId,
  ) {
    if (platform.isEmpty) return 0.05;

    if (categoryId.isNotEmpty) {
      final catId = int.tryParse(categoryId);
      final match = rates.firstWhere(
        (r) =>
            r is Map && r['platform'] == platform && r['categoryId'] == catId,
        orElse: () => null,
      );
      if (match != null && match is Map) {
        return (match['rate'] as num?)?.toDouble() ?? 0.05;
      }
    }

    final defaultRate = rates.firstWhere(
      (r) => r is Map && r['platform'] == platform && r['categoryId'] == null,
      orElse: () => null,
    );
    if (defaultRate != null && defaultRate is Map) {
      return (defaultRate['rate'] as num?)?.toDouble() ?? 0.05;
    }

    return 0.05;
  }

  // 단일 필드 검증 (입력 진행 중에는 건드린 필드만 검증할 때 사용)
  String? _validateField(String field, Map<String, String> data) {
    final value = data[field] ?? '';
    switch (field) {
      case 'sellerId':
        return value.isEmpty ? '판매자를 선택해주세요.' : null;
      case 'platform':
        return value.isEmpty ? '플랫폼을 선택해주세요.' : null;
      case 'name':
        if (value.isEmpty) return '판매상품 이름을 입력해주세요.';
        if (value.length > 255) return '최대 255자까지 입력 가능합니다.';
        return null;
      case 'platformProductId':
        return value.isEmpty ? '플랫폼 상품 ID를 입력해주세요.' : null;
      case 'categoryId':
        return value.isEmpty ? '카테고리를 선택해주세요.' : null;
      case 'carrierId':
        return value.isEmpty ? '배송사를 선택해주세요.' : null;
      case 'packageId':
        return value.isEmpty ? '패키지를 선택해주세요.' : null;
      default:
        return null;
    }
  }

  // 전체 폼 검증 (제출 시 모든 필드 에러를 한 번에 표시)
  Map<String, String?> _validateForm(Map<String, String> data) {
    final errors = <String, String?>{};
    for (final field in const [
      'sellerId',
      'platform',
      'name',
      'platformProductId',
      'categoryId',
      'carrierId',
      'packageId',
    ]) {
      final error = _validateField(field, data);
      if (error != null) {
        errors[field] = error;
      }
    }
    return errors;
  }
}
