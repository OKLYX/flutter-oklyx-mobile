import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_stock_linked_usecase.dart';
import 'purchase_setting_event.dart';
import 'purchase_setting_state.dart';

/// The one source of the stock link setting on mobile (FEATURE_2610_09 D65 ·
/// D71 · D72).
///
/// **Purpose**: while the stock link is on, the drawer shows 「재고 조회」, the
/// 「입고·조정」 page shows the 「입고 대기」 purchase picker and the intake card
/// shows its stock notice (「입고하면 재고에 바로 더해집니다」); while it is off,
/// the 「입고·조정」 page gives the 「매입」 reason a 「단가 (선택)」 field instead.
/// **File**: lib/features/purchase_list/presentation/bloc/purchase_setting_bloc.dart
///
/// **Usage**:
/// ```dart
/// context.read<PurchaseSettingBloc>().add(LoadPurchaseSetting());
/// BlocBuilder<PurchaseSettingBloc, PurchaseSettingState>(
///   builder: (context, s) => s.stockLinked == true ? on : off,
/// )
/// ```
///
/// 🔴 App-wide singleton provided in `main.dart`, like `AlertSummaryBloc` —
///    the drawer is rebuilt on every opening and must not start from null again.
/// ⚠️ A failed load keeps the previous value and shows no error.
/// ❌ Mobile has no screen that changes the setting — web 「구매관리 설정」 only (D72).
class PurchaseSettingBloc
    extends Bloc<PurchaseSettingEvent, PurchaseSettingState> {
  final GetStockLinkedUseCase getStockLinkedUseCase;

  PurchaseSettingBloc({required this.getStockLinkedUseCase})
      : super(const PurchaseSettingState()) {
    on<LoadPurchaseSetting>(_onLoad);
  }

  Future<void> _onLoad(
    LoadPurchaseSetting event,
    Emitter<PurchaseSettingState> emit,
  ) async {
    final result = await getStockLinkedUseCase();
    if (emit.isDone) return;
    result.fold(
      (_) {},
      (stockLinked) => emit(PurchaseSettingState(stockLinked: stockLinked)),
    );
  }
}
