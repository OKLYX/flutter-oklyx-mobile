import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_form_field.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

class CategoryDetailPage extends StatefulWidget {
  final int categoryId;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  bool _isEditing = false;
  CategoryDetailLoaded? _lastLoadedState;

  Future<void> _showDeleteDialog(BuildContext context, Category category) async {
    final ok = await showAppConfirmDialog(
      context,
      title: '카테고리 삭제',
      message: '${category.name}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (!ok || !context.mounted) {
      return;
    }
    context
        .read<CategoryDetailBloc>()
        .add(DeleteCategoryRequested(category.id));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '카테고리 정보',
      navBarIndex: 2,
      onBackPressed: () {
        if (_isEditing) {
          setState(() => _isEditing = false);
        } else {
          context.go(Routes.categoryListPath);
        }
      },
      body: BlocListener<CategoryDetailBloc, CategoryDetailState>(
          listenWhen: (previous, current) =>
              current is CategoryDetailSuccess ||
              current is CategoryDetailDeleteSuccess ||
              current is CategoryDetailError,
          listener: (context, state) {
            if (state is CategoryDetailSuccess) {
              showSuccessToast(context, '카테고리가 수정되었습니다.');
              setState(() => _isEditing = false);
              context.read<CategoryDetailBloc>().add(
                FetchCategoryRequested(categoryId: widget.categoryId),
              );
            } else if (state is CategoryDetailDeleteSuccess) {
              showSuccessToast(context, '카테고리가 삭제되었습니다.');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  GetIt.instance<CategoryListBloc>().add(FetchCategoriesRequested());
                  context.pop();
                }
              });
            } else if (state is CategoryDetailError) {
              showErrorToast(context, state.message);
            }
          },
          child: BlocBuilder<CategoryDetailBloc, CategoryDetailState>(
            builder: (context, state) {
              final bloc = context.read<CategoryDetailBloc>();
              if (state is CategoryDetailLoading) {
                return const AppPageBody(children: [AppLoading()]);
              }
              if (state is CategoryDetailLoaded) {
                _lastLoadedState = state;
                return _CategoryDetailsView(
                  category: state,
                  isEditing: _isEditing,
                  onEditChange: (editing) => setState(() => _isEditing = editing),
                  onDeletePressed: () {
                    final cat = Category(
                      id: state.category.id,
                      name: state.category.name,
                      platform: state.category.platform,
                      platformCategoryId: state.category.platformCategoryId,
                      parentId: state.category.parentId,
                      createdDate: state.category.createdDate,
                      modifiedDate: state.category.modifiedDate,
                    );
                    _showDeleteDialog(context, cat);
                  },
                );
              }
              if (state is CategoryDetailSuccess && _lastLoadedState != null) {
                return _CategoryDetailsView(
                  category: _lastLoadedState!,
                  isEditing: _isEditing,
                  onEditChange: (editing) => setState(() => _isEditing = editing),
                  onDeletePressed: () {
                    final cat = Category(
                      id: _lastLoadedState!.category.id,
                      name: _lastLoadedState!.category.name,
                      platform: _lastLoadedState!.category.platform,
                      platformCategoryId: _lastLoadedState!.category.platformCategoryId,
                      parentId: _lastLoadedState!.category.parentId,
                      createdDate: _lastLoadedState!.category.createdDate,
                      modifiedDate: _lastLoadedState!.category.modifiedDate,
                    );
                    _showDeleteDialog(context, cat);
                  },
                );
              }
              if (state is CategoryDetailError) {
                return AppPageBody(
                  children: [
                    AppErrorBox(
                      message: state.message,
                      action: FilledButton(
                        onPressed: () => bloc.add(
                          FetchCategoryRequested(categoryId: widget.categoryId),
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

class _CategoryDetailsView extends StatefulWidget {
  final CategoryDetailLoaded category;
  final bool isEditing;
  final Function(bool) onEditChange;
  final VoidCallback onDeletePressed;

  const _CategoryDetailsView({
    required this.category,
    required this.isEditing,
    required this.onEditChange,
    required this.onDeletePressed,
  });

  @override
  State<_CategoryDetailsView> createState() => _CategoryDetailsViewState();
}

class _CategoryDetailsViewState extends State<_CategoryDetailsView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _platformCtrl;
  late TextEditingController _platformCategoryIdCtrl;
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.editName);
    _platformCtrl = TextEditingController(text: widget.category.editPlatform);
    _platformCategoryIdCtrl = TextEditingController(text: widget.category.editPlatformCategoryId);
    _selectedParentId = widget.category.category.parentId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _platformCtrl.dispose();
    _platformCategoryIdCtrl.dispose();
    super.dispose();
  }

  String _getParentCategoryName(List<Category> categories) {
    if (widget.category.category.parentId == null) {
      return '없음';
    }
    try {
      final parent = categories.firstWhere(
        (cat) => cat.id == widget.category.category.parentId,
      );
      return parent.name;
    } catch (e) {
      return '(삭제됨 - ID: ${widget.category.category.parentId})';
    }
  }

  bool _isValid() {
    final nameValid = _nameCtrl.text.isNotEmpty && _nameCtrl.text.length <= 100;
    final platformValid = _platformCtrl.text.isNotEmpty && _platformCtrl.text.length <= 50;
    final platformCategoryIdValid = _platformCategoryIdCtrl.text.isNotEmpty &&
                                   _platformCategoryIdCtrl.text.length <= 50;

    return nameValid && platformValid && platformCategoryIdValid;
  }

  bool _isChanged() {
    return _nameCtrl.text != widget.category.category.name ||
        _platformCtrl.text != widget.category.category.platform ||
        _platformCategoryIdCtrl.text != widget.category.category.platformCategoryId ||
        _selectedParentId != widget.category.category.parentId;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) {
      return BlocBuilder<CategoryListBloc, CategoryListState>(
        builder: (context, state) {
          final List<Category> categories = state is CategoryListLoaded ? state.categories : [];
          final parentCategoryName = _getParentCategoryName(categories);

          return AppPageBody.scroll(
            child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${widget.category.category.id}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () => widget.onEditChange(true),
                            icon: const Icon(Icons.edit),
                            label: const Text('수정'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: widget.onDeletePressed,
                            icon: const Icon(Icons.delete),
                            label: const Text('삭제'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppDetailField('카테고리명', widget.category.category.name),
                  AppDetailField('플랫폼', widget.category.category.platform),
                  AppDetailField('플랫폼 카테고리 ID', widget.category.category.platformCategoryId),
                  AppDetailField('부모 카테고리', parentCategoryName),
                  AppDetailField(
                    '생성일',
                    widget.category.category.createdDate.toString().split('.')[0],
                  ),
                  AppDetailField(
                    '수정일',
                    widget.category.category.modifiedDate.toString().split('.')[0],
                  ),
                ],
              ),
          );
        },
      );
    }

    return BlocBuilder<CategoryListBloc, CategoryListState>(
      builder: (context, listState) {
        final List<Category> categories = listState is CategoryListLoaded ? listState.categories : [];

        return AppPageBody.scroll(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormField(
                  '카테고리명',
                  _nameCtrl,
                  (v) => context.read<CategoryDetailBloc>().add(NameDetailChanged(v)),
                ),
                AppFormField(
                  '플랫폼',
                  _platformCtrl,
                  (v) => context.read<CategoryDetailBloc>().add(PlatformDetailChanged(v)),
                ),
                AppFormField(
                  '플랫폼 카테고리 ID',
                  _platformCategoryIdCtrl,
                  (v) => context.read<CategoryDetailBloc>().add(PlatformCategoryIdDetailChanged(v)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: '부모 카테고리',
                  ),
                  value: _selectedParentId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('선택 안함 (최상위)'),
                    ),
                    ...categories
                        .where((cat) => cat.id != widget.category.category.id)
                        .map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedParentId = value);
                    final parentIdStr = value?.toString() ?? '';
                    context
                        .read<CategoryDetailBloc>()
                        .add(ParentIdDetailChanged(parentIdStr));
                  },
                ),
                const SizedBox(height: 24),
                BlocBuilder<CategoryDetailBloc, CategoryDetailState>(
                  builder: (context, state) {
                    final isLoading = state is CategoryDetailLoading;
                    final isEnabled = _isValid() && _isChanged();

                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => widget.onEditChange(false),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isLoading || !isEnabled
                                ? null
                                : () {
                                    context
                                        .read<CategoryDetailBloc>()
                                        .add(UpdateCategorySubmitted());
                                  },
                            child: isLoading
                                ? const AppBusyLabel('수정')
                                : const Text('수정'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
        );
      },
    );
  }
}
