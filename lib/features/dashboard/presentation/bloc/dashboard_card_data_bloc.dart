import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_event.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_state.dart';

/// Data of one dashboard card (FEATURE_2610_29 / D20) — one BLoC per shown
/// card, made with the card's [loader].
///
/// **Usage**:
/// ```dart
/// BlocProvider(
///   key: ValueKey(period),
///   create: (_) => DashboardCardDataBloc<int>(
///     loader: () => getIt<SalesUseCase>().getDailySales(from: f, to: t),
///   )..add(const DashboardCardDataRequested()),
///   child: ...,
/// )
/// ```
///
/// ⚠️ A card whose period changes gets a new BLoC (`key: ValueKey(period)`).
class DashboardCardDataBloc<T>
    extends Bloc<DashboardCardDataEvent, DashboardCardDataState<T>> {
  final Future<Either<Failure, T>> Function() loader;

  DashboardCardDataBloc({required this.loader})
      : super(DashboardCardDataState<T>()) {
    on<DashboardCardDataRequested>(_onRequested);
  }

  Future<void> _onRequested(DashboardCardDataRequested event,
      Emitter<DashboardCardDataState<T>> emit) async {
    emit(DashboardCardDataState<T>());
    final result = await loader();
    emit(result.fold(
      (failure) => DashboardCardDataState<T>(
        loading: false,
        message:
            failure.message.trim().isNotEmpty ? failure.message : '불러오지 못했습니다.',
      ),
      (data) => DashboardCardDataState<T>(loading: false, data: data),
    ));
  }
}
