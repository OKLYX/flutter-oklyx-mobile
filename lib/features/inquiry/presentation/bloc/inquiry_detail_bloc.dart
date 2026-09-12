import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_type_option.dart';
import '../../domain/usecases/inquiry_usecase.dart';
import 'inquiry_detail_event.dart';
import 'inquiry_detail_state.dart';

/// 고객문의 상세 BLoC (FEATURE_2609_36 / 02).
///
/// 🔴 상세는 **반드시** 단건 API 를 부른다(PLAN M1) — 스레드·관련 주문·관련 상품·답변 가능
/// 여부는 `GET /api/inquiries/{id}` 에서만 채워지고 목록 응답에서는 항상 null 이다.
/// 클레임 상세처럼 `extra` 만으로 그리면 스레드가 영원히 비어 있다.
///
/// ⚠️ 유형 라벨도 서버에서 받는다(M2) — 앱에 `PRODUCT_QNA: '상품문의'` 표를 두지 않으려면
/// 상세도 `/types` 를 알아야 한다. **한 인스턴스에서 한 번만** 불러 보관한다.
class InquiryDetailBloc extends Bloc<InquiryDetailEvent, InquiryDetailState> {
  final InquiryUseCase inquiryUseCase;

  /// 마지막으로 조회한 문의 id. [ReloadInquiry] 가 인자를 갖지 않는 근거다.
  int? _id;

  /// 유형 라벨 표(서버 원천). 실패하면 비어 있고, 그때 화면은 유형 칩을 그리지 않는다.
  List<InquiryTypeOption>? _typeOptions;

  InquiryDetailBloc({required this.inquiryUseCase})
      : super(InquiryDetailInitial()) {
    on<LoadInquiry>(_onLoad);
    on<ReloadInquiry>(_onReload);
    on<SubmitReply>(_onSubmitReply);
    on<ReplyErrorCleared>(_onReplyErrorCleared);
  }

  Future<void> _onLoad(
    LoadInquiry event,
    Emitter<InquiryDetailState> emit,
  ) async {
    _id = event.id;
    await _fetch(event.id, emit);
  }

  /// id 를 모르면(진입 전 새로고침) 조용히 무시한다 — 화면은 이미 안내 패널을 그린다.
  Future<void> _onReload(
    ReloadInquiry event,
    Emitter<InquiryDetailState> emit,
  ) async {
    final id = _id;
    if (id == null) return;
    await _fetch(id, emit);
  }

  Future<void> _fetch(int id, Emitter<InquiryDetailState> emit) async {
    emit(InquiryDetailLoading());

    // 유형 라벨은 한 번만 받아 둔다(새로고침마다 다시 부르지 않는다).
    if (_typeOptions == null) {
      final typesResult = await inquiryUseCase.getTypeOptions();
      _typeOptions =
          typesResult.fold((_) => <InquiryTypeOption>[], (list) => list);
    }

    final result = await inquiryUseCase.getInquiry(id);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(InquiryDetailError(message: failure.message)),
      (detail) => emit(InquiryDetailLoaded(
        detail: detail,
        typeLabel: _labelOf(detail.inquiry.inquiryType),
      )),
    );
  }

  /// 답변 전송 (03) — `POST /api/admin/inquiries/{id}/replies`.
  ///
  /// 🔴 **재진입 가드는 여기에 둔다.** 버튼 비활성만으로는 부족하다 — 확인 다이얼로그가 떠 있는
  /// 사이 이벤트가 두 번 들어오거나 더블탭이 통과하면 **같은 답변이 두 번 간다**. 되돌릴 수 없는
  /// 전송이라 화면 한 곳이 아니라 BLoC 에서 막는다.
  ///
  /// 🔴 성공 후 [ReloadInquiry] 를 부르지 않는다 — 응답이 이미 갱신된 문의 1건이다.
  /// 🔴 실패해도 스레드에 낙관적으로 추가하지 않는다 — 성공 응답의 스레드만 신뢰한다.
  Future<void> _onSubmitReply(
    SubmitReply event,
    Emitter<InquiryDetailState> emit,
  ) async {
    final current = state;
    if (current is! InquiryDetailLoaded) return;
    if (current.submitting) return; // 재진입 가드
    final id = _id;
    if (id == null) return;

    emit(current.copyWith(submitting: true, clearReplyError: true));

    final result = await inquiryUseCase.replyToInquiry(id, event.content);
    if (emit.isDone) return; // 전송 중 화면을 벗어난 경우
    final latest = state;
    if (latest is! InquiryDetailLoaded) return;

    result.fold(
      (failure) {
        // 상태 코드 판정은 `order_cancel_bloc` 과 같은 관용구다.
        final code = failure is ServerFailure ? failure.statusCode : null;
        final handled = code == 403 || code == 502;
        emit(latest.copyWith(
          submitting: false,
          // 403 = ADMIN 아님 → 컴포저를 권한 안내로 바꾼다(실패 SnackBar 를 띄우지 않는다).
          replyForbidden: code == 403,
          // 502 = 전송 결과 미상 → 실패로 취급하지 않는다(재전송 유도 금지).
          replyUnknown: code == 502,
          replyError: handled ? null : failure.message,
          clearReplyError: handled,
        ));
      },
      // 응답이 곧 최신 문의다 — 스레드·상태·replyCapability 가 함께 갱신된다.
      (detail) => emit(latest.copyWith(
        detail: detail,
        typeLabel: _labelOf(detail.inquiry.inquiryType),
        submitting: false,
        clearReplyError: true,
      )),
    );
  }

  void _onReplyErrorCleared(
    ReplyErrorCleared event,
    Emitter<InquiryDetailState> emit,
  ) {
    final current = state;
    if (current is! InquiryDetailLoaded || current.replyError == null) return;
    emit(current.copyWith(clearReplyError: true));
  }

  /// 코드 → 라벨. 서버 목록에 없으면 null (칩을 그리지 않는다).
  String? _labelOf(InquiryType type) {
    for (final option in _typeOptions ?? const <InquiryTypeOption>[]) {
      if (option.code == type) return option.label;
    }
    return null;
  }
}
