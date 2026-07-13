import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/platform_carrier_code.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/platform_code_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/platform_code_event.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/platform_code_state.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/dialogs/platform_code_input_dialog.dart';

/// 택배사 행을 펼쳤을 때 노출되는 플랫폼 코드 섹션.
///
/// 프론트엔드 carrier-company 화면의 플랫폼 코드 관리와 동일한 기능을 제공한다:
/// 코드 목록 조회 + 추가 + 수정 + 삭제.
///
/// 택배사별로 자체 [PlatformCodeBloc] 을 생성(factoryParam: carrierId)하여 목록을
/// 불러온다. 생성/수정/삭제 후에는 목록이 자동으로 새로고침된다.
class PlatformCodeSection extends StatelessWidget {
  final int carrierId;

  const PlatformCodeSection({required this.carrierId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlatformCodeBloc>(
      create: (_) =>
          GetIt.instance<PlatformCodeBloc>(param1: carrierId)..add(FetchCodes()),
      child: _PlatformCodeSectionView(carrierId: carrierId),
    );
  }
}

class _PlatformCodeSectionView extends StatelessWidget {
  final int carrierId;

  const _PlatformCodeSectionView({required this.carrierId});

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
    final bloc = context.read<PlatformCodeBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const PlatformCodeInputDialog(),
      ),
    );
  }

  void _openEditDialog(BuildContext context, PlatformCarrierCode code) {
    final bloc = context.read<PlatformCodeBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: PlatformCodeInputDialog(code: code),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlatformCodeBloc bloc, PlatformCarrierCode code) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${code.platform} → ${code.deliveryCompanyCode}" 코드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(DeleteCode(codeId: code.id));
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlatformCodeBloc, PlatformCodeState>(
      listenWhen: (previous, current) =>
          current is PlatformCodeActionSuccess ||
          current is PlatformCodeActionFailure,
      listener: (context, state) {
        if (state is PlatformCodeActionSuccess) {
          _showSnackBar(context, state.message);
        } else if (state is PlatformCodeActionFailure) {
          _showSnackBar(context, state.message, isError: true);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: Colors.grey.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '플랫폼 코드',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            BlocBuilder<PlatformCodeBloc, PlatformCodeState>(
              // 액션(생성/수정/삭제) 상태에서는 목록을 다시 그리지 않아 리스트가 유지된다.
              buildWhen: (previous, current) =>
                  current is PlatformCodeInitial ||
                  current is PlatformCodeLoading ||
                  current is PlatformCodeLoaded ||
                  current is PlatformCodeError,
              builder: (context, state) {
                if (state is PlatformCodeLoading || state is PlatformCodeInitial) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is PlatformCodeError) {
                  return _MessageBox(
                    message: state.message,
                    isError: true,
                    onRetry: () =>
                        context.read<PlatformCodeBloc>().add(FetchCodes()),
                  );
                }
                if (state is PlatformCodeLoaded) {
                  return Column(
                    children: [
                      if (state.codes.isEmpty)
                        const _MessageBox(message: '등록된 플랫폼 코드가 없습니다.')
                      else
                        ...state.codes.map((code) => _CodeTile(
                              code: code,
                              onEdit: () => _openEditDialog(context, code),
                              onDelete: () => _confirmDelete(
                                  context, context.read<PlatformCodeBloc>(), code),
                            )),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _openCreateDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('코드 추가'),
                        ),
                      ),
                    ],
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

class _CodeTile extends StatelessWidget {
  final PlatformCarrierCode code;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CodeTile({required this.code, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                code.platform,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Text(code.deliveryCompanyCode)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: '수정',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: '삭제',
            ),
          ],
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
