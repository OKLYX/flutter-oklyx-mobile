import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_seller_usecase.dart';
import 'seller_create_event.dart';
import 'seller_create_state.dart';

class SellerCreateBloc extends Bloc<SellerCreateEvent, SellerCreateState> {
  final CreateSellerUseCase createSellerUseCase;
  static const _initialData = {'sellerName': '', 'businessRegistration': ''};

  SellerCreateBloc({required this.createSellerUseCase})
      : super(const SellerCreateLoaded(formData: _initialData)) {
    on<ResetCreateForm>(
      (_, emit) => emit(const SellerCreateLoaded(formData: _initialData)),
    );
    on<UpdateFormField>(_onUpdateField);
    on<SubmitSellerCreate>(_onSubmit);
  }

  void _onUpdateField(UpdateFormField event, Emitter<SellerCreateState> emit) {
    if (state is! SellerCreateLoaded) return;
    final current = state as SellerCreateLoaded;
    final updated = {...current.formData, event.field: event.value};
    emit(SellerCreateLoaded(
      formData: updated,
      validationErrors: _validateForm(updated),
    ));
  }

  Future<void> _onSubmit(SubmitSellerCreate event, Emitter<SellerCreateState> emit) async {
    if (state is! SellerCreateLoaded) return;
    final current = state as SellerCreateLoaded;
    final errors = _validateForm(current.formData);

    if (errors.isNotEmpty) {
      emit(SellerCreateLoaded(formData: current.formData, validationErrors: errors));
      return;
    }

    emit(const SellerCreateLoading());
    final result = await createSellerUseCase(CreateSellerParams(
      sellerName: current.formData['sellerName']!,
      businessRegistration: current.formData['businessRegistration']!,
    ));

    result.fold(
      (failure) {
        emit(SellerCreateError(failure.message));
        // 에러 후 폼 복원
        emit(SellerCreateLoaded(formData: current.formData, validationErrors: const {}));
      },
      (seller) => emit(SellerCreateSuccess(seller)),
    );
  }

  Map<String, String?> _validateForm(Map<String, String> data) {
    final errors = <String, String?>{};
    final name = data['sellerName'] ?? '';
    final reg = data['businessRegistration'] ?? '';

    if (name.isEmpty) {
      errors['sellerName'] = '판매자명을 입력해주세요.';
    } else if (name.length > 255) {
      errors['sellerName'] = '최대 255자까지 입력 가능합니다.';
    }

    if (reg.isEmpty) {
      errors['businessRegistration'] = '사업자등록번호를 입력해주세요.';
    } else if (!RegExp(r'^\d{10}$').hasMatch(reg)) {
      errors['businessRegistration'] = '형식이 맞지 않습니다. (예: 1234567890)';
    }

    return errors;
  }
}
