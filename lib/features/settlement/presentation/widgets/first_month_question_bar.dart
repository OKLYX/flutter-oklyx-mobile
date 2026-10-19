import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';

/// 「{채널 이름} 11번가 채널: 지난달(2026년 9월) 11번가 구매확정액이 500만 원 이상이었나요?」 (D45 ⑦).
String firstMonthQuestionText(FirstMonthQuestion question) {
  final alias = question.accountAlias?.trim() ?? '';
  final channel =
      alias.isNotEmpty ? question.accountAlias : '채널 #${question.accountId}';
  return '$channel 11번가 채널: 지난달(${monthLabel(question.askMonth)}) 11번가 구매확정액이 '
      '500만 원 이상이었나요?';
}

/// 11st server-fee first-month questions — one yellow row per waiting link at
/// the top of 「정산 내역」 (FEATURE_2610_20 / D45 ⑦). Display only: the BLoC loads
/// the questions and sends the answer.
class FirstMonthQuestionBar extends StatelessWidget {
  final List<FirstMonthQuestion> questions;
  final int? answeringLinkId;
  final String error;
  final void Function(int linkId, {required bool charged}) onAnswer;

  const FirstMonthQuestionBar({
    required this.questions,
    required this.error,
    required this.onAnswer,
    super.key,
    this.answeringLinkId,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty && error.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final question in questions) ...[
          SettlementMessageBox(
            tone: SettlementMessageTone.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(firstMonthQuestionText(question)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: answeringLinkId == question.linkId
                          ? null
                          : () => onAnswer(question.linkId, charged: true),
                      child: const Text('예'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: answeringLinkId == question.linkId
                          ? null
                          : () => onAnswer(question.linkId, charged: false),
                      child: const Text('아니오'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (error.isNotEmpty) ...[
          SettlementMessageBox(
              tone: SettlementMessageTone.error, message: error),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
