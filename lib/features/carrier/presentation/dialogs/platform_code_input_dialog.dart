import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/platform_carrier_code.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/platform_code_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/platform_code_event.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/platform_code_state.dart';

/// 플랫폼 코드 생성/수정 다이얼로그.
///
/// **용도**: 택배사의 플랫폼별 코드(platform + deliveryCompanyCode) 생성/수정 폼.
/// - [code] 가 null 이면 추가 모드, 있으면 수정 모드.
///
/// **필수 사항**:
/// - 반드시 BlocProvider.value 로 [PlatformCodeBloc] 을 주입해서 열어야 함.
/// - 성공(PlatformCodeActionSuccess) 시 다이얼로그가 자동으로 닫히고 목록이 새로고침됨.
class PlatformCodeInputDialog extends StatefulWidget {
  final PlatformCarrierCode? code;

  const PlatformCodeInputDialog({this.code, super.key});

  bool get isEdit => code != null;

  @override
  State<PlatformCodeInputDialog> createState() => _PlatformCodeInputDialogState();
}

class _PlatformCodeInputDialogState extends State<PlatformCodeInputDialog> {
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _platformError;
  String? _codeError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final code = widget.code;
    if (code != null) {
      _platformController.text = code.platform;
      _codeController.text = code.deliveryCompanyCode;
    }
  }

  @override
  void dispose() {
    _platformController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final platform = _platformController.text.trim();
    final code = _codeController.text.trim();
    setState(() {
      _platformError = platform.isEmpty ? '플랫폼을 입력하세요' : null;
      _codeError = code.isEmpty ? '배송사 코드를 입력하세요' : null;
      _formError = null;
    });
    if (platform.isEmpty || code.isEmpty) return;

    final bloc = context.read<PlatformCodeBloc>();
    if (widget.isEdit) {
      bloc.add(UpdateCode(codeId: widget.code!.id, platform: platform, code: code));
    } else {
      bloc.add(CreateCode(platform: platform, code: code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? '플랫폼 코드 수정' : '플랫폼 코드 추가';

    return BlocConsumer<PlatformCodeBloc, PlatformCodeState>(
      listenWhen: (previous, current) =>
          current is PlatformCodeActionSuccess ||
          current is PlatformCodeActionFailure,
      listener: (context, state) {
        if (state is PlatformCodeActionSuccess) {
          Navigator.of(context).pop();
        } else if (state is PlatformCodeActionFailure) {
          setState(() => _formError = state.message);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is PlatformCodeActionInProgress;

        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_formError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _platformController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: '플랫폼 *',
                    hintText: '예: COUPANG',
                    border: const OutlineInputBorder(),
                    errorText: _platformError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: '배송사 코드 *',
                    hintText: '예: CJGLS',
                    border: const OutlineInputBorder(),
                    errorText: _codeError,
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
                  : Text(widget.isEdit ? '저장' : '추가'),
            ),
          ],
        );
      },
    );
  }
}
