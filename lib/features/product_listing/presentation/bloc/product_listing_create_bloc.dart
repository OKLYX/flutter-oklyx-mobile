import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_listing_request.dart';
import '../../domain/usecases/product_listing_usecase.dart';
import '../../domain/entities/product_listing.dart';
import 'product_listing_create_event.dart';
import 'product_listing_create_state.dart';

class ProductListingCreateBloc
    extends Bloc<ProductListingCreateEvent, ProductListingCreateState> {
  final ProductListingUseCase productListingUseCase;

  // 수정 대상 판매상품 ID. 이 폼은 수정 전용이므로 제출 전에 반드시 채워져 있어야 한다.
  // (신규 등록 경로는 제거됐다 - 판매상품은 마스터 상품을 통해서만 생긴다.)
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

    // 옵션 + 구성품 복원. 구성품은 마스터 상품이 소유하므로 서버 응답 그대로 읽기
    // 전용으로만 보관한다(편집·전송하지 않는다).
    final optionsData = <OptionWithProducts>[];
    for (final opt in listing.options ?? const <ProductListingOption>[]) {
      final pqs = <ProductQuantity>[];
      for (final p in opt.products ?? const <ProductListingProduct>[]) {
        pqs.add(ProductQuantity(
          productId: p.productId,
          productName: p.productName,
          quantity: p.quantity,
        ));
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
      optionsData: current.optionsData,
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

    // 추가 검증: 옵션 확인. 구성품은 마스터가 소유하므로 이 폼에서 검증하지 않는다.
    if (current.optionsData.isEmpty) {
      emit(ProductListingCreateLoaded(
        formData: current.formData,
        validationErrors: {...errors, 'options': '최소 1개 이상의 옵션을 추가해주세요.'},
        sellers: current.sellers,
        categories: current.categories,
        carrierRates: current.carrierRates,
        packages: current.packages,
        commissionRates: current.commissionRates,
        optionsData: current.optionsData,
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
        optionsData: current.optionsData,
        commissionRate: current.commissionRate,
      ));
      return;
    }

    // 수정 대상이 없으면 저장할 곳이 없다(프리필 실패 등).
    if (editingListingId == null) {
      emit(const ProductListingCreateError('수정할 판매상품을 불러오지 못했습니다.'));
      emit(current);
      return;
    }

    emit(const ProductListingCreateLoading());

    // 옵션 데이터 구성. 구성품(products)은 전송하지 않는다 - 마스터 상품이 소유한다.
    final options = current.optionsData.map((optionData) {
      return CreateProductListingOptionRequest(
        optionName: optionData.option.optionName,
        sellingPrice: optionData.option.sellingPrice,
        platformOptionId: optionData.platformOptionId,
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

    // 수정 전용 폼이므로 항상 update(id) 를 호출한다.
    final result = await productListingUseCase.update(
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
          optionsData: current.optionsData,
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

      // lookup + 기존 데이터 프리필을 한 번에 emit (순서 경합 방지).
      // editListing 없이 호출되면 빈 폼이 되므로 수정 화면은 항상 함께 넘긴다.
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

    // 새 옵션은 마스터에 연결돼 있지 않으므로 구성품을 알 수 없다(빈 목록).
    final newOptionWithProducts = OptionWithProducts(
      option: newOption,
      products: const [],
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
      optionsData: updatedOptions,
      commissionRate: current.commissionRate,
    ));
  }

  void _onUpdateOption(
    UpdateOption event,
    Emitter<ProductListingCreateState> emit,
  ) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;

    // 구성품은 읽기 전용이므로 기존 값을 그대로 보존한다.
    final updatedOptions = current.optionsData.map((optionData) {
      if (optionData.option.id != event.optionId) return optionData;
      return OptionWithProducts(
        option: ProductListingOption(
          id: optionData.option.id,
          optionName: event.optionName,
          sellingPrice: event.sellingPrice,
        ),
        products: optionData.products,
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
      optionsData: updatedOptions,
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
      optionsData: updatedOptions,
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
      optionsData: current.optionsData,
      commissionRate: event.rate,
    ));
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
