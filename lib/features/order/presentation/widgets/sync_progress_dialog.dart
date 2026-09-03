import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sync_target.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';

/// 주문 동기화 진행 다이얼로그 (채널별 진행률 + 완료 리포트)
///
/// **용도**: 동기화 중 화면을 차단해 "어느 판매자·어느 플랫폼을 조회 중인지"와 진행률을
/// 보여주고, 끝나면 채널별 성공/실패를 요약해 실패한 채널만 다시 조회하게 한다.
///
/// **표시 방법** (order_history_page 의 BlocListener 에서 isSyncing false→true 일 때):
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (_) => BlocProvider.value(
///     value: context.read<OrderListBloc>(),   // 다이얼로그는 별도 route
///     child: const SyncProgressDialog(),
///   ),
/// );
/// ```
///
/// ⚠️ 동기화가 끝나도(`isSyncing == false`) 자동으로 닫지 않는다 — 리포트를 보여주고
///    사용자가 [닫기]로 닫는다. `Navigator.pop` 은 이 위젯 안에서만 호출한다(중복 pop 방지).
/// ⚠️ 진행률 분모는 `syncChannels.length`(서버가 준 동기화 대상 수)다.
/// ⚠️ 여기 표시되는 `성공` 은 **HTTP 결과**다. 서버가 PARTIAL 로 낙인한 채널도 성공으로 보인다 —
///    실제 채널 상태는 닫은 뒤 목록 상단 배너(`syncTargets`)가 알려준다.
class SyncProgressDialog extends StatelessWidget {
  const SyncProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderListBloc, OrderListState>(
      builder: (context, state) {
        if (state is! OrderListLoaded) return const SizedBox.shrink();

        final channels = state.syncChannels;
        final total = channels.length;
        final done = state.syncDoneCount;
        final isRunning = state.isSyncing;
        final successCount =
            channels.where((c) => c.state == ChannelSyncState.success).length;
        final failedCount =
            channels.where((c) => c.state == ChannelSyncState.failed).length;
        final runningList = channels
            .where((c) => c.state == ChannelSyncState.running)
            .toList();
        final running = runningList.isEmpty ? null : runningList.first;

        final title = isRunning
            ? '동기화 중… ($done/$total)'
            : '동기화 완료 · 성공 $successCount · 실패 $failedCount'
                '${state.syncCanceled ? ' · 중단됨' : ''}';

        return PopScope(
          // 진행 중에는 안드로이드 뒤로가기로도 닫히지 않는다.
          canPop: !isRunning,
          child: AlertDialog(
            title: Text(title, style: const TextStyle(fontSize: 16)),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: total > 0 ? done / total : 0),
                  if (running != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _channelLabel(running.target),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: channels.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) =>
                          _ChannelRow(channel: channels[index]),
                    ),
                  ),
                  if (isRunning) ...[
                    const SizedBox(height: 8),
                    Text(
                      '진행 중인 채널은 끝까지 조회한 뒤 멈춥니다.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            actions: isRunning
                ? [
                    TextButton(
                      onPressed: () =>
                          context.read<OrderListBloc>().add(CancelSync()),
                      child: const Text('취소'),
                    ),
                  ]
                : [
                    if (failedCount > 0)
                      TextButton(
                        onPressed: () => context
                            .read<OrderListBloc>()
                            .add(RetryFailedChannels()),
                        child: const Text('실패한 채널만 다시 조회'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                  ],
          ),
        );
      },
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final ChannelProgress channel;

  const _ChannelRow({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 18, child: Center(child: _icon())),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _channelLabel(channel.target),
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (channel.state == ChannelSyncState.failed && channel.error != null)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                channel.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.red[700]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _icon() {
    switch (channel.state) {
      case ChannelSyncState.pending:
        return Text('·', style: TextStyle(color: Colors.grey[400]));
      case ChannelSyncState.running:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ChannelSyncState.success:
        return Icon(Icons.check, size: 16, color: Colors.green[600]);
      case ChannelSyncState.failed:
        return Icon(Icons.close, size: 16, color: Colors.red[600]);
    }
  }
}

/// '판매자 · 플랫폼 · 계정별칭' (별칭 없으면 생략)
String _channelLabel(SyncTarget target) {
  final alias = target.accountAlias;
  final suffix = (alias == null || alias.isEmpty) ? '' : ' · $alias';
  return '${target.sellerName} · ${target.platform}$suffix';
}
