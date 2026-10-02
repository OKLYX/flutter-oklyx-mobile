import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/order_setting_bloc.dart';
import '../bloc/order_setting_event.dart';
import '../bloc/order_setting_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// 주문관리 > 주문관리 설정 페이지 (FEATURE_2609_75 / D4·D12).
///
/// **용도**: 테넌트 기본 예약 발송 시각(한국시간) 1개를 보고 바꾼다. 초기값 00:02.
/// **파일**: lib/features/order/presentation/pages/order_settings_page.dart
/// ⚠️ 시각은 'HH:mm' 문자열 그대로 주고받는다 — DateTime 으로 시간대 계산을 하지 않는다.
/// ⚠️ 메인 탭(Drawer 진입) 규칙 = 출고관리와 같은 navBarIndex 2 · showDrawer true · showAppBarDrawerButton false.
class OrderSettingsPage extends StatelessWidget {
  const OrderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<OrderSettingBloc>()..add(const OrderSettingRequested()),
      child: const _OrderSettingsView(),
    );
  }
}

class _OrderSettingsView extends StatelessWidget {
  const _OrderSettingsView();

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '주문관리 설정',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<OrderSettingBloc, OrderSettingState>(
        listenWhen: (prev, curr) => curr.saved && !prev.saved,
        listener: (context, state) {
          showSuccessToast(context, '저장했습니다.');
        },
        builder: (context, state) {
          if (state.loading) {
            return const AppPageBody(children: [AppLoading()]);
          }
          if (state.forbidden) {
            return const Center(child: Text('관리자만 설정할 수 있습니다.'));
          }
          final setting = state.setting;
          return AppPageBody(
            children: [
              AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '예약 발송',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text('기본 예약 발송 시각',
                          style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            setting?.reservedShipmentTime ?? '-',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: setting == null || state.saving
                                ? null
                                : () => _pickAndSave(
                                    context, setting.reservedShipmentTime),
                            child: state.saving
                                ? const AppBusyLabel('변경')
                                : const Text('변경'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '한국시간입니다. [예약 발송]을 누를 때 이 시각이 기본으로 채워집니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (setting != null &&
                          setting.nextExecuteAt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // 서버가 준 KST 벽시계를 그대로 'yyyy-MM-dd HH:mm' 로 보여준다(오프셋 없는 값 = 변환 없음).
                        Text(
                          '다음 기본 예약 시각: ${formatOrderDateTime(setting.nextExecuteAt)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 시각 선택 → 'HH:mm' 로 저장. 선택을 취소하면 아무것도 하지 않는다.
  Future<void> _pickAndSave(BuildContext context, String current) async {
    final bloc = context.read<OrderSettingBloc>();
    final parts = current.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 2,
          )
        : const TimeOfDay(hour: 0, minute: 2);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || bloc.isClosed) return;
    String two(int n) => n.toString().padLeft(2, '0');
    bloc.add(OrderSettingSaved('${two(picked.hour)}:${two(picked.minute)}'));
  }
}
