import 'package:flutter_bloc/flutter_bloc.dart';

/// 「출고 전 주문 제외」 switch value (FEATURE_2611_04 / D3 · D9) — shared by the
/// three 「매출」 screens (summary · by channel · by product).
///
/// - Provided by the `ShellRoute` around the three sales routes in
///   `app_router.dart`, so moving between the three keeps the value.
/// - Leaving the three routes drops this Cubit — coming back starts off (D9).
/// - Memory only — never stored on the device, in the route or on the server.
///
/// File: lib/features/sales/presentation/bloc/sales_shipped_only_cubit.dart
class SalesShippedOnlyCubit extends Cubit<bool> {
  SalesShippedOnlyCubit() : super(false);

  void set({required bool value}) => emit(value);
}
