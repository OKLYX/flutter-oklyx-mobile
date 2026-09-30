import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// One pickable pool image. [token] = image id (edit mode) or buffer token
/// (create mode). [file] is set for a create-mode file entry (rendered with
/// `Image.file`); otherwise [url] is rendered.
class PickerImage {
  final int token;
  final String url;
  final File? file;

  const PickerImage({required this.token, required this.url, this.file});
}

/// Sheet body that picks the pool images mapped to one field — port of web
/// `app/dashboard/master-products/components/MasterImagePickerModal.tsx`
/// (@09208a0).
/// **File**: lib/features/master_product/presentation/widgets/master_image_picker_sheet.dart
///
/// Multi-select for a zone field, single (last pick wins) for the cover photo.
/// [확인] pops the selected tokens; [취소] / drag down pops `null`.
///
/// **Usage**:
/// ```dart
/// final tokens = await showMasterSheet<List<int>>(
///   context,
///   builder: (_) => MasterImagePickerSheet(
///     fieldLabel: field.label,
///     single: field.key == kSourceZone,
///     images: pickerImages,
///     initialSelected: fieldTokens(field.key),
///   ),
/// );
/// if (tokens != null) commit(field.key, tokens);
/// ```
///
/// ❌ Open it only through `showMasterSheet` (PLAN R24).
class MasterImagePickerSheet extends StatefulWidget {
  final String fieldLabel;
  final bool single;
  final List<PickerImage> images;
  final List<int> initialSelected;

  const MasterImagePickerSheet({
    required this.fieldLabel,
    required this.single,
    required this.images,
    required this.initialSelected,
    super.key,
  });

  @override
  State<MasterImagePickerSheet> createState() => _MasterImagePickerSheetState();
}

class _MasterImagePickerSheetState extends State<MasterImagePickerSheet> {
  List<int> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected = [...widget.initialSelected];
  }

  void _toggle(int token) {
    setState(() {
      if (widget.single) {
        _selected =
            _selected.isNotEmpty && _selected[0] == token ? [] : [token];
        return;
      }
      _selected = _selected.contains(token)
          ? _selected.where((t) => t != token).toList()
          : [..._selected, token];
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            '${widget.fieldLabel} 이미지 선택 '
            '${widget.single ? '(단일)' : '(다중)'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: widget.images.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    '풀에 이미지가 없습니다. 먼저 이미지를 업로드하세요.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final img in widget.images)
                      _pickCard(context, img, _selected.contains(img.token)),
                  ],
                ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pickCard(BuildContext context, PickerImage img, bool isChecked) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _toggle(img.token),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isChecked ? AppColors.infoForeground : scheme.outlineVariant,
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
            if (isChecked)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.infoForeground,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '✓',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.backgroundLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
