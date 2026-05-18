import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_state.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_event.dart';

/// Package Input Dialog
///
/// 상자비 추가 다이얼로그. "상자비 추가" 버튼 탭 시 표시됨.
///
/// 필수 속성:
/// - onClose: 다이얼로그 닫기 콜백
///
/// 사용 예:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (ctx) => PackageInputDialog(
///     onClose: () => Navigator.pop(context),
///   ),
/// );
/// ```
///
/// ⚠️ BLoC 접근: context.read<PackageCreateBloc>()
class PackageInputDialog extends StatefulWidget {
  final VoidCallback onClose;

  const PackageInputDialog({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<PackageInputDialog> createState() => _PackageInputDialogState();
}

class _PackageInputDialogState extends State<PackageInputDialog> {
  late TextEditingController _typeController;
  late TextEditingController _costController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController();
    _costController = TextEditingController();
    _dateController = TextEditingController();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dateController.text = today;
    Future.microtask(() {
      context.read<PackageCreateBloc>().add(PackageEffectiveDateChanged(today));
    });
  }

  @override
  void dispose() {
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
      context.read<PackageCreateBloc>().add(
        PackageEffectiveDateChanged(formatted),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: BlocListener<PackageCreateBloc, PackageCreateState>(
        listener: (context, state) {
          if (state is PackageCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('상자비가 추가되었습니다')),
            );
            context.read<PackageListBloc>().add(FetchPackages());
            context.read<PackageCreateBloc>().add(ResetCreateForm());
            Navigator.of(context).pop();
          } else if (state is PackageCreateError) {
            ScaffoldMessenger.of(context).showSnackBar(
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
                      '상자비 추가',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<PackageCreateBloc>().add(ResetCreateForm());
                        widget.onClose();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error Message
                BlocBuilder<PackageCreateBloc, PackageCreateState>(
                  builder: (context, state) {
                    if (state is PackageCreateError) {
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

                // Type Field
                _buildTextField(
                  controller: _typeController,
                  label: '패키지 타입',
                  onChanged: (value) {
                    context.read<PackageCreateBloc>().add(
                      PackageTypeChanged(value),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Cost Field (must be > 0)
                _buildTextField(
                  controller: _costController,
                  label: '비용',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    context.read<PackageCreateBloc>().add(
                      PackageCostChanged(value),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Date Field
                _buildDateField(context),
                const SizedBox(height: 12),

                // IsDefault Checkbox
                BlocBuilder<PackageCreateBloc, PackageCreateState>(
                  builder: (context, state) {
                    if (state is PackageCreateLoaded) {
                      return CheckboxListTile(
                        title: const Text('기본값'),
                        value: state.isDefault,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<PackageCreateBloc>().add(
                              PackageIsDefaultChanged(value),
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
    return BlocBuilder<PackageCreateBloc, PackageCreateState>(
      builder: (context, state) {
        final isCreating = state is PackageCreateLoading;
        final isFormValid = state is PackageCreateLoaded && state.isFormValid;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isCreating
                  ? null
                  : () {
                      context.read<PackageCreateBloc>().add(ResetCreateForm());
                      widget.onClose();
                    },
              child: const Text('취소'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (isCreating || !isFormValid)
                  ? null
                  : () {
                      context.read<PackageCreateBloc>().add(
                        CreatePackageRequested(),
                      );
                    },
              child: isCreating
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
