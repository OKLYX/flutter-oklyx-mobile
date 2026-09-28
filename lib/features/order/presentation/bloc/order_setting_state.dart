import 'package:equatable/equatable.dart';

import '../../data/models/order_setting.dart';

/// 주문관리 설정 화면 상태 (FEATURE_2609_75 / D12).
class OrderSettingState extends Equatable {
  final bool loading;
  final bool saving;
  final OrderSetting? setting;
  final String? errorMessage;

  /// 방금 저장에 성공했다(SnackBar 1회용 — 화면이 소비한다).
  final bool saved;

  /// 403 — 관리자가 아니다.
  final bool forbidden;

  const OrderSettingState({
    required this.loading,
    required this.saving,
    required this.setting,
    required this.errorMessage,
    required this.saved,
    required this.forbidden,
  });

  const OrderSettingState.initial()
      : loading = true,
        saving = false,
        setting = null,
        errorMessage = null,
        saved = false,
        forbidden = false;

  OrderSettingState copyWith({
    bool? loading,
    bool? saving,
    OrderSetting? setting,
    String? errorMessage,
    bool? saved,
    bool? forbidden,
    bool clearError = false,
  }) =>
      OrderSettingState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        setting: setting ?? this.setting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        saved: saved ?? this.saved,
        forbidden: forbidden ?? this.forbidden,
      );

  @override
  List<Object?> get props =>
      [loading, saving, setting, errorMessage, saved, forbidden];
}
