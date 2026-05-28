import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/commission_rate_create_bloc.dart';
import '../bloc/commission_rate_create_event.dart';
import '../bloc/commission_rate_create_state.dart';
import '../bloc/commission_rate_list_bloc.dart';
import '../bloc/commission_rate_list_event.dart';

class CommissionRateInputDialog extends StatefulWidget {
  final VoidCallback onClose;

  const CommissionRateInputDialog({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CommissionRateInputDialog> createState() => _CommissionRateInputDialogState();
}

void showCreateCommissionRateDialog(BuildContext context) {
  context.read<CommissionRateCreateBloc>().add(ResetCreateForm());

  showDialog(
    context: context,
    builder: (ctx) => MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: context.read<CommissionRateCreateBloc>(),
        ),
        BlocProvider.value(
          value: context.read<CommissionRateListBloc>(),
        ),
      ],
      child: CommissionRateInputDialog(
        onClose: () => Navigator.pop(context),
      ),
    ),
  );
}

class _CommissionRateInputDialogState extends State<CommissionRateInputDialog> {
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: BlocListener<CommissionRateCreateBloc, CommissionRateCreateState>(
        listener: (listenerContext, state) {
          if (state is CommissionRateCreateSuccess) {
            ScaffoldMessenger.of(listenerContext).showSnackBar(
              const SnackBar(content: Text('수수료가 추가되었습니다')),
            );
            context.read<CommissionRateListBloc>().add(FetchCommissionRates());
            widget.onClose();
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('수수료 추가', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    context.read<CommissionRateCreateBloc>().add(ResetCreateForm());
                    widget.onClose();
                  },
                ),
              ]),
              const SizedBox(height: 16),
              BlocBuilder<CommissionRateCreateBloc, CommissionRateCreateState>(
                builder: (context, state) {
                  if (state is CommissionRateCreateError) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(state.message, style: TextStyle(color: Colors.red.shade700)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              _buildPlatformDropdown(context),
              const SizedBox(height: 12),
              _buildCategoryDropdown(context),
              const SizedBox(height: 12),
              _buildRateField(),
              const SizedBox(height: 24),
              _buildButtonBar(context),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformDropdown(BuildContext context) {
    return BlocBuilder<CommissionRateCreateBloc, CommissionRateCreateState>(
      builder: (context, state) {
        if (state is! CommissionRateCreateInitial) return const SizedBox.shrink();

        return DropdownButtonFormField<String>(
          value: state.platform.isEmpty ? null : state.platform,
          decoration: InputDecoration(
            labelText: 'Platform (필수)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: CommissionRateCreateBloc.platforms.map((platform) {
            return DropdownMenuItem(value: platform, child: Text(platform));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<CommissionRateCreateBloc>().add(PlatformSelected(value));
            }
          },
        );
      },
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return BlocBuilder<CommissionRateCreateBloc, CommissionRateCreateState>(
      builder: (context, state) {
        if (state is! CommissionRateCreateInitial) return const SizedBox.shrink();

        if (state.platform.isEmpty) {
          return DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Category (선택)',
              hintText: '플랫폼을 먼저 선택해주세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [],
            onChanged: null,
          );
        }

        if (state.isLoadingCategories) {
          return Container(
            height: 55,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return DropdownButtonFormField<int>(
          value: state.selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Category (선택)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('선택 안함')),
            ...state.availableCategories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<CommissionRateCreateBloc>().add(CategorySelected(value));
            } else {
              context.read<CommissionRateCreateBloc>().add(CategorySelected(-1));
            }
          },
        );
      },
    );
  }

  Widget _buildRateField() {
    return TextField(
      controller: _rateController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Rate (필수)',
        hintText: '예) 5.5, 15.0 (0~100)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        context.read<CommissionRateCreateBloc>().add(RateChanged(value));
      },
    );
  }

  Widget _buildButtonBar(BuildContext context) {
    return BlocBuilder<CommissionRateCreateBloc, CommissionRateCreateState>(
      builder: (context, state) {
        if (state is! CommissionRateCreateInitial) return const SizedBox.shrink();

        final isSubmitting = false;
        final isValid = state.isValid && state.platform.isNotEmpty;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                context.read<CommissionRateCreateBloc>().add(ResetCreateForm());
                widget.onClose();
              },
              child: const Text('취소'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: !isValid
                  ? null
                  : () {
                      final rate = double.tryParse(_rateController.text) ?? 0.0;
                      context.read<CommissionRateCreateBloc>().add(
                        CreateCommissionRateSubmitted(
                          platform: state.platform,
                          categoryId: state.selectedCategoryId == -1
                              ? null
                              : state.selectedCategoryId,
                          rate: rate / 100.0,
                        ),
                      );
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ],
        );
      },
    );
  }
}
