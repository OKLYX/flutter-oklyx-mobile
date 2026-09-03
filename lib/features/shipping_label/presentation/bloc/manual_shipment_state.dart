import 'package:equatable/equatable.dart';

import '../../data/models/carrier_option.dart';
import '../../data/models/manual_shipment_result.dart';

/// 주문 상세 단건 발송처리 섹션 상태.
///
/// 전환마다 새 클래스를 만들지 않고 한 클래스를 copyWith 로 굴린다 — 택배사 목록과
/// 선택값을 전송 중/전송 후에도 잃지 않아야 하기 때문(송장시트 BLoC 과 의도적으로 다르다).
///
/// - [options] 가 비면 전송 불가(택배사 미등록, PLAN 2609_11 D16).
/// - [optionsLoadFailed] 는 조회 실패 — 등록된 택배사가 없는 것과 안내 문구가 다르다.
/// - [optionsForbidden] 은 403(ADMIN 아님) → 섹션 자체를 숨긴다.
/// - [result] 가 있으면 입력을 잠근다(D14) — 쿠팡이 응답을 준 뒤라 같은 번호 재전송은
///   DUPLICATE_INVOICE_NUMBER 를 부른다. 반대로 요청 자체가 실패한 [errorMessage] 는 잠그지 않는다.
class ManualShipmentState extends Equatable {
  final bool loadingOptions;
  final List<CarrierOption> options;
  final String? carrierCode;
  final bool submitting;
  final ManualShipmentResult? result;

  /// 전송 실패(응답 자체가 실패). 쿠팡이 응답을 준 부분실패는 [result] 의 failed 로 간다.
  final String? errorMessage;
  final bool optionsLoadFailed;
  final bool optionsForbidden;

  /// 초기 상태. 생성 직후 LoadCarrierOptions 가 붙으므로 loadingOptions 를 true 로 시작한다
  /// (false 로 시작하면 첫 프레임에 "택배사 없음" 안내가 깜빡인다).
  const ManualShipmentState.initial()
      : loadingOptions = true,
        options = const [],
        carrierCode = null,
        submitting = false,
        result = null,
        errorMessage = null,
        optionsLoadFailed = false,
        optionsForbidden = false;

  const ManualShipmentState({
    required this.loadingOptions,
    required this.options,
    required this.carrierCode,
    required this.submitting,
    required this.result,
    required this.errorMessage,
    required this.optionsLoadFailed,
    required this.optionsForbidden,
  });

  /// [clearError] 없이 `errorMessage: null` 을 넘기면 기존 값이 승계된다(?? 함정).
  ManualShipmentState copyWith({
    bool? loadingOptions,
    List<CarrierOption>? options,
    String? carrierCode,
    bool? submitting,
    ManualShipmentResult? result,
    String? errorMessage,
    bool? optionsLoadFailed,
    bool? optionsForbidden,
    bool clearError = false,
  }) =>
      ManualShipmentState(
        loadingOptions: loadingOptions ?? this.loadingOptions,
        options: options ?? this.options,
        carrierCode: carrierCode ?? this.carrierCode,
        submitting: submitting ?? this.submitting,
        result: result ?? this.result,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        optionsLoadFailed: optionsLoadFailed ?? this.optionsLoadFailed,
        optionsForbidden: optionsForbidden ?? this.optionsForbidden,
      );

  @override
  List<Object?> get props => [
        loadingOptions,
        options,
        carrierCode,
        submitting,
        result,
        errorMessage,
        optionsLoadFailed,
        optionsForbidden,
      ];
}
