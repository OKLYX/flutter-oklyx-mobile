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

  void _showDeleteDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteConfirmationDialog(
        category: category,
        onConfirm: () {
          Navigator.pop(ctx);
          context
              .read<CategoryDetailBloc>()
              .add(DeleteCategoryRequested(category.id));
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
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
          listener: (context, state) {
            if (state is CategoryDetailSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('카테고리가 수정되었습니다.')),
              );
              setState(() => _isEditing = false);
              context.read<CategoryDetailBloc>().add(
                FetchCategoryRequested(categoryId: widget.categoryId),
              );
            } else if (state is CategoryDetailDeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('카테고리가 삭제되었습니다.')),
              );
              context.read<CategoryListBloc>().add(FetchCategoriesRequested());
              context.go(Routes.categoryListPath);
            } else if (state is CategoryDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<CategoryDetailBloc, CategoryDetailState>(
            builder: (context, state) {
              final bloc = context.read<CategoryDetailBloc>();
              if (state is CategoryDetailLoading) {
                return const Center(child: CircularProgressIndicator());
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => bloc.add(
                          FetchCategoryRequested(categoryId: widget.categoryId),
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
      return '${widget.category.category.parentId} (삭제됨?)';
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
      final categoryListBloc = GetIt.instance<CategoryListBloc>();
      return BlocBuilder<CategoryListBloc, CategoryListState>(
        bloc: categoryListBloc,
        builder: (context, state) {
          final List<Category> categories = state is CategoryListLoaded ? state.categories : [];
          final parentCategoryName = _getParentCategoryName(categories);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${widget.category.category.id}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => widget.onEditChange(true),
                            icon: const Icon(Icons.edit),
                            label: const Text('수정'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: widget.onDeletePressed,
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
                  _DetailField('카테고리명', widget.category.category.name),
                  _DetailField('플랫폼', widget.category.category.platform),
                  _DetailField('플랫폼 카테고리 ID', widget.category.category.platformCategoryId),
                  _DetailField('부모 카테고리', parentCategoryName),
                  _DetailField(
                    '생성일',
                    widget.category.category.createdDate.toString().split('.')[0],
                  ),
                  _DetailField(
                    '수정일',
                    widget.category.category.modifiedDate.toString().split('.')[0],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final categoryListBloc = GetIt.instance<CategoryListBloc>();
    return BlocBuilder<CategoryListBloc, CategoryListState>(
      bloc: categoryListBloc,
      builder: (context, listState) {
        final List<Category> categories = listState is CategoryListLoaded ? listState.categories : [];

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FormField(
                  '카테고리명',
                  _nameCtrl,
                  (v) => context.read<CategoryDetailBloc>().add(NameDetailChanged(v)),
                ),
                _FormField(
                  '플랫폼',
                  _platformCtrl,
                  (v) => context.read<CategoryDetailBloc>().add(PlatformDetailChanged(v)),
                ),
                _FormField(
                  '플랫폼 카테고리 ID',
                  _platformCategoryIdCtrl,
                  (v) => context.read<CategoryDetailBloc>().add(PlatformCategoryIdDetailChanged(v)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: '부모 카테고리',
                    border: OutlineInputBorder(),
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
                          child: ElevatedButton(
                            onPressed: () => widget.onEditChange(false),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading || !isEnabled
                                ? null
                                : () {
                                    context
                                        .read<CategoryDetailBloc>()
                                        .add(UpdateCategorySubmitted());
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('수정'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(String) onChanged;
  final TextInputType keyboardType;

  const _FormField(
    this.label,
    this.controller,
    this.onChanged, {
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
      ),
      onChanged: onChanged,
    ),
  );
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

class _DeleteConfirmationDialog extends StatelessWidget {
  final Category category;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.category,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('카테고리 삭제'),
      content:
          Text('${category.name}을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
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
