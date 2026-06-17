import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/entities/marketplace_account.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/bloc/marketplace_account_bloc.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/bloc/marketplace_account_event.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/bloc/marketplace_account_state.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/dialogs/channel_details_dialog.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/dialogs/channel_form_dialog.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/widgets/platform_options.dart';

/// 판매자 행을 펼쳤을 때 노출되는 판매채널(MarketplaceAccount) 섹션.
///
/// 프론트엔드 SellerChannelSection 과 동일한 기능을 모바일에서 제공한다:
/// 판매채널 목록 조회 + 추가 + 상세 + 수정 + 삭제.
///
/// 판매자별로 자체 [MarketplaceAccountBloc] 을 생성(factoryParam)하여 채널 목록을
/// 불러온다. 생성/수정/삭제 후에는 목록이 자동으로 새로고침된다.
class SellerChannelSection extends StatelessWidget {
  final int sellerId;
  final String sellerName;

  const SellerChannelSection({
    required this.sellerId,
    required this.sellerName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MarketplaceAccountBloc>(
      create: (_) =>
          GetIt.instance<MarketplaceAccountBloc>(param1: sellerId)..add(const LoadChannels()),
      child: _SellerChannelSectionView(sellerId: sellerId, sellerName: sellerName),
    );
  }
}

class _SellerChannelSectionView extends StatelessWidget {
  final int sellerId;
  final String sellerName;

  const _SellerChannelSectionView({required this.sellerId, required this.sellerName});

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    // Bottom nav 가 overlay 로 떠 있으므로 SnackBar 는 floating + 하단 여백으로 띄운다.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : null,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
      ),
    );
  }

  void _openCreateDialog(BuildContext context) {
    final bloc = context.read<MarketplaceAccountBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ChannelFormDialog(sellerId: sellerId, sellerName: sellerName),
      ),
    );
  }

  void _openEditDialog(BuildContext context, MarketplaceAccount channel) {
    final bloc = context.read<MarketplaceAccountBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ChannelFormDialog(
          sellerId: sellerId,
          sellerName: sellerName,
          channel: channel,
        ),
      ),
    );
  }

  void _openDetailsDialog(BuildContext context, MarketplaceAccount channel) {
    final bloc = context.read<MarketplaceAccountBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => ChannelDetailsDialog(
        channel: channel,
        sellerName: sellerName,
        onEdit: () {
          Navigator.of(dialogContext).pop();
          _openEditDialog(context, channel);
        },
        onDelete: () {
          Navigator.of(dialogContext).pop();
          _confirmDelete(context, bloc, channel);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, MarketplaceAccountBloc bloc, MarketplaceAccount channel) {
    final label = (channel.accountAlias?.isNotEmpty ?? false)
        ? channel.accountAlias!
        : platformLabel(channel.platform);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('정말로 "$label" 판매채널을 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(DeleteChannelRequested(channel.id));
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MarketplaceAccountBloc, MarketplaceAccountState>(
      listenWhen: (previous, current) =>
          current is MarketplaceAccountActionSuccess ||
          current is MarketplaceAccountActionFailure,
      listener: (context, state) {
        if (state is MarketplaceAccountActionSuccess) {
          _showSnackBar(context, state.message);
        } else if (state is MarketplaceAccountActionFailure) {
          _showSnackBar(context, state.message, isError: true);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '판매채널',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: () => _openCreateDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('판매채널 추가'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BlocBuilder<MarketplaceAccountBloc, MarketplaceAccountState>(
              // 액션(생성/수정/삭제) 상태에서는 목록을 다시 그리지 않아 리스트가 유지된다.
              buildWhen: (previous, current) =>
                  current is MarketplaceAccountInitial ||
                  current is MarketplaceAccountLoading ||
                  current is MarketplaceAccountLoaded ||
                  current is MarketplaceAccountError,
              builder: (context, state) {
                if (state is MarketplaceAccountLoading || state is MarketplaceAccountInitial) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is MarketplaceAccountError) {
                  return _MessageBox(
                    message: state.message,
                    isError: true,
                    onRetry: () =>
                        context.read<MarketplaceAccountBloc>().add(const LoadChannels()),
                  );
                }
                if (state is MarketplaceAccountLoaded) {
                  if (state.channels.isEmpty) {
                    return const _MessageBox(message: '등록된 판매채널이 없습니다.');
                  }
                  return Column(
                    children: state.channels
                        .map((channel) => _ChannelTile(
                              channel: channel,
                              onTap: () => _openDetailsDialog(context, channel),
                            ))
                        .toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final MarketplaceAccount channel;
  final VoidCallback onTap;

  const _ChannelTile({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(
              child: Text(
                platformLabel(channel.platform),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _StatusChip(isActive: channel.isActive),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('별칭: ${channel.accountAlias?.isNotEmpty == true ? channel.accountAlias : '-'}'),
            Text('벤더 ID: ${channel.vendorId}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
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

class _MessageBox extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const _MessageBox({required this.message, this.isError = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.white,
        border: Border.all(color: isError ? Colors.red.shade200 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isError ? Colors.red.shade700 : Colors.grey.shade600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('재시도')),
          ],
        ],
      ),
    );
  }
}
