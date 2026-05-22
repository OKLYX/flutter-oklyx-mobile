import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class CategoryDetailPage extends StatelessWidget {
  final int categoryId;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '카테고리 상세',
      navBarIndex: 2,
      onBackPressed: () => context.go(Routes.categoryListPath),
      body: BlocListener<CategoryDetailBloc, CategoryDetailState>(
        listener: (context, state) {
          if (state is CategoryDetailDeleteSuccess) {
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
              return _CategoryDetailsView(
                category: state.category,
                onDeletePressed: () =>
                    _showDeleteDialog(context, state.category),
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
                        FetchCategoryRequested(categoryId: categoryId),
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
}

class _CategoryDetailsView extends StatelessWidget {
  final Category category;
  final VoidCallback onDeletePressed;

  const _CategoryDetailsView({
    required this.category,
    required this.onDeletePressed,
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
                  'ID: ${category.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to edit page (Phase 05)
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onDeletePressed,
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
            _DetailField('카테고리명', category.name),
            _DetailField('플랫폼', category.platform),
            _DetailField(
              '생성일',
              category.createdDate.toString().split('.')[0],
            ),
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
