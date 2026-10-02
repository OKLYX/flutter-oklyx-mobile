import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// One master-owned pool image in the manage sheet. [file] is set for a
/// create-mode file entry.
class ManageImage {
  final int token;
  final String url;
  final File? file;
  final bool inUse;

  const ManageImage({
    required this.token,
    required this.url,
    required this.inUse,
    this.file,
  });
}

/// Sheet body that multi-selects master-owned pool images and deletes them —
/// port of web
/// `app/dashboard/master-products/components/MasterPoolManageModal.tsx`
/// (@09208a0).
/// **File**: lib/features/master_product/presentation/widgets/master_pool_manage_sheet.dart
///
/// Deletion is delegated to [onDelete]; it returns the refreshed image list
/// (tokens may be reindexed in create mode), so the sheet stays open with
/// the current pool like the web modal.
///
/// **Usage**:
/// ```dart
/// await showAppSheet<void>(
///   context,
///   builder: (_) => MasterPoolManageSheet(
///     images: manageImages,
///     onDelete: _deletePoolImages,
///   ),
/// );
/// ```
///
/// ⚠️ Product references are auto-managed and never listed here.
/// ❌ Open it only through `showAppSheet` (PLAN R24).
class MasterPoolManageSheet extends StatefulWidget {
  final List<ManageImage> images;
  final Future<List<ManageImage>> Function(List<int> tokens) onDelete;

  const MasterPoolManageSheet({
    required this.images,
    required this.onDelete,
    super.key,
  });

  @override
  State<MasterPoolManageSheet> createState() => _MasterPoolManageSheetState();
}

class _MasterPoolManageSheetState extends State<MasterPoolManageSheet> {
  List<ManageImage> _images = [];
  List<int> _selected = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _images = widget.images;
  }

  void _toggle(int token) {
    setState(() {
      _selected = _selected.contains(token)
          ? _selected.where((t) => t != token).toList()
          : [..._selected, token];
    });
  }

  Future<void> _handleDelete() async {
    if (_selected.isEmpty) {
      return;
    }
    final ok = await showAppConfirmDialog(
      context,
      message: '선택한 ${_selected.length}개 이미지를 삭제할까요? 매핑돼 있으면 함께 해제됩니다.',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final next = await widget.onDelete(_selected);
      if (!mounted) {
        return;
      }
      setState(() {
        _images = next;
        _selected = [];
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            '마스터 이미지 관리',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: _images.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    '관리할 마스터 이미지가 없습니다.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final img in _images)
                      _manageCard(context, img, _selected.contains(img.token)),
                  ],
                ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selected.length}개 선택',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _selected.isEmpty || _busy ? null : _handleDelete,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(_busy ? '삭제 중...' : '선택 삭제'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _manageCard(BuildContext context, ManageImage img, bool checked) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _toggle(img.token),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: checked ? scheme.error : scheme.outlineVariant,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: img.file != null
                      ? Image.file(img.file!, fit: BoxFit.contain)
                      : MasterNetworkImage(
                          url: img.url,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              ),
            ),
            if (img.inUse)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.infoForeground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '사용중',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.backgroundLight,
                    ),
                  ),
                ),
              ),
            if (checked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '✓',
                    style: TextStyle(fontSize: 11, color: scheme.onError),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
