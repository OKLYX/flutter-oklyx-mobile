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
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_form_field.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

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

  Future<void> _showDeleteDialog(BuildContext context, CommissionRate rate) async {
    final ok = await showAppConfirmDialog(
      context,
      title: '수수료 삭제',
      message: '${rate.platform} 수수료를 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (!ok || !context.mounted) {
      return;
    }
    context.read<CommissionRateDetailBloc>().add(
      ConfirmDeleteCommissionRate(rate.id),
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
            showSuccessToast(context, '수수료가 수정되었습니다');
            context.read<CommissionRateListBloc>().add(FetchCommissionRates());
            context.go(Routes.commissionRatePath);
          } else if (state is CommissionRateDetailDeleteSuccess) {
            showSuccessToast(context, '수수료가 삭제되었습니다');
            context.read<CommissionRateListBloc>().add(FetchCommissionRates());
            context.go(Routes.commissionRatePath);
          } else if (state is CommissionRateDetailError) {
            showErrorToast(context, state.message);
          }
        },
        child: BlocBuilder<CommissionRateDetailBloc, CommissionRateDetailState>(
          builder: (context, state) {
            final bloc = context.read<CommissionRateDetailBloc>();

            if (state is CommissionRateDetailLoading) {
              return const AppPageBody(children: [AppLoading()]);
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
              return AppPageBody(
                children: [
                  AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () => bloc.add(
                        FetchCommissionRateDetail(widget.commissionRateId),
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
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
    return AppPageBody.scroll(
      child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${rate.id}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('삭제'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppDetailField('플랫폼', rate.platform),
            AppDetailField(
              '카테고리',
              rate.categoryName ?? '기본값',
            ),
            AppDetailField(
              '수수료율',
              '${rate.rate.toStringAsFixed(4)}',
            ),
          ],
        ),
    );
  }
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

    return AppPageBody.scroll(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPlatformDropdown(errors['platform']),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCategoryDropdown(errors['categoryId']),
            ),
            AppFormField(
              '수수료율 (필수)',
              rateCtrl,
              (value) {
                widget.bloc.add(RateChanged(value));
              },
              error: errors['rate'],
              keyboardType: TextInputType.number,
              hintText: '예: 0.089',
              helperText: '0~1 범위의 소수 (예: 0.089 = 8.9%)',
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
                FilledButton(
                  onPressed: !hasChanges || isSubmitting
                      ? null
                      : () => widget.bloc.add(UpdateCommissionRateSubmitted()),
                  child: isSubmitting
                      ? const AppBusyLabel('저장')
                      : const Text('저장'),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildPlatformDropdown(String? error) {
    return DropdownButtonFormField<String>(
      value: widget.state.editingData['platform'],
      decoration: InputDecoration(
        labelText: '플랫폼 (필수)',
        errorText: error,
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

  Widget _buildCategoryDropdown(String? error) {
    final filteredCategories = widget.state.availableCategories
        .where((cat) => cat.platform == widget.state.editingData['platform'])
        .toList();

    return DropdownButtonFormField<int>(
      value: widget.state.editingData['categoryId'],
      decoration: InputDecoration(
        labelText: '카테고리 (선택)',
        errorText: error,
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
