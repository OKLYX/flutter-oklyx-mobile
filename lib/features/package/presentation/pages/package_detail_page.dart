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
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('상자비가 수정되었습니다.')),
            );
            context.read<PackageListBloc>().add(FetchPackages());
            context.go(Routes.packageSearchPath);
          } else if (state is PackageDetailDeleteSuccess) {
            context.go(Routes.packageSearchPath);
          } else if (state is PackageDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<PackageDetailBloc, PackageDetailState>(
          builder: (context, state) {
            final bloc = context.read<PackageDetailBloc>();
            if (state is PackageDetailLoading) {
              return const Center(child: CircularProgressIndicator());
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => bloc.add(LoadPackageDetail(packageId)),
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

class _PackageDetailsView extends StatelessWidget {
  final Package package;
  final VoidCallback onEdit;
  const _PackageDetailsView({required this.package, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('###,##0', 'ko_KR');
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${package.id}',
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
                      onPressed: () => _showDeleteDialog(context, package),
                      icon: const Icon(Icons.delete),
                      label: const Text('삭제'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailField('상자 유형', package.type),
            _DetailField('비용', '${fmt.format(package.cost)}원'),
            _DetailField('유효일', package.effectiveDate),
            _DetailField('기본값', package.isDefault ? '예' : '아니오'),
          ],
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label, value;
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

class _PackageEditForm extends StatefulWidget {
  final PackageDetailEditing state;
  final PackageDetailBloc bloc;
  const _PackageEditForm({required this.state, required this.bloc});

  @override
  State<_PackageEditForm> createState() => _PackageEditFormState();
}

class _PackageEditFormState extends State<_PackageEditForm> {
  late TextEditingController typeCtrl, costCtrl, dateCtrl;

  @override
  void initState() {
    super.initState();
    typeCtrl = TextEditingController(text: widget.state.editingData['type']);
    costCtrl = TextEditingController(text: widget.state.editingData['cost'].toInt().toString());
    dateCtrl = TextEditingController(text: widget.state.editingData['effectiveDate']);
  }

  @override
  void dispose() {
    typeCtrl.dispose();
    costCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    return widget.state.editingData['type'] != widget.state.originalPackage.type ||
        widget.state.editingData['cost'] != widget.state.originalPackage.cost ||
        widget.state.editingData['effectiveDate'] != widget.state.originalPackage.effectiveDate ||
        widget.state.editingData['isDefault'] != widget.state.originalPackage.isDefault;
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<PackageDetailBloc, bool>(
      (b) => b.state is PackageDetailSubmitting,
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
              '상자 유형',
              typeCtrl,
              (v) => widget.bloc.add(UpdateFormField(field: 'type', value: v)),
              errors['type'],
            ),
            _FormField(
              '비용',
              costCtrl,
              (v) => widget.bloc.add(UpdateFormField(field: 'cost', value: double.tryParse(v) ?? 0)),
              errors['cost'],
              keyboardType: TextInputType.number,
            ),
            _FormField(
              '유효일 (YYYY-MM-DD)',
              dateCtrl,
              (v) => widget.bloc.add(UpdateFormField(field: 'effectiveDate', value: v)),
              errors['effectiveDate'],
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
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () => context.go(Routes.packageSearchPath),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isSubmitting || !hasChanges) ? null : () => widget.bloc.add(SubmitPackageUpdate()),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('수정'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? error;
  final TextInputType keyboardType;

  const _FormField(
    this.label,
    this.controller,
    this.onChanged,
    this.error, {
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: error,
      ),
      onChanged: onChanged,
    ),
  );
}

void _showDeleteDialog(BuildContext context, Package package) {
  showDialog(
    context: context,
    builder: (ctx) => _DeleteConfirmationDialog(
      package: package,
      onConfirm: () {
        Navigator.pop(ctx);
        context.read<PackageDetailBloc>().add(ConfirmDeletePackage());
      },
      onCancel: () => Navigator.pop(ctx),
    ),
  );
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final Package package;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _DeleteConfirmationDialog({
    required this.package,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('상자비 삭제'),
      content: Text('${package.type}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}
