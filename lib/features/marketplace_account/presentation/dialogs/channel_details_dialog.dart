import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/entities/marketplace_account.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/widgets/platform_options.dart';

/// 판매채널 상세 정보 다이얼로그 (읽기 전용).
///
/// 채널 행을 탭하면 열린다. [onEdit] / [onDelete] 콜백으로 수정/삭제 흐름을 트리거한다.
/// (Secret Key 는 응답에 없으므로 표시하지 않는다.)
class ChannelDetailsDialog extends StatelessWidget {
  final MarketplaceAccount channel;
  final String sellerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChannelDetailsDialog({
    required this.channel,
    required this.sellerName,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('판매채널 정보 — $sellerName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: '플랫폼', value: platformLabel(channel.platform)),
            _DetailRow(label: '계정 별칭', value: channel.accountAlias ?? '-'),
            _DetailRow(label: '판매자(벤더) ID', value: channel.vendorId),
            _DetailRow(label: 'Access Key', value: channel.accessKey),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 110,
                    child: Text('상태', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  _StatusChip(isActive: channel.isActive),
                ],
              ),
            ),
            _DetailRow(label: '등록일', value: channel.createdAt),
            _DetailRow(label: '수정일', value: channel.updatedAt),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: onEdit,
          child: const Text('수정'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: onDelete,
          child: const Text('삭제'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? '활성' : '비활성',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
