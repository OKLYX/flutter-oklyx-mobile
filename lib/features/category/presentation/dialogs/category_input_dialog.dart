import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';

class CategoryInputDialog extends StatefulWidget {
  final VoidCallback onClose;

  const CategoryInputDialog({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CategoryInputDialog> createState() => _CategoryInputDialogState();
}

class _CategoryInputDialogState extends State<CategoryInputDialog> {
  late TextEditingController _nameController;
  late TextEditingController _platformController;
  late TextEditingController _platformCategoryIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _platformController = TextEditingController();
    _platformCategoryIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _platformController.dispose();
    _platformCategoryIdController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리명을 입력해주세요.')),
      );
      return;
    }

    if (_platformController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('플랫폼을 입력해주세요.')),
      );
      return;
    }

    if (_platformCategoryIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('플랫폼 카테고리 ID를 입력해주세요.')),
      );
      return;
    }

    // TODO: Implement API call to create category
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카테고리가 추가되었습니다.')),
    );
    context.read<CategoryListBloc>().add(FetchCategoriesRequested());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '카테고리 추가',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '카테고리명',
                hintText: '예: Electronics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _platformController,
              decoration: InputDecoration(
                labelText: '플랫폼',
                hintText: '예: COUPANG',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _platformCategoryIdController,
              decoration: InputDecoration(
                labelText: '플랫폼 카테고리 ID',
                hintText: '예: cat_001',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onAddPressed,
                  child: const Text('추가'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
