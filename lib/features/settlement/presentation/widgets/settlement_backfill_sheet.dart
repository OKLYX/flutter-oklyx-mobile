import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_event.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_state.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

/// [과거 정산 불러오기] sheet — one channel, a start month and an end month
/// (FEATURE_2610_20 / D19 · D24 · D25), the mobile twin of the web
/// `SettlementBackfillDialog`. Open it with `showAppSheet` +
/// `BlocProvider.value`.
///
/// 🔴 The month loop runs in [PayoutListBloc]; this sheet only collects the
/// input and shows the progress.
/// ⚠️ While running the sheet cannot be closed; it closes by itself when the
/// run ends. D11 · D14: the notice names the chosen channel's market and calls
/// 11st once per month, other markets twice.
class SettlementBackfillSheet extends StatefulWidget {
  const SettlementBackfillSheet({super.key});

  @override
  State<SettlementBackfillSheet> createState() =>
      _SettlementBackfillSheetState();
}

class _SettlementBackfillSheetState extends State<SettlementBackfillSheet> {
  final List<({String value, String label})> _months =
      buildSettlementMonthOptions();
  int? _accountId;
  String _fromMonth = '';
  String _toMonth = '';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Default = three months ago ~ this month (the list is newest first).
    _fromMonth = (_months.length > 3 ? _months[3] : _months.last).value;
    _toMonth = _months.first.value;
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PayoutListBloc, PayoutListState>(
        listenWhen: (previous, current) =>
            previous.backfillRunning && !current.backfillRunning,
        listener: (context, state) {
          if (_started) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final channels = state.channels;
          final selectedId = _accountId ?? channels.firstOrNull?.accountId;
          final selected =
              channels.where((c) => c.accountId == selectedId).firstOrNull;
          final invalidRange = _fromMonth.compareTo(_toMonth) > 0;
          final running = state.backfillRunning;
          final callsPerMonth = selected?.platform == 'ELEVENST' ? 1 : 2;
          return PopScope(
            canPop: !running,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('과거 정산 불러오기',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  '선택한 달마다 '
                  '${withObjectParticle(marketName(selected?.platform))} '
                  '$callsPerMonth번씩 조회합니다. '
                  '기간이 길수록 오래 걸립니다.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (channels.isEmpty)
                  const Text('불러올 채널이 없습니다.')
                else ...[
                  DropdownButtonFormField<int>(
                    initialValue: selectedId,
                    decoration: const InputDecoration(labelText: '채널'),
                    items: [
                      for (final c in channels)
                        DropdownMenuItem(
                          value: c.accountId,
                          child: Text(channelLabel(
                              c.platform, c.accountAlias, c.accountId)),
                        ),
                    ],
                    onChanged: running
                        ? null
                        : (value) => setState(() => _accountId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _fromMonth,
                    decoration: const InputDecoration(labelText: '시작월'),
                    items: [
                      for (final m in _months)
                        DropdownMenuItem(value: m.value, child: Text(m.label))
                    ],
                    onChanged: running
                        ? null
                        : (value) =>
                            setState(() => _fromMonth = value ?? _fromMonth),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _toMonth,
                    decoration: const InputDecoration(labelText: '종료월'),
                    items: [
                      for (final m in _months)
                        DropdownMenuItem(value: m.value, child: Text(m.label))
                    ],
                    onChanged: running
                        ? null
                        : (value) =>
                            setState(() => _toMonth = value ?? _toMonth),
                  ),
                  if (invalidRange) ...[
                    const SizedBox(height: 12),
                    const SettlementMessageBox(
                        tone: SettlementMessageTone.error,
                        message: '시작월이 종료월보다 뒤입니다.'),
                  ],
                ],
                if (running && state.backfillProgress.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SettlementMessageBox(
                      tone: SettlementMessageTone.info,
                      message: state.backfillProgress),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                          running ? null : () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: running || selectedId == null || invalidRange
                          ? null
                          : () {
                              _started = true;
                              context
                                  .read<PayoutListBloc>()
                                  .add(PayoutBackfillRequested(
                                    accountId: selectedId,
                                    fromMonth: _fromMonth,
                                    toMonth: _toMonth,
                                  ));
                            },
                      child: running
                          ? const AppBusyLabel('불러오기')
                          : const Text('불러오기'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}
