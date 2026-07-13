import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_form_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_form_event.dart';
import 'package:flutter_oklyn_mobile/features/carrier/presentation/bloc/carrier_form_state.dart';

/// 택배사 생성/수정 다이얼로그.
///
/// **용도**: 택배사 마스터(name + isActive) 생성 또는 수정 폼.
/// - [carrier] 가 null 이면 추가 모드(isActive 기본 true), 있으면 수정 모드.
///
/// **필수 사항**:
/// - 반드시 BlocProvider.value 로 [CarrierFormBloc] 을 주입해서 열어야 함.
/// - 성공(CarrierFormSuccess) 시 다이얼로그가 자동으로 닫히고, 페이지가 목록을 재조회함.
///
/// **사용 예제**:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => BlocProvider.value(
///     value: context.read<CarrierFormBloc>(),
///     child: const CarrierInputDialog(),
///   ),
/// );
/// ```
class CarrierInputDialog extends StatefulWidget {
  final Carrier? carrier;

  const CarrierInputDialog({this.carrier, super.key});

  bool get isEdit => carrier != null;

  @override
  State<CarrierInputDialog> createState() => _CarrierInputDialogState();
}

class _CarrierInputDialogState extends State<CarrierInputDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isActive = true;
  String? _nameError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final carrier = widget.carrier;
    if (carrier != null) {
      _nameController.text = carrier.name;
      _isActive = carrier.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '택배사명을 입력하세요');
      return;
    }
    setState(() {
      _nameError = null;
      _formError = null;
    });

    final bloc = context.read<CarrierFormBloc>();
    if (widget.isEdit) {
      bloc.add(UpdateCarrier(id: widget.carrier!.id, name: name, isActive: _isActive));
    } else {
      bloc.add(CreateCarrier(name: name, isActive: _isActive));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? '택배사 수정' : '택배사 추가';

    return BlocConsumer<CarrierFormBloc, CarrierFormState>(
      listener: (context, state) {
        if (state is CarrierFormSuccess &&
            (state.action == CarrierFormAction.create ||
                state.action == CarrierFormAction.update)) {
          Navigator.of(context).pop();
        } else if (state is CarrierFormError) {
          setState(() => _formError = state.message);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CarrierFormLoading;

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
                  controller: _nameController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: '택배사명 *',
                    hintText: '예: CJ대한통운',
                    border: const OutlineInputBorder(),
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('활성'),
                  value: _isActive,
                  onChanged: isSubmitting
                      ? null
                      : (value) => setState(() => _isActive = value),
                  contentPadding: EdgeInsets.zero,
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
