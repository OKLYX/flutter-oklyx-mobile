import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/carrier_rate_detail_bloc.dart';
import '../bloc/carrier_rate_detail_event.dart';
import '../bloc/carrier_rate_detail_state.dart';
import '../bloc/carrier_rate_list_bloc.dart';
import '../bloc/carrier_rate_list_event.dart';

/// Carrier Rate Detail Dialog
///
/// 택배비 수정 다이얼로그. 리스트 아이템 탭 시 표시됨.
///
/// 필수 속성:
/// - id: 택배비 ID
/// - onClose: 다이얼로그 닫기 콜백
///
/// 사용 예:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (ctx) => MultiBlocProvider(
///     providers: [
///       BlocProvider.value(value: context.read<CarrierRateDetailBloc>()),
///       BlocProvider.value(value: context.read<CarrierRateListBloc>()),
///     ],
///     child: CarrierRateDetailDialog(
///       id: 1,
///       onClose: () => Navigator.pop(context),
///     ),
///   ),
/// );
/// ```
///
/// ⚠️ BLoC 접근: context.read<CarrierRateDetailBloc>()
class CarrierRateDetailDialog extends StatefulWidget {
  final int id;
  final VoidCallback onClose;

  const CarrierRateDetailDialog({
    Key? key,
    required this.id,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CarrierRateDetailDialog> createState() => _CarrierRateDetailDialogState();
}

void showEditCarrierRateDialog(BuildContext context, int id) {
  final detailBloc = context.read<CarrierRateDetailBloc>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: detailBloc),
        BlocProvider.value(value: context.read<CarrierRateListBloc>()),
      ],
      child: BlocBuilder<CarrierRateDetailBloc, CarrierRateDetailState>(
        builder: (context, state) {
          if (state is! CarrierRateDetailLoaded) {
            // Show full-screen loading (matching Package detail page)
            return const Center(child: CircularProgressIndicator());
          }

          // Show actual detail form once loaded
          return CarrierRateDetailDialog(
            id: id,
            onClose: () => Navigator.pop(context),
          );
        },
      ),
    ),
  );

  // Trigger fetch after dialog is shown
  detailBloc.add(FetchCarrierRateDetail(id));
}


class _CarrierRateDetailDialogState extends State<CarrierRateDetailDialog> {
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
      context.read<CarrierRateDetailBloc>().add(
            EffectiveDateDetailChanged(formatted),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: BlocListener<CarrierRateDetailBloc, CarrierRateDetailState>(
        listener: (listenerContext, state) {
          print('[CarrierRateDetailBloc] State changed: $state');
          if (state is CarrierRateDetailSuccess) {
            print('[CarrierRateDetailBloc] Success state detected');
            ScaffoldMessenger.of(listenerContext).showSnackBar(
              const SnackBar(content: Text('택배비가 수정되었습니다')),
            );
            context.read<CarrierRateListBloc>().add(FetchCarrierRates());
            Future.delayed(const Duration(milliseconds: 500), () {
              print('[CarrierRateDetailBloc] Calling onClose');
              widget.onClose();
            });
          } else if (state is CarrierRateDetailError) {
            print('[CarrierRateDetailBloc] Error state: ${state.message}');
            ScaffoldMessenger.of(listenerContext).showSnackBar(
              SnackBar(content: Text('오류: ${state.message}')),
            );
          }
        },
        child: BlocBuilder<CarrierRateDetailBloc, CarrierRateDetailState>(
          builder: (context, state) {
            if (state is! CarrierRateDetailLoaded) {
              return const SizedBox.shrink();
            }

            // Update controllers when state loads
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _carrierController.text = state.carrier.value;
              _typeController.text = state.type.value;
              _costController.text = state.cost.value.toStringAsFixed(0);
              _dateController.text = state.effectiveDate.value;
            });

            return SingleChildScrollView(
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
                          '택배비 수정',
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
                    if (state.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          state.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),

                    // Carrier Field
                    _buildTextField(
                      controller: _carrierController,
                      label: '배송사',
                      onChanged: (value) {
                        context.read<CarrierRateDetailBloc>().add(
                              CarrierDetailChanged(value),
                            );
                      },
                      enabled: !state.isSubmitting,
                    ),
                    const SizedBox(height: 12),

                    // Type Field
                    _buildTextField(
                      controller: _typeController,
                      label: '타입',
                      onChanged: (value) {
                        context.read<CarrierRateDetailBloc>().add(
                              TypeDetailChanged(value),
                            );
                      },
                      enabled: !state.isSubmitting,
                    ),
                    const SizedBox(height: 12),

                    // Cost Field
                    _buildTextField(
                      controller: _costController,
                      label: '비용',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        context.read<CarrierRateDetailBloc>().add(
                              CostDetailChanged(value),
                            );
                      },
                      enabled: !state.isSubmitting,
                    ),
                    const SizedBox(height: 12),

                    // Date Field
                    _buildDateField(context, state.isSubmitting),
                    const SizedBox(height: 12),

                    // IsDefault Checkbox
                    CheckboxListTile(
                      title: const Text('기본값'),
                      value: state.isDefault,
                      onChanged: !state.isSubmitting
                          ? (value) {
                              if (value != null) {
                                context.read<CarrierRateDetailBloc>().add(
                                      IsDefaultDetailChanged(value),
                                    );
                              }
                            }
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    _buildButtonBar(context, state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField(BuildContext context, bool isSubmitting) {
    return TextField(
      controller: _dateController,
      readOnly: true,
      enabled: !isSubmitting,
      decoration: InputDecoration(
        labelText: '유효일',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: !isSubmitting ? () => _selectDate(context) : null,
    );
  }

  Widget _buildButtonBar(
    BuildContext context,
    CarrierRateDetailLoaded state,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: state.isSubmitting ? null : widget.onClose,
          child: const Text('취소'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: (state.isSubmitting || !state.isValid)
              ? null
              : () {
                  context.read<CarrierRateDetailBloc>().add(
                        UpdateCarrierRateSubmitted(widget.id),
                      );
                },
          child: state.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('수정'),
        ),
      ],
    );
  }
}
