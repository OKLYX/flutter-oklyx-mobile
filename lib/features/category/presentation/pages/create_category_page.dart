import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_state.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/create_category_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/create_category_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/create_category_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class CreateCategoryPage extends StatefulWidget {
  const CreateCategoryPage({super.key});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _platformController;
  late final TextEditingController _platformCategoryIdController;

  String _selectedPlatform = '';
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _platformController = TextEditingController();
    _platformCategoryIdController = TextEditingController();
    context.read<CategoryListBloc>().add(FetchCategoriesRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _platformController.dispose();
    _platformCategoryIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '카테고리 추가',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.pop(),
      body: BlocListener<CreateCategoryBloc, CreateCategoryState>(
        listener: (context, state) {
          if (state is CreateCategorySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('카테고리가 추가되었습니다.')),
            );
            context.pop(true);
          } else if (state is CreateCategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('오류: ${state.message}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '카테고리 정보',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '카테고리명 *',
                  hintText: '카테고리 이름을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                onChanged: (value) {
                  context
                      .read<CreateCategoryBloc>()
                      .add(CreateCategoryNameChanged(name: value));
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '플랫폼 *',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPlatform.isEmpty ? null : _selectedPlatform,
                items: ['COUPANG', 'GMARKET', 'AUCTION', 'SMARTSTORE']
                    .map((platform) => DropdownMenuItem(
                          value: platform,
                          child: Text(platform),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedPlatform = value ?? '');
                  context
                      .read<CreateCategoryBloc>()
                      .add(CreateCategoryPlatformChanged(platform: value ?? ''));
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _platformCategoryIdController,
                decoration: const InputDecoration(
                  labelText: '플랫폼 카테고리 ID *',
                  hintText: '예: cat_001',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                onChanged: (value) {
                  context
                      .read<CreateCategoryBloc>()
                      .add(CreateCategoryIdChanged(platformCategoryId: value));
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<CategoryListBloc, CategoryListState>(
                builder: (context, state) {
                  final categories = state is CategoryListLoaded ? state.categories : [];

                  return DropdownButtonFormField<int?>(
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
                      ...categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedParentId = value);
                      context
                          .read<CreateCategoryBloc>()
                          .add(CreateCategoryParentIdChanged(parentId: value));
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              BlocBuilder<CreateCategoryBloc, CreateCategoryState>(
                builder: (context, state) {
                  final isLoading = state is CreateCategoryLoading;
                  final isValid = state is CreateCategoryEditing && state.isValid;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading || !isValid
                          ? null
                          : () {
                              context
                                  .read<CreateCategoryBloc>()
                                  .add(CreateCategorySubmitted());
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('추가'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
