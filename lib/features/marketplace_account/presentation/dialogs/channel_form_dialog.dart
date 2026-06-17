import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/entities/marketplace_account.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/repositories/marketplace_account_repository.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/bloc/marketplace_account_bloc.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/bloc/marketplace_account_event.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/bloc/marketplace_account_state.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/widgets/platform_options.dart';

/// 판매채널 추가/수정 다이얼로그.
///
/// **용도**: 판매채널(MarketplaceAccount) 생성 또는 수정 폼.
/// - [channel] 이 null 이면 추가 모드, 있으면 수정 모드.
/// - 수정 모드에서 Secret Key 는 비워두면 기존 값이 유지된다 (응답에 없으므로 미리 채울 수 없음).
///
/// **필수 사항**:
/// - 반드시 BlocProvider.value 로 [MarketplaceAccountBloc] 을 주입해서 열어야 함.
/// - 성공(ActionSuccess) 시 다이얼로그가 자동으로 닫히고, 섹션이 목록을 새로고침함.
///
/// **사용 예제**:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => BlocProvider.value(
///     value: context.read<MarketplaceAccountBloc>(),
///     child: ChannelFormDialog(sellerId: sellerId, sellerName: name),
///   ),
/// );
/// ```
class ChannelFormDialog extends StatefulWidget {
  final int sellerId;
  final String sellerName;
  final MarketplaceAccount? channel;

  const ChannelFormDialog({
    required this.sellerId,
    required this.sellerName,
    this.channel,
    super.key,
  });

  bool get isEdit => channel != null;

  @override
  State<ChannelFormDialog> createState() => _ChannelFormDialogState();
}

class _ChannelFormDialogState extends State<ChannelFormDialog> {
  String _platform = '';
  final TextEditingController _accountAliasController = TextEditingController();
  final TextEditingController _vendorIdController = TextEditingController();
  final TextEditingController _accessKeyController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();

  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    final channel = widget.channel;
    if (channel != null) {
      _platform = channel.platform;
      _accountAliasController.text = channel.accountAlias ?? '';
      _vendorIdController.text = channel.vendorId;
      _accessKeyController.text = channel.accessKey;
    }
  }

  @override
  void dispose() {
    _accountAliasController.dispose();
    _vendorIdController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <String, String?>{};
    if (_platform.isEmpty) {
      errors['platform'] = '플랫폼을 선택하세요';
    }
    if (_vendorIdController.text.trim().isEmpty) {
      errors['vendorId'] = '판매자(벤더) ID를 입력하세요';
    }
    if (_accessKeyController.text.trim().isEmpty) {
      errors['accessKey'] = 'Access Key를 입력하세요';
    }
    if (!widget.isEdit && _secretKeyController.text.isEmpty) {
      errors['secretKey'] = 'Secret Key를 입력하세요';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  void _onSubmit() {
    if (!_validate()) return;

    final alias = _accountAliasController.text.trim();
    final bloc = context.read<MarketplaceAccountBloc>();

    if (widget.isEdit) {
      bloc.add(UpdateChannelRequested(
        widget.channel!.id,
        UpdateMarketplaceAccountParams(
          sellerId: widget.sellerId,
          platform: _platform,
          accountAlias: alias.isEmpty ? null : alias,
          vendorId: _vendorIdController.text.trim(),
          accessKey: _accessKeyController.text.trim(),
          secretKey: _secretKeyController.text.isEmpty ? null : _secretKeyController.text,
        ),
      ));
    } else {
      bloc.add(CreateChannelRequested(
        CreateMarketplaceAccountParams(
          sellerId: widget.sellerId,
          platform: _platform,
          accountAlias: alias.isEmpty ? null : alias,
          vendorId: _vendorIdController.text.trim(),
          accessKey: _accessKeyController.text.trim(),
          secretKey: _secretKeyController.text,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? '판매채널 수정' : '판매채널 추가';

    return BlocConsumer<MarketplaceAccountBloc, MarketplaceAccountState>(
      listenWhen: (previous, current) =>
          current is MarketplaceAccountActionSuccess ||
          current is MarketplaceAccountActionFailure,
      listener: (context, state) {
        if (state is MarketplaceAccountActionSuccess) {
          Navigator.of(context).pop();
        } else if (state is MarketplaceAccountActionFailure) {
          setState(() => _errors['form'] = state.message);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is MarketplaceAccountActionInProgress;

        return AlertDialog(
          title: Text('$title — ${widget.sellerName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errors['form'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errors['form']!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  value: _platform.isEmpty ? null : _platform,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '플랫폼 *',
                    border: const OutlineInputBorder(),
                    errorText: _errors['platform'],
                  ),
                  hint: const Text('플랫폼을 선택하세요'),
                  items: kPlatformOptions
                      .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) => setState(() => _platform = value ?? ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountAliasController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: '계정 별칭',
                    hintText: '예: 쿠팡 본점',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _vendorIdController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: '판매자(벤더) ID *',
                    hintText: '예: A00012345',
                    border: const OutlineInputBorder(),
                    errorText: _errors['vendorId'],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accessKeyController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Access Key *',
                    hintText: 'Access Key를 입력하세요',
                    border: const OutlineInputBorder(),
                    errorText: _errors['accessKey'],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _secretKeyController,
                  enabled: !isSubmitting,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: widget.isEdit ? 'Secret Key' : 'Secret Key *',
                    hintText: widget.isEdit
                        ? '변경 시에만 입력 (비워두면 기존 값 유지)'
                        : 'Secret Key를 입력하세요',
                    border: const OutlineInputBorder(),
                    errorText: _errors['secretKey'],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: isSubmitting ? null : _onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isEdit ? '저장' : '등록'),
            ),
          ],
        );
      },
    );
  }
}
