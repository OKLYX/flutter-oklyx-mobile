import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_listing_request.dart';
import '../../domain/usecases/product_listing_usecase.dart';
import 'product_listing_create_event.dart';
import 'product_listing_create_state.dart';

class ProductListingCreateBloc
    extends Bloc<ProductListingCreateEvent, ProductListingCreateState> {
  final ProductListingUseCase productListingUseCase;
  static const _initialData = {
    'platform': '',
    'platformProductId': '',
    'name': '',
    'categoryId': '',
    'carrierId': '',
    'packageId': '',
    'sellerId': '',
  };

  ProductListingCreateBloc({required this.productListingUseCase})
      : super(const ProductListingCreateLoaded(formData: _initialData)) {
    on<ResetCreateForm>(
      (_, emit) => emit(const ProductListingCreateLoaded(formData: _initialData)),
    );
    on<UpdateFormField>(_onUpdateField);
    on<SubmitProductListingCreate>(_onSubmit);
  }

  void _onUpdateField(UpdateFormField event, Emitter<ProductListingCreateState> emit) {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;
    final updated = {...current.formData, event.field: event.value};
    emit(ProductListingCreateLoaded(
      formData: updated,
      validationErrors: _validateForm(updated),
    ));
  }

  Future<void> _onSubmit(
    SubmitProductListingCreate event,
    Emitter<ProductListingCreateState> emit,
  ) async {
    if (state is! ProductListingCreateLoaded) return;
    final current = state as ProductListingCreateLoaded;
    final errors = _validateForm(current.formData);

    if (errors.isNotEmpty) {
      emit(ProductListingCreateLoaded(
        formData: current.formData,
        validationErrors: errors,
      ));
      return;
    }

    emit(const ProductListingCreateLoading());
    final request = CreateProductListingRequest(
      platform: current.formData['platform']!,
      platformProductId: current.formData['platformProductId']!,
      name: current.formData['name']!,
      categoryId: current.formData['categoryId']?.isEmpty ?? true
          ? null
          : current.formData['categoryId'],
      carrierId: current.formData['carrierId']?.isEmpty ?? true
          ? null
          : current.formData['carrierId'],
      packageId: current.formData['packageId']?.isEmpty ?? true
          ? null
          : current.formData['packageId'],
      sellerId: current.formData['sellerId']?.isEmpty ?? true
          ? null
          : current.formData['sellerId'],
    );

    final result = await productListingUseCase.create(request);

    result.fold(
      (failure) {
        emit(ProductListingCreateError(failure.message));
        emit(ProductListingCreateLoaded(
          formData: current.formData,
          validationErrors: const {},
        ));
      },
      (productListing) => emit(ProductListingCreateSuccess(productListing)),
    );
  }

  Map<String, String?> _validateForm(Map<String, String> data) {
    final errors = <String, String?>{};
    final platform = data['platform'] ?? '';
    final productId = data['platformProductId'] ?? '';
    final name = data['name'] ?? '';

    if (platform.isEmpty) {
      errors['platform'] = '플랫폼을 입력해주세요.';
    }

    if (productId.isEmpty) {
      errors['platformProductId'] = '플랫폼 상품 ID를 입력해주세요.';
    }

    if (name.isEmpty) {
      errors['name'] = '상품명을 입력해주세요.';
    } else if (name.length > 255) {
      errors['name'] = '최대 255자까지 입력 가능합니다.';
    }

    return errors;
  }
}
