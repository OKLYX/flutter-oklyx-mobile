import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/get_packages_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_state.dart';

class PackageListBloc extends Bloc<PackageListEvent, PackageListState> {
  final GetPackagesUseCase getPackagesUseCase;
  List<Package> _allPackages = [];

  PackageListBloc({required this.getPackagesUseCase}) : super(PackageListInitial()) {
    on<FetchPackages>(_onFetchPackages);
    on<SearchPackages>(_onSearchPackages);
  }

  Future<void> _onFetchPackages(FetchPackages event, Emitter<PackageListState> emit) async {
    emit(PackageListLoading());
    final result = await getPackagesUseCase();
    result.fold(
      (failure) => emit(PackageListError(message: failure.message)),
      (packages) {
        _allPackages = packages;
        if (packages.isEmpty) {
          emit(PackageListEmpty());
        } else {
          emit(PackageListLoaded(packages: packages));
        }
      },
    );
  }

  Future<void> _onSearchPackages(SearchPackages event, Emitter<PackageListState> emit) async {
    final query = event.query.toLowerCase();
    final filtered = _allPackages
        .where((pkg) => pkg.type.toLowerCase().contains(query))
        .toList();

    if (filtered.isEmpty && query.isNotEmpty) {
      emit(PackageListEmpty());
    } else if (filtered.isEmpty) {
      emit(PackageListLoaded(packages: _allPackages));
    } else {
      emit(PackageListLoaded(packages: filtered));
    }
  }
}
