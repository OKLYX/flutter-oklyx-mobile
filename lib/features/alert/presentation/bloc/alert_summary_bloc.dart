import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/alert_usecase.dart';
import 'alert_summary_event.dart';
import 'alert_summary_state.dart';

/// 알림 배지 카운트 (FEATURE_2609_49 / D9).
///
/// **용도**: Drawer 메뉴의 처리 대기 건수. "처리할 일이 몇 건인가"를 보여주는 모든 자리의
/// 단일 원천이다.
/// **필수 규칙**: 화면이 자기 목록 길이를 세지 말고 이 Bloc 을 쓴다 — 목록에는 필터가 걸려 있다.
/// **파일**: lib/features/alert/presentation/bloc/alert_summary_bloc.dart
///
/// 🔴 **배지 숫자는 목록 화면의 행 수와 일치하지 않는다 — 정상이다.** 배지는 미완결/미답변
/// **전부**(타입 무관·기간 무관, 실질 상한은 서버의 STALE 30일)이고, 반품/교환·고객문의 화면은
/// 기본이 `반품` + 최근 2주다. 일치시키려고 배지를 좁히지 말 것 — 오래된 미처리 건이야말로
/// 배지가 존재하는 이유다.
///
/// **사용 예제**:
/// BlocBuilder<AlertSummaryBloc, AlertSummaryState>(
///   builder: (context, state) => AlertBadge(count: state.openClaims),
/// )
///
/// 🔴 **앱 전체 1개**(`registerSingleton`)다. Drawer 는 열릴 때마다 새로 빌드되므로 factory 로
/// 두면 매번 0 에서 다시 시작해 숫자가 깜빡인다.
/// 🔴 **타이머를 두지 않는다.** 갱신 시점은 Drawer 가 열릴 때다(`AppDrawer.initState`) — 배지는
/// Drawer 안에만 있고, 닫혀 있는 동안 폴링하면 배터리만 쓴다.
/// ⚠️ 실패는 **직전 값을 유지**하고 에러를 화면에 띄우지 않는다. 배지는 보조 정보이고, Drawer 에
/// 에러를 그리면 모든 화면이 오염된다.
class AlertSummaryBloc extends Bloc<AlertSummaryEvent, AlertSummaryState> {
  final AlertUseCase alertUseCase;

  AlertSummaryBloc({required this.alertUseCase})
      : super(const AlertSummaryState()) {
    on<LoadAlertSummary>(_onLoad);
  }

  Future<void> _onLoad(
    LoadAlertSummary event,
    Emitter<AlertSummaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await alertUseCase.getSummary();
    if (emit.isDone) return;
    // 실패는 숫자를 건드리지 않는다 — 직전 값을 그대로 둔다(위 주석).
    emit(result.fold(
      (_) => state.copyWith(isLoading: false),
      (summary) => state.copyWith(
        openClaims: summary.openClaims,
        unansweredInquiries: summary.unansweredInquiries,
        isLoading: false,
      ),
    ));
  }
}
