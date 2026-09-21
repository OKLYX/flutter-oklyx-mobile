import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/models/create_package_params.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/create_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_state.dart';

class PackageCreateBloc extends Bloc<PackageCreateEvent, PackageCreateState> {
  final CreatePackageUseCase createPackageUseCase;

  String _type = '';
  String _cost = '';
  bool _isDefault = false;
  String _width = '';
  String _length = '';
  String _height = '';

  PackageCreateBloc({
    required this.createPackageUseCase,
  }) : super(PackageCreateInitial()) {
    on<PackageTypeChanged>(_onPackageTypeChanged);
    on<PackageCostChanged>(_onPackageCostChanged);
    on<PackageWidthChanged>(_onPackageWidthChanged);
    on<PackageLengthChanged>(_onPackageLengthChanged);
    on<PackageHeightChanged>(_onPackageHeightChanged);
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

  Future<void> _onPackageWidthChanged(
    PackageWidthChanged event,
    Emitter<PackageCreateState> emit,
  ) async {
    _width = event.width;
    emit(_buildLoadedState());
  }

  Future<void> _onPackageLengthChanged(
    PackageLengthChanged event,
    Emitter<PackageCreateState> emit,
  ) async {
    _length = event.length;
    emit(_buildLoadedState());
  }

  Future<void> _onPackageHeightChanged(
    PackageHeightChanged event,
    Emitter<PackageCreateState> emit,
  ) async {
    _height = event.height;
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
      isDefault: _isDefault,
      widthCm: double.parse(_width),
      lengthCm: double.parse(_length),
      heightCm: double.parse(_height),
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
    _isDefault = false;
    _width = '';
    _length = '';
    _height = '';
    emit(PackageCreateInitial());
  }

  PackageCreateLoaded _buildLoadedState() {
    return PackageCreateLoaded(
      type: _type,
      cost: _cost,
      isDefault: _isDefault,
      width: _width,
      length: _length,
      height: _height,
      isFormValid: _validateForm(),
    );
  }

  bool _validateForm() {
    if (_type.isEmpty || _cost.isEmpty) {
      return false;
    }

    final costValue = double.tryParse(_cost);
    if (costValue == null || costValue <= 0) {
      return false;
    }

    if (!_isValidSize(_width) ||
        !_isValidSize(_length) ||
        !_isValidSize(_height)) {
      return false;
    }

    return true;
  }

  /// 사이즈 입력 검증 — 0.1 ~ 999.9 · 소수점 첫째 자리까지
  /// (서버 `@DecimalMin`/`@DecimalMax`/`@Digits` 와 동일 조건, PLAN 2609_38 D5).
  bool _isValidSize(String raw) {
    final v = double.tryParse(raw);
    if (v == null || v < 0.1 || v > 999.9) {
      return false;
    }
    return double.parse(v.toStringAsFixed(1)) == v;
  }
}
