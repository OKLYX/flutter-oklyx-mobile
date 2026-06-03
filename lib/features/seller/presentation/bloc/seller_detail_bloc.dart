import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_seller_by_id_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/update_seller_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/delete_seller_usecase.dart';
import 'seller_detail_event.dart';
import 'seller_detail_state.dart';

class SellerDetailBloc extends Bloc<SellerDetailEvent, SellerDetailState> {
  final GetSellerByIdUseCase getSellerByIdUseCase;
  final UpdateSellerUseCase updateSellerUseCase;
  final DeleteSellerUseCase deleteSellerUseCase;

  SellerDetailBloc({
    required this.getSellerByIdUseCase,
    required this.updateSellerUseCase,
    required this.deleteSellerUseCase,
  }) : super(const SellerDetailInitial()) {
    on<LoadSellerDetail>(_onLoadDetail);
    on<StartEditingSeller>(_onStartEditing);
    on<UpdateSellerFormField>(_onUpdateField);
    on<SubmitSellerUpdate>(_onSubmitUpdate);
    on<SubmitSellerUpdateDirect>(_onSubmitUpdateDirect);
    on<ConfirmDeleteSeller>(_onConfirmDelete);
  }

  Future<void> _onLoadDetail(
    LoadSellerDetail event,
    Emitter<SellerDetailState> emit,
  ) async {
    emit(const SellerDetailLoading());
    final result = await getSellerByIdUseCase(event.sellerId);
    result.fold(
      (failure) => emit(SellerDetailError(failure.message)),
      (seller) => emit(SellerDetailLoaded(seller)),
    );
  }

  Future<void> _onStartEditing(
    StartEditingSeller event,
    Emitter<SellerDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is SellerDetailLoaded) {
      emit(SellerDetailEditing(
        originalSeller: currentState.seller,
        editingData: {
          'sellerName': currentState.seller.sellerName,
          'businessRegistration': currentState.seller.businessRegistration,
        },
      ));
    }
  }

  Future<void> _onUpdateField(
    UpdateSellerFormField event,
    Emitter<SellerDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is SellerDetailEditing) {
      final updatedData = {...currentState.editingData};
      updatedData[event.field] = event.value;

      final errors = _validateFields(updatedData);
      emit(SellerDetailEditing(
        originalSeller: currentState.originalSeller,
        editingData: updatedData,
        validationErrors: errors,
      ));
    }
  }

  Future<void> _onSubmitUpdate(
    SubmitSellerUpdate event,
    Emitter<SellerDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is SellerDetailEditing) {
      final errors = _validateFields(currentState.editingData);
      if (errors.isNotEmpty) {
        emit(SellerDetailEditing(
          originalSeller: currentState.originalSeller,
          editingData: currentState.editingData,
          validationErrors: errors,
        ));
        return;
      }

      emit(const SellerDetailSubmitting());
      final result = await updateSellerUseCase(
        currentState.originalSeller.id,
        currentState.editingData['sellerName'] as String,
        currentState.editingData['businessRegistration'] as String,
      );

      result.fold(
        (failure) {
          emit(SellerDetailError(failure.message));
        },
        (seller) {
          emit(SellerDetailUpdateSuccess(seller));
        },
      );
    }
  }

  Future<void> _onSubmitUpdateDirect(
    SubmitSellerUpdateDirect event,
    Emitter<SellerDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is SellerDetailEditing || currentState is SellerDetailLoaded) {
      final sellerId = currentState is SellerDetailEditing
          ? currentState.originalSeller.id
          : (currentState as SellerDetailLoaded).seller.id;

      emit(const SellerDetailSubmitting());
      final result = await updateSellerUseCase(
        sellerId,
        event.sellerName,
        event.businessRegistration,
      );

      result.fold(
        (failure) {
          emit(SellerDetailError(failure.message));
        },
        (seller) {
          emit(SellerDetailUpdateSuccess(seller));
        },
      );
    }
  }

  Future<void> _onConfirmDelete(
    ConfirmDeleteSeller event,
    Emitter<SellerDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is SellerDetailLoaded) {
      emit(const SellerDetailSubmitting());
      final result = await deleteSellerUseCase(currentState.seller.id);

      result.fold(
        (failure) {
          emit(SellerDetailError(failure.message));
        },
        (_) {
          emit(const SellerDetailDeleteSuccess());
        },
      );
    }
  }

  Map<String, String?> _validateFields(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    final sellerName = data['sellerName'] as String?;
    if (sellerName == null || sellerName.isEmpty) {
      errors['sellerName'] = '판매자명을 입력해주세요.';
    } else if (sellerName.length > 255) {
      errors['sellerName'] = '최대 255자입니다.';
    } else {
      errors['sellerName'] = null;
    }

    final businessReg = data['businessRegistration'] as String?;
    if (businessReg == null || businessReg.isEmpty) {
      errors['businessRegistration'] = '사업자등록번호를 입력해주세요.';
    } else if (businessReg.length != 10) {
      errors['businessRegistration'] = '10자리 숫자를 입력해주세요.';
    } else if (!_isValidBusinessRegistration(businessReg)) {
      errors['businessRegistration'] = '숫자만 입력 가능합니다.';
    } else {
      errors['businessRegistration'] = null;
    }

    return errors;
  }

  bool _isValidBusinessRegistration(String value) {
    final regex = RegExp(r'^\d{10}$');
    return regex.hasMatch(value);
  }
}
