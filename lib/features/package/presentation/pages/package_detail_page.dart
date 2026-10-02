import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_event.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_form_field.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

class PackageDetailPage extends StatelessWidget {
  final int packageId;
  const PackageDetailPage({required this.packageId});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '상자비 정보',
      navBarIndex: 2,
      onBackPressed: () => context.go(Routes.packageSearchPath),
      body: BlocListener<PackageDetailBloc, PackageDetailState>(
        listener: (context, state) {
          if (state is PackageDetailUpdateSuccess) {
            showSuccessToast(context, '상자비가 수정되었습니다.');
            context.read<PackageListBloc>().add(FetchPackages());
            context.go(Routes.packageSearchPath);
          } else if (state is PackageDetailDeleteSuccess) {
            context.go(Routes.packageSearchPath);
          } else if (state is PackageDetailError) {
            showErrorToast(context, state.message);
          }
        },
        child: BlocBuilder<PackageDetailBloc, PackageDetailState>(
          builder: (context, state) {
            final bloc = context.read<PackageDetailBloc>();
            if (state is PackageDetailLoading) {
              return const AppPageBody(children: [AppLoading()]);
            }
            if (state is PackageDetailLoaded) {
              return _PackageDetailsView(
                package: state.package,
                onEdit: () => bloc.add(StartEditingPackage()),
              );
            }
            if (state is PackageDetailEditing) {
              return _PackageEditForm(state: state, bloc: bloc);
            }
            if (state is PackageDetailError) {
              return AppPageBody(
                children: [
                  AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () => bloc.add(LoadPackageDetail(packageId)),
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

class _PackageDetailsView extends StatelessWidget {
  final Package package;
  final VoidCallback onEdit;
  const _PackageDetailsView({required this.package, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('###,##0', 'ko_KR');
    return AppPageBody.scroll(
      child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${package.id}',
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
                      onPressed: () => _showDeleteDialog(context, package),
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
            AppDetailField('상자 유형', package.type),
            AppDetailField('비용', '${fmt.format(package.cost)}원'),
            AppDetailField('사이즈', package.sizeLabel),
            AppDetailField('기본값', package.isDefault ? '예' : '아니오'),
          ],
        ),
    );
  }
}

class _PackageEditForm extends StatefulWidget {
  final PackageDetailEditing state;
  final PackageDetailBloc bloc;
  const _PackageEditForm({required this.state, required this.bloc});

  @override
  State<_PackageEditForm> createState() => _PackageEditFormState();
}

class _PackageEditFormState extends State<_PackageEditForm> {
  late TextEditingController typeCtrl, costCtrl;
  late TextEditingController widthCtrl, lengthCtrl, heightCtrl;

  @override
  void initState() {
    super.initState();
    typeCtrl = TextEditingController(text: widget.state.editingData['type']);
    costCtrl = TextEditingController(text: widget.state.editingData['cost'].toInt().toString());
    // 미지정(0) 상자는 빈 칸으로 연다 — 0 이 남아 있으면 지우고 다시 쳐야 한다
    // (PLAN 2609_38 D4).
    widthCtrl = TextEditingController(text: _sizeText('widthCm'));
    lengthCtrl = TextEditingController(text: _sizeText('lengthCm'));
    heightCtrl = TextEditingController(text: _sizeText('heightCm'));
  }

  String _sizeText(String field) {
    final value = widget.state.editingData[field] as double;
    return value == 0 ? '' : value.toString();
  }

  @override
  void dispose() {
    typeCtrl.dispose();
    costCtrl.dispose();
    widthCtrl.dispose();
    lengthCtrl.dispose();
    heightCtrl.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    return widget.state.editingData['type'] != widget.state.originalPackage.type ||
        widget.state.editingData['cost'] != widget.state.originalPackage.cost ||
        widget.state.editingData['isDefault'] != widget.state.originalPackage.isDefault ||
        widget.state.editingData['widthCm'] !=
            widget.state.originalPackage.widthCm ||
        widget.state.editingData['lengthCm'] !=
            widget.state.originalPackage.lengthCm ||
        widget.state.editingData['heightCm'] !=
            widget.state.originalPackage.heightCm;
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<PackageDetailBloc, bool>(
      (b) => b.state is PackageDetailSubmitting,
    );
    final errors = widget.state.validationErrors;
    final hasChanges = _hasChanges();

    return AppPageBody.scroll(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormField(
              '상자 유형',
              typeCtrl,
              (v) => widget.bloc.add(UpdateFormField(field: 'type', value: v)),
              error: errors['type'],
            ),
            AppFormField(
              '비용',
              costCtrl,
              (v) => widget.bloc.add(UpdateFormField(field: 'cost', value: double.tryParse(v) ?? 0)),
              error: errors['cost'],
              keyboardType: TextInputType.number,
            ),
            if (widget.state.originalPackage.isSizeUnset)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '사이즈가 등록되지 않은 상자입니다. 값을 입력해야 저장할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warningForeground,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: AppFormField(
                    '가로(cm)',
                    widthCtrl,
                    (v) => widget.bloc.add(
                      UpdateFormField(
                        field: 'widthCm',
                        value: double.tryParse(v) ?? 0,
                      ),
                    ),
                    error: errors['widthCm'],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppFormField(
                    '세로(cm)',
                    lengthCtrl,
                    (v) => widget.bloc.add(
                      UpdateFormField(
                        field: 'lengthCm',
                        value: double.tryParse(v) ?? 0,
                      ),
                    ),
                    error: errors['lengthCm'],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppFormField(
                    '높이(cm)',
                    heightCtrl,
                    (v) => widget.bloc.add(
                      UpdateFormField(
                        field: 'heightCm',
                        value: double.tryParse(v) ?? 0,
                      ),
                    ),
                    error: errors['heightCm'],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              enabled: !isSubmitting,
              title: const Text('기본값으로 설정'),
              value: widget.state.editingData['isDefault'] ?? false,
              onChanged: !isSubmitting
                  ? (v) => widget.bloc.add(UpdateFormField(field: 'isDefault', value: v ?? false))
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isSubmitting ? null : () => context.go(Routes.packageSearchPath),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (isSubmitting || !hasChanges) ? null : () => widget.bloc.add(SubmitPackageUpdate()),
                    child: isSubmitting
                        ? const AppBusyLabel('수정')
                        : const Text('수정'),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

Future<void> _showDeleteDialog(BuildContext context, Package package) async {
  final ok = await showAppConfirmDialog(
    context,
    title: '상자비 삭제',
    message: '${package.type}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
    confirmText: '삭제',
    isDangerous: true,
  );
  if (!ok || !context.mounted) {
    return;
  }
  context.read<PackageDetailBloc>().add(ConfirmDeletePackage());
}
