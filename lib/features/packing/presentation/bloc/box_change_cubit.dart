import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/models/create_package_params.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/create_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/get_packages_usecase.dart';
import '../../domain/usecases/change_parcel_box_usecase.dart';

/// Name of the shared 「재활용 상자(미등록)」 box (FEATURE_2611_06 / D17 · D20).
///
/// Picked when a recycled box of unknown kind was used. The server needs a
/// registered box id, so one recycled box with this name and cost 0 is
/// created once and reused. ❌ The only place in the app that holds this
/// text — finding / creating the box lives in [BoxChangeCubit] only.
const String kUnregisteredRecycledBoxType = '재활용 상자(미등록)';

/// State of the box change sheet (FEATURE_2611_06 / D16 · D20).
class BoxChangeState {
  /// Every box, from the server on each open (R12).
  final List<Package> packages;
  final bool loading;

  /// 「재활용 상자 사용」 checkbox.
  final bool recycled;

  /// The picked registered box — never set together with [unregistered].
  final int? pickedId;

  /// 「재활용 상자(미등록)」 is picked — never set together with [pickedId].
  final bool unregistered;

  /// A request (find / create / change) is running.
  final bool busy;

  /// Error text inside the sheet, blank when none.
  final String error;

  /// The box that was applied — the sheet closes with it.
  final Package? applied;

  const BoxChangeState({
    this.packages = const [],
    this.loading = true,
    this.recycled = false,
    this.pickedId,
    this.unregistered = false,
    this.busy = false,
    this.error = '',
    this.applied,
  });

  /// Boxes drawn as list rows: the shared unregistered box is drawn on its
  /// own at the top, and the checkbox keeps recycled boxes only (web
  /// `BoxChangeModal` `listed`).
  List<Package> get listed => [
        for (final box in packages)
          if (box.type != kUnregisteredRecycledBoxType &&
              (!recycled || box.boxKind == BoxKind.recycled))
            box,
      ];

  BoxChangeState copyWith({
    List<Package>? packages,
    bool? loading,
    bool? recycled,
    int? pickedId,
    bool clearPickedId = false,
    bool? unregistered,
    bool? busy,
    String? error,
    Package? applied,
  }) =>
      BoxChangeState(
        packages: packages ?? this.packages,
        loading: loading ?? this.loading,
        recycled: recycled ?? this.recycled,
        pickedId: clearPickedId ? null : (pickedId ?? this.pickedId),
        unregistered: unregistered ?? this.unregistered,
        busy: busy ?? this.busy,
        error: error ?? this.error,
        applied: applied ?? this.applied,
      );
}

/// Cubit of the box change sheet (FEATURE_2611_06 / D16 · D19 · D20 · D22).
///
/// **Purpose**: the pick, the checkbox, the new box checks and the apply of
/// the sheet opened by `showBoxChangeSheet`.
/// **File**: lib/features/packing/presentation/bloc/box_change_cubit.dart
///
/// - Target parcel `null` = the box being packed: apply only hands the box
///   back (no server call, D22).
/// - Target parcel set = a packed parcel: apply changes its box on the
///   server; a refusal keeps the sheet open with the server text (D19 · D20).
/// ⚠️ Registered by `getIt` as a factory — a new one for every sheet.
class BoxChangeCubit extends Cubit<BoxChangeState> {
  final GetPackagesUseCase getPackagesUseCase;
  final CreatePackageUseCase createPackageUseCase;
  final ChangeParcelBoxUseCase changeParcelBoxUseCase;

  /// The packed parcel whose box changes, null = the box being packed.
  int? _parcelId;

  BoxChangeCubit({
    required this.getPackagesUseCase,
    required this.createPackageUseCase,
    required this.changeParcelBoxUseCase,
  }) : super(const BoxChangeState());

  /// Loads every box and preselects [selectedPackageId] (web first pick).
  Future<void> start({
    required int? parcelId,
    required int? selectedPackageId,
  }) async {
    _parcelId = parcelId;
    final result = await getPackagesUseCase();
    final packages = result.fold((_) => const <Package>[], (list) => list);
    Package? selected;
    for (final box in packages) {
      if (box.id == selectedPackageId) {
        selected = box;
        break;
      }
    }
    if (isClosed) {
      return;
    }
    if (selected == null) {
      emit(state.copyWith(packages: packages, loading: false));
      return;
    }
    final unregistered = selected.type == kUnregisteredRecycledBoxType;
    emit(state.copyWith(
      packages: packages,
      loading: false,
      recycled: selected.boxKind == BoxKind.recycled,
      unregistered: unregistered,
      pickedId: unregistered ? null : selected.id,
      clearPickedId: unregistered,
    ));
  }

  /// 「재활용 상자 사용」 — on picks the unregistered box, off drops it.
  void toggleRecycled({required bool value}) {
    if (state.busy || state.loading) {
      return;
    }
    if (value) {
      emit(state.copyWith(
        recycled: true,
        unregistered: true,
        clearPickedId: true,
      ));
      return;
    }
    emit(state.copyWith(recycled: false, unregistered: false));
  }

  /// A registered box row was tapped.
  void pick(int packageId) {
    if (state.busy || state.loading) {
      return;
    }
    emit(state.copyWith(pickedId: packageId, unregistered: false));
  }

  /// The 「재활용 상자(미등록)」 row was tapped.
  void pickUnregistered() {
    if (state.busy || state.loading) {
      return;
    }
    emit(state.copyWith(unregistered: true, clearPickedId: true));
  }

  /// [이 상자로 변경].
  Future<void> apply() async {
    if (state.busy || state.loading) {
      return;
    }
    if (!state.unregistered && state.pickedId == null) {
      emit(state.copyWith(error: '상자를 고르세요'));
      return;
    }
    emit(state.copyWith(busy: true, error: ''));
    final Package? box;
    if (state.unregistered) {
      box = await _unregisteredBox();
      if (box == null) {
        emit(state.copyWith(busy: false, error: '재활용 상자를 준비하지 못했습니다'));
        return;
      }
    } else {
      box = _boxOf(state.pickedId);
      if (box == null) {
        emit(state.copyWith(busy: false, error: '상자를 고르세요'));
        return;
      }
    }
    await _applyBox(box);
  }

  /// [등록하고 이 상자로 변경] — same checks and texts as the web.
  Future<void> createAndApply({
    required String type,
    required String width,
    required String length,
    required String height,
    required String cost,
  }) async {
    if (state.busy || state.loading) {
      return;
    }
    final recycled = state.recycled;
    final name = type.trim();
    if (name.isEmpty) {
      emit(state.copyWith(error: '상자 이름을 입력하세요'));
      return;
    }
    final sizes = [
      double.tryParse(width.trim()),
      double.tryParse(length.trim()),
      double.tryParse(height.trim()),
    ];
    if (sizes.any((value) => value == null || !value.isFinite || value < 0.1)) {
      emit(state.copyWith(error: '가로 · 세로 · 높이를 0.1cm 이상으로 입력하세요'));
      return;
    }
    final costValue = cost.trim().isEmpty
        ? (recycled ? 0.0 : null)
        : double.tryParse(cost.trim());
    if (costValue == null ||
        !costValue.isFinite ||
        costValue < 0 ||
        (!recycled && costValue == 0)) {
      emit(state.copyWith(
        error: recycled ? '비용을 0원 이상으로 입력하세요' : '구매 상자는 비용을 1원 이상 입력하세요',
      ));
      return;
    }
    emit(state.copyWith(busy: true, error: ''));
    final result = await createPackageUseCase(CreatePackageParams(
      type: name,
      cost: costValue,
      isDefault: false,
      widthCm: sizes[0]!,
      lengthCm: sizes[1]!,
      heightCm: sizes[2]!,
      boxKind: recycled ? BoxKind.recycled : BoxKind.purchased,
    ));
    final created = result.fold((_) => null, (box) => box);
    if (created == null) {
      emit(state.copyWith(busy: false, error: '상자를 등록하지 못했습니다'));
      return;
    }
    emit(state.copyWith(packages: [...state.packages, created]));
    await _applyBox(created);
  }

  /// The shared unregistered recycled box — found in the list, or created
  /// once and added to the end of it. Null when creating fails.
  Future<Package?> _unregisteredBox() async {
    for (final box in state.packages) {
      if (box.type == kUnregisteredRecycledBoxType &&
          box.boxKind == BoxKind.recycled) {
        return box;
      }
    }
    final result = await createPackageUseCase(CreatePackageParams(
      type: kUnregisteredRecycledBoxType,
      cost: 0,
      isDefault: false,
      widthCm: 1,
      lengthCm: 1,
      heightCm: 1,
      boxKind: BoxKind.recycled,
    ));
    final created = result.fold((_) => null, (box) => box);
    if (created != null) {
      emit(state.copyWith(packages: [...state.packages, created]));
    }
    return created;
  }

  /// Hands the box back (box being packed) or changes the parcel's box on
  /// the server; a failure keeps the sheet open with the server text.
  Future<void> _applyBox(Package box) async {
    final parcelId = _parcelId;
    if (parcelId == null) {
      emit(state.copyWith(busy: false, applied: box));
      return;
    }
    final result = await changeParcelBoxUseCase(parcelId, box.id);
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, applied: box)),
    );
  }

  Package? _boxOf(int? id) {
    for (final box in state.packages) {
      if (box.id == id) {
        return box;
      }
    }
    return null;
  }
}
