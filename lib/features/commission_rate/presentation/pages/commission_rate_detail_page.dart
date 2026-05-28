import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router/routes.dart';
import '../../../../shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/commission_rate_detail_bloc.dart';
import '../bloc/commission_rate_detail_event.dart';
import '../bloc/commission_rate_detail_state.dart';
import '../../domain/entities/commission_rate.dart';
import '../../../category/domain/entities/category.dart';
import '../bloc/commission_rate_list_bloc.dart';
import '../bloc/commission_rate_list_event.dart';

class CommissionRateDetailPage extends StatefulWidget {
  final int commissionRateId;
  const CommissionRateDetailPage({required this.commissionRateId});

  @override
  State<CommissionRateDetailPage> createState() => _CommissionRateDetailPageState();
}

class _CommissionRateDetailPageState extends State<CommissionRateDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<CommissionRateDetailBloc>().add(
      FetchCommissionRateDetail(widget.commissionRateId),
    );
  }

  void _showDeleteDialog(BuildContext context, CommissionRate rate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('수수료 삭제'),
        content: Text('${rate.platform} 수수료를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CommissionRateDetailBloc>().add(
                ConfirmDeleteCommissionRate(rate.id),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '수수료 정보',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () {
        final bloc = context.read<CommissionRateDetailBloc>();
        if (bloc.state is CommissionRateDetailEditing) {
          bloc.add(CancelEditing());
        } else {
          context.go(Routes.commissionRatePath);
        }
      },
      body: BlocListener<CommissionRateDetailBloc, CommissionRateDetailState>(
        listener: (context, state) {
          if (state is CommissionRateDetailUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수수료가 수정되었습니다')),
            );
            context.read<CommissionRateListBloc>().add(FetchCommissionRates());
            context.go(Routes.commissionRatePath);
          } else if (state is CommissionRateDetailDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수수료가 삭제되었습니다')),
            );
            context.read<CommissionRateListBloc>().add(FetchCommissionRates());
            context.go(Routes.commissionRatePath);
          } else if (state is CommissionRateDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CommissionRateDetailBloc, CommissionRateDetailState>(
          builder: (context, state) {
            final bloc = context.read<CommissionRateDetailBloc>();

            if (state is CommissionRateDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CommissionRateDetailLoaded) {
              return _CommissionRateDetailsView(
                rate: state.commissionRate,
                onEdit: () => bloc.add(StartEditingCommissionRate()),
                onDelete: () => _showDeleteDialog(context, state.commissionRate),
              );
            }

            if (state is CommissionRateDetailEditing) {
              return _CommissionRateEditForm(
                state: state,
                bloc: bloc,
              );
            }

            if (state is CommissionRateDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => bloc.add(
                        FetchCommissionRateDetail(widget.commissionRateId),
                      ),
                      child: const Text('재시도'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// 상세 정보 보기 모드
class _CommissionRateDetailsView extends StatelessWidget {
  final CommissionRate rate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommissionRateDetailsView({
    required this.rate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${rate.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('삭제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailField('플랫폼', rate.platform),
            _DetailField(
              '카테고리',
              rate.categoryName ?? '기본값',
            ),
            _DetailField(
              '수수료율',
              '${rate.rate.toStringAsFixed(4)}',
            ),
          ],
        ),
      ),
    );
  }
}

// DetailField 컴포넌트 (Package와 동일)
class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Divider(),
      ],
    ),
  );
}

// 편집 폼 (Page 내 inline)
class _CommissionRateEditForm extends StatefulWidget {
  final CommissionRateDetailEditing state;
  final CommissionRateDetailBloc bloc;

  const _CommissionRateEditForm({
    required this.state,
    required this.bloc,
  });

  @override
  State<_CommissionRateEditForm> createState() => _CommissionRateEditFormState();
}

class _CommissionRateEditFormState extends State<_CommissionRateEditForm> {
  late TextEditingController rateCtrl;

  @override
  void initState() {
    super.initState();
    rateCtrl = TextEditingController(
      text: (widget.state.editingData['rate'] as double).toStringAsFixed(4),
    );
  }

  @override
  void dispose() {
    rateCtrl.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    return widget.state.editingData['platform'] !=
            widget.state.originalCommissionRate.platform ||
        widget.state.editingData['categoryId'] !=
            widget.state.originalCommissionRate.categoryId ||
        widget.state.editingData['rate'] !=
            widget.state.originalCommissionRate.rate;
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        context.select<CommissionRateDetailBloc, bool>(
          (b) => b.state is CommissionRateDetailSubmitting,
        );
    final errors = widget.state.validationErrors;
    final hasChanges = _hasChanges();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormField(
              '플랫폼 (필수)',
              _buildPlatformDropdown(),
              errors['platform'],
            ),
            _FormField(
              '카테고리 (선택)',
              _buildCategoryDropdown(),
              errors['categoryId'],
            ),
            _FormField(
              '수수료율 (필수)',
              TextFormField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예: 0.089',
                  helperText: '0~1 범위의 소수 (예: 0.089 = 8.9%)',
                ),
                onChanged: (value) {
                  widget.bloc.add(RateChanged(value));
                },
              ),
              errors['rate'],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => widget.bloc.add(CancelEditing()),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: !hasChanges || isSubmitting
                      ? null
                      : () => widget.bloc.add(UpdateCommissionRateSubmitted()),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformDropdown() {
    return DropdownButtonFormField<String>(
      value: widget.state.editingData['platform'],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      items: CommissionRateDetailBloc.platforms.map((platform) {
        return DropdownMenuItem(value: platform, child: Text(platform));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          widget.bloc.add(PlatformChanged(value));
        }
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final filteredCategories = widget.state.availableCategories
        .where((cat) => cat.platform == widget.state.editingData['platform'])
        .toList();

    return DropdownButtonFormField<int>(
      value: widget.state.editingData['categoryId'],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('선택 안함')),
        ...filteredCategories.map((category) {
          return DropdownMenuItem(
            value: category.id,
            child: Text(category.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        widget.bloc.add(CategoryChanged(value));
      },
    );
  }
}

// FormField 래퍼 (에러 표시 포함)
class _FormField extends StatelessWidget {
  final String label;
  final Widget field;
  final String? error;

  const _FormField(this.label, this.field, this.error);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        field,
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    ),
  );
}
