import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/carrier_rate_create_bloc.dart';
import '../bloc/carrier_rate_create_event.dart';
import '../bloc/carrier_rate_create_state.dart';
import '../bloc/carrier_rate_list_bloc.dart';
import '../bloc/carrier_rate_list_event.dart';

/// Carrier Rate Input Dialog
///
/// 택배비 추가 다이얼로그. "택배비 추가" 버튼 탭 시 표시됨.
///
/// 필수 속성:
/// - onClose: 다이얼로그 닫기 콜백
///
/// 사용 예:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (ctx) => MultiBlocProvider(
///     providers: [
///       BlocProvider.value(value: context.read<CarrierRateCreateBloc>()),
///       BlocProvider.value(value: context.read<CarrierRateListBloc>()),
///     ],
///     child: CarrierRateInputDialog(
///       onClose: () => Navigator.pop(context),
///     ),
///   ),
/// );
/// ```
///
/// ⚠️ BLoC 접근: context.read<CarrierRateCreateBloc>()
class CarrierRateInputDialog extends StatefulWidget {
  final VoidCallback onClose;

  const CarrierRateInputDialog({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CarrierRateInputDialog> createState() => _CarrierRateInputDialogState();
}

void showCreateCarrierRateDialog(BuildContext context) {
  context.read<CarrierRateCreateBloc>().add(ResetCreateForm());

  showDialog(
    context: context,
    builder: (ctx) => MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: context.read<CarrierRateCreateBloc>(),
        ),
        BlocProvider.value(
          value: context.read<CarrierRateListBloc>(),
        ),
      ],
      child: CarrierRateInputDialog(
        onClose: () => Navigator.pop(context),
      ),
    ),
  );
}


class _CarrierRateInputDialogState extends State<CarrierRateInputDialog> {
  late TextEditingController _carrierController;
  late TextEditingController _typeController;
  late TextEditingController _costController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _carrierController = TextEditingController();
    _typeController = TextEditingController();
    _costController = TextEditingController();
    _dateController = TextEditingController();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dateController.text = today;
    Future.microtask(() {
      context.read<CarrierRateCreateBloc>().add(EffectiveDateChanged(today));
    });
  }

  @override
  void dispose() {
    _carrierController.dispose();
    _typeController.dispose();
    _costController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      _dateController.text = formatted;
      context.read<CarrierRateCreateBloc>().add(
            EffectiveDateChanged(formatted),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: BlocListener<CarrierRateCreateBloc, CarrierRateCreateState>(
        listener: (listenerContext, state) {
          print('[CarrierRateCreateBloc] State changed: $state');
          if (state is CarrierRateCreateSuccess) {
            print('[CarrierRateCreateBloc] Success state detected');
            ScaffoldMessenger.of(listenerContext).showSnackBar(
              const SnackBar(content: Text('택배비가 추가되었습니다')),
            );
            context.read<CarrierRateListBloc>().add(FetchCarrierRates());
            Future.delayed(const Duration(milliseconds: 500), () {
              print('[CarrierRateCreateBloc] Calling onClose');
              widget.onClose();
            });
          } else if (state is CarrierRateCreateError) {
            print('[CarrierRateCreateBloc] Error state: ${state.message}');
            ScaffoldMessenger.of(listenerContext).showSnackBar(
              SnackBar(content: Text('오류: ${state.message}')),
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '택배비 추가',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error Message
                BlocBuilder<CarrierRateCreateBloc, CarrierRateCreateState>(
                  builder: (context, state) {
                    if (state is CarrierRateCreateError) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          state.message,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Carrier Field
                _buildTextField(
                  controller: _carrierController,
                  label: '배송사',
                  onChanged: (value) {
                    context.read<CarrierRateCreateBloc>().add(
                          CarrierChanged(value),
                        );
                  },
                ),
                const SizedBox(height: 12),

                // Type Field
                _buildTextField(
                  controller: _typeController,
                  label: '타입',
                  onChanged: (value) {
                    context.read<CarrierRateCreateBloc>().add(
                          TypeChanged(value),
                        );
                  },
                ),
                const SizedBox(height: 12),

                // Cost Field
                _buildTextField(
                  controller: _costController,
                  label: '비용',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    context.read<CarrierRateCreateBloc>().add(
                          CostChanged(value),
                        );
                  },
                ),
                const SizedBox(height: 12),

                // Date Field
                _buildDateField(context),
                const SizedBox(height: 12),

                // IsDefault Checkbox
                BlocBuilder<CarrierRateCreateBloc, CarrierRateCreateState>(
                  builder: (context, state) {
                    if (state is CarrierRateCreateInitial) {
                      return CheckboxListTile(
                        title: const Text('기본값'),
                        value: state.isDefault,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<CarrierRateCreateBloc>().add(
                                  IsDefaultChanged(value),
                                );
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                _buildButtonBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: '유효일',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () => _selectDate(context),
    );
  }

  Widget _buildButtonBar(BuildContext context) {
    return BlocBuilder<CarrierRateCreateBloc, CarrierRateCreateState>(
      builder: (context, state) {
        final isSubmitting =
            state is CarrierRateCreateInitial && state.isSubmitting;
        final isFormValid =
            state is CarrierRateCreateInitial && state.isValid;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isSubmitting ? null : widget.onClose,
              child: const Text('취소'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (isSubmitting || !isFormValid)
                  ? null
                  : () {
                      context.read<CarrierRateCreateBloc>().add(
                            CreateCarrierRateSubmitted(),
                          );
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('추가'),
            ),
          ],
        );
      },
    );
  }
}
