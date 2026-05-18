import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/models/create_package_params.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/create_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_state.dart';

class PackageCreateBloc extends Bloc<PackageCreateEvent, PackageCreateState> {
  final CreatePackageUseCase createPackageUseCase;

  String _type = '';
  String _cost = '';
  String _effectiveDate = '';
  bool _isDefault = false;

  PackageCreateBloc({
    required this.createPackageUseCase,
  }) : super(PackageCreateInitial()) {
    on<PackageTypeChanged>(_onPackageTypeChanged);
    on<PackageCostChanged>(_onPackageCostChanged);
    on<PackageEffectiveDateChanged>(_onPackageEffectiveDateChanged);
    on<PackageIsDefaultChanged>(_onPackageIsDefaultChanged);
    on<CreatePackageRequested>(_onCreatePackageRequested);
    on<ResetCreateForm>(_onResetCreateForm);
  }

  Future<void> _onPackageTypeChanged(
    PackageTypeChanged event,
    Emitter<PackageCreateState> emit,
  ) async {
    _type = event.type;
    emit(_buildLoadedState());
  }

  Future<void> _onPackageCostChanged(
    PackageCostChanged event,
    Emitter<PackageCreateState> emit,
  ) async {
    _cost = event.cost;
    emit(_buildLoadedState());
  }

  Future<void> _onPackageEffectiveDateChanged(
    PackageEffectiveDateChanged event,
    Emitter<PackageCreateState> emit,
  ) async {
    _effectiveDate = event.effectiveDate;
    emit(_buildLoadedState());
  }

  Future<void> _onPackageIsDefaultChanged(
    PackageIsDefaultChanged event,
    Emitter<PackageCreateState> emit,
  ) async {
    _isDefault = event.isDefault;
    emit(_buildLoadedState());
  }

  Future<void> _onCreatePackageRequested(
    CreatePackageRequested event,
    Emitter<PackageCreateState> emit,
  ) async {
    emit(PackageCreateLoading());

    final params = CreatePackageParams(
      type: _type,
      cost: double.parse(_cost),
      effectiveDate: _effectiveDate,
      isDefault: _isDefault,
    );

    final result = await createPackageUseCase(params);

    result.fold(
      (failure) => emit(PackageCreateError(failure.message)),
      (createdPackage) {
        emit(PackageCreateSuccess(createdPackage));
      },
    );
  }

  Future<void> _onResetCreateForm(
    ResetCreateForm event,
    Emitter<PackageCreateState> emit,
  ) async {
    _type = '';
    _cost = '';
    _effectiveDate = '';
    _isDefault = false;
    emit(PackageCreateInitial());
  }

  PackageCreateLoaded _buildLoadedState() {
    return PackageCreateLoaded(
      type: _type,
      cost: _cost,
      effectiveDate: _effectiveDate,
      isDefault: _isDefault,
      isFormValid: _validateForm(),
    );
  }

  bool _validateForm() {
    if (_type.isEmpty || _cost.isEmpty || _effectiveDate.isEmpty) {
      return false;
    }

    final costValue = double.tryParse(_cost);
    if (costValue == null || costValue <= 0) {
      return false;
    }

    if (!_effectiveDate.contains(RegExp(r'^\d{4}-\d{2}-\d{2}$'))) {
      return false;
    }

    return true;
  }
}
