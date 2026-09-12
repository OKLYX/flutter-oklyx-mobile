import '../../domain/entities/inquiry_detail.dart';

abstract class InquiryDetailState {}

class InquiryDetailInitial extends InquiryDetailState {}

/// 조회 중. ⚠️ 화면은 `extra` 로 받은 목록 항목으로 **헤더를 먼저 그리고**, 이 상태에서는
/// 스레드·관련 주문 자리에만 스피너를 놓는다(스피너만 있는 화면을 만들지 않는다).
class InquiryDetailLoading extends InquiryDetailState {}

class InquiryDetailError extends InquiryDetailState {
  final String message;

  InquiryDetailError({required this.message});
}

/// 조회 성공.
///
/// [copyWith] 는 03(답변 전송)이 **전송 성공 응답으로 이 상태를 직접 갱신**하기 위한 준비다 —
/// 그렇게 하면 전송 후 재조회가 필요 없다. ⚠️ 02 에서는 쓰지 않는다(필드만 만들어 둔다).
class InquiryDetailLoaded extends InquiryDetailState {
  final InquiryDetail detail;

  /// 유형 표시 문구. **서버 `/types` 가 준 라벨**이며(PLAN M2) 못 받았으면 null 이다 —
  /// 그때는 화면이 유형 칩을 그리지 않는다. 앱에 코드→라벨 표를 만들지 말 것.
  final String? typeLabel;

  InquiryDetailLoaded({required this.detail, this.typeLabel});

  InquiryDetailLoaded copyWith({InquiryDetail? detail, String? typeLabel}) =>
      InquiryDetailLoaded(
        detail: detail ?? this.detail,
        typeLabel: typeLabel ?? this.typeLabel,
      );
}
