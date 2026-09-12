import 'package:flutter_bloc/flutter_bloc.dart';
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

  /// 코드 → 라벨. 서버 목록에 없으면 null (칩을 그리지 않는다).
  String? _labelOf(InquiryType type) {
    for (final option in _typeOptions ?? const <InquiryTypeOption>[]) {
      if (option.code == type) return option.label;
    }
    return null;
  }
}
