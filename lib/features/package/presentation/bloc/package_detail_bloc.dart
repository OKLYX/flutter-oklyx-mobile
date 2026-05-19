import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/get_packages_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/update_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/delete_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_state.dart';

class PackageDetailBloc extends Bloc<PackageDetailEvent, PackageDetailState> {
  final GetPackagesUseCase getPackagesUseCase;
  final UpdatePackageUseCase updatePackageUseCase;
  final DeletePackageUseCase deletePackageUseCase;
  List<Package> _allPackages = [];

  PackageDetailBloc({
    required this.getPackagesUseCase,
    required this.updatePackageUseCase,
    required this.deletePackageUseCase,
  }) : super(PackageDetailInitial()) {
    on<LoadPackageDetail>(_onLoadPackageDetail);
    on<StartEditingPackage>(_onStartEditingPackage);
    on<UpdateFormField>(_onUpdateFormField);
    on<SubmitPackageUpdate>(_onSubmitPackageUpdate);
    on<StartDeletingPackage>(_onStartDeleting);
    on<ConfirmDeletePackage>(_onConfirmDelete);
    on<CancelDeletePackage>(_onCancelDelete);
  }

  Future<void> _onLoadPackageDetail(LoadPackageDetail event, Emitter<PackageDetailState> emit) async {
    emit(PackageDetailLoading());
    final result = await getPackagesUseCase();
    result.fold(
      (failure) => emit(PackageDetailError(failure.message)),
      (packages) {
        _allPackages = packages;
        final pkg = packages.firstWhere(
          (p) => p.id == event.packageId,
          orElse: () => throw Exception('Package not found'),
        );
        emit(PackageDetailLoaded(pkg));
      },
    );
  }

  Future<void> _onStartEditingPackage(StartEditingPackage event, Emitter<PackageDetailState> emit) async {
    if (state is PackageDetailLoaded) {
      final pkg = (state as PackageDetailLoaded).package;
      emit(PackageDetailEditing(
        originalPackage: pkg,
        editingData: {
          'type': pkg.type,
          'cost': pkg.cost,
          'effectiveDate': pkg.effectiveDate,
          'isDefault': pkg.isDefault,
        },
      ));
    }
  }

  Future<void> _onUpdateFormField(UpdateFormField event, Emitter<PackageDetailState> emit) async {
    if (state is PackageDetailEditing) {
      final current = state as PackageDetailEditing;
      final errors = _validateField(event.field, event.value);
      final newErrors = {...current.validationErrors};
      if (errors.isEmpty) {
        newErrors.remove(event.field);
      } else {
        newErrors[event.field] = errors;
      }
      emit(PackageDetailEditing(
        originalPackage: current.originalPackage,
        editingData: {...current.editingData, event.field: event.value},
        validationErrors: newErrors,
      ));
    }
  }

  Future<void> _onSubmitPackageUpdate(SubmitPackageUpdate event, Emitter<PackageDetailState> emit) async {
    if (state is PackageDetailEditing) {
      final current = state as PackageDetailEditing;
      if (!_isFormValid(current.editingData)) {
        emit(PackageDetailEditing(
          originalPackage: current.originalPackage,
          editingData: current.editingData,
          validationErrors: _validateAll(current.editingData),
        ));
        return;
      }
      emit(PackageDetailSubmitting());
      final result = await updatePackageUseCase(
        id: current.originalPackage.id,
        type: current.editingData['type'],
        cost: current.editingData['cost'],
        effectiveDate: current.editingData['effectiveDate'],
        isDefault: current.editingData['isDefault'],
      );
      result.fold(
        (failure) => emit(PackageDetailError(failure.message)),
        (updatedPackage) {
          emit(PackageDetailUpdateSuccess());
          emit(PackageDetailLoaded(updatedPackage));
        },
      );
    }
  }

  String _validateField(String field, dynamic value) {
    if (field == 'type') {
      if ((value as String).isEmpty) return '상자 유형은 필수입니다';
      if (value.length > 100) return '100자 이하로 입력하세요';
    } else if (field == 'cost') {
      final cost = double.tryParse(value.toString()) ?? -1;
      if (cost < 0) return '양수를 입력하세요';
    } else if (field == 'effectiveDate') {
      if ((value as String).isEmpty) return '유효일은 필수입니다';
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return 'YYYY-MM-DD 형식으로 입력하세요';
    }
    return '';
  }

  Map<String, String> _validateAll(Map<String, dynamic> data) {
    final errors = <String, String>{};
    for (final field in ['type', 'cost', 'effectiveDate']) {
      final error = _validateField(field, data[field]);
      if (error.isNotEmpty) {
        errors[field] = error;
      }
    }
    return errors;
  }

  bool _isFormValid(Map<String, dynamic> data) => _validateAll(data).isEmpty;

  Future<void> _onStartDeleting(
    StartDeletingPackage event,
    Emitter<PackageDetailState> emit,
  ) async {
    if (state is PackageDetailLoaded) {
      final package = (state as PackageDetailLoaded).package;
      emit(PackageDetailConfirmingDelete(package: package));
    } else if (state is PackageDetailEditing) {
      final package = (state as PackageDetailEditing).originalPackage;
      emit(PackageDetailConfirmingDelete(package: package));
    }
  }

  Future<void> _onConfirmDelete(
    ConfirmDeletePackage event,
    Emitter<PackageDetailState> emit,
  ) async {
    int? packageId;

    final currentState = state;
    if (currentState is PackageDetailLoaded) {
      packageId = currentState.package.id;
    } else if (currentState is PackageDetailEditing) {
      packageId = currentState.originalPackage.id;
    } else if (currentState is PackageDetailConfirmingDelete) {
      packageId = currentState.package.id;
    }

    if (packageId == null) return;

    emit(PackageDetailDeleting());
    final result = await deletePackageUseCase(packageId);

    result.fold(
      (failure) => emit(PackageDetailError(failure.message)),
      (_) => emit(PackageDetailDeleteSuccess()),
    );
  }

  Future<void> _onCancelDelete(
    CancelDeletePackage event,
    Emitter<PackageDetailState> emit,
  ) async {
    if (state is PackageDetailConfirmingDelete) {
      final package = (state as PackageDetailConfirmingDelete).package;
      emit(PackageDetailLoaded(package));
    }
  }
}
