import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_image.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_image_gallery_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_image_gallery_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_image_gallery_state.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';

/// 물품(상품) 사진 여러 장 — 웹 `ProductImageGallery` 와 같은 동작.
///
/// **파일**: lib/features/product/presentation/widgets/product_image_gallery.dart
/// **쓰는 곳**: 상품등록(`ProductRegisterPage`) · 상품상세(`ProductDetailPage`).
///
/// **할 수 있는 것**(웹과 같다): 여러 장 올리기(앨범 여러 장 · 카메라 한 장) · [대체] ·
/// [삭제] · ◀▶ 순서 바꾸기 · 첫 장 「대표」 · 사진 누르면 확대 · [다운로드](상세만).
/// 받는 파일은 웹과 같이 JPEG/PNG · 20MB 이하 — 나머지는 빼고 안내한다.
///
/// **두 모드**:
/// - `ProductImageGallery.server(productId:)` — 상세. 고르는 즉시 서버에 반영
///   (`ProductImageGalleryBloc`, `/api/admin/products/{id}/images`).
/// - `ProductImageGallery.buffer(files:, onChanged:)` — 등록. 서버를 부르지 않고 부모가 든
///   파일 목록만 바꾼다. 부모가 상품을 만든 뒤 한 번에 올린다(`ProductRegisterBloc`).
///
/// **사용 예제**:
/// ```dart
/// // 1) 상품상세 — 바로 서버 반영
/// ProductImageGallery.server(productId: product.id)
///
/// // 2) 상품등록 — 부모가 파일 목록을 든다
/// ProductImageGallery.buffer(
///   files: _imageFiles,
///   onChanged: (files) => setState(() => _imageFiles = files),
/// )
///
/// // 3) 등록 화면에서 저장할 때 같이 넘긴다
/// _bloc.add(RegisterProductRequested(productName: name, images: _imageFiles));
/// ```
///
/// ⚠️ 첫 장이 대표 사진이다 — 서버가 `Product.imageUrl` 을 첫 장으로 맞추고
///    `ProductThumbnail` 이 그것을 보여 준다.
/// ⚠️ 삭제 409 = 마스터 이미지 풀에 놓인 사진 — 서버 문구를 그대로 보여 준다.
/// ❌ 옛 단일 사진 API(`PUT/DELETE /api/products/{id}/image`)로 올리지 말 것 — 갤러리에
///    안 보이고, 갤러리를 고치는 순간 덮어써진다.
/// ❌ 웹의 클립보드 끌어 붙이기 · 마켓 사진 가져오기는 없다(끌기 기능이라 웹도 좁은 화면에서 끈다).
class ProductImageGallery extends StatelessWidget {
  final int? productId;
  final List<File> files;
  final ValueChanged<List<File>>? onChanged;

  const ProductImageGallery.server({required int this.productId, super.key})
      : files = const [],
        onChanged = null;

  const ProductImageGallery.buffer({
    required this.files,
    required ValueChanged<List<File>> this.onChanged,
    super.key,
  }) : productId = null;

  @override
  Widget build(BuildContext context) {
    final id = productId;
    if (id != null) {
      return BlocProvider(
        create: (_) =>
            getIt<ProductImageGalleryBloc>()..add(ProductImagesRequested(id)),
        child: _ServerGallery(productId: id),
      );
    }
    final change = onChanged!;
    return _GalleryView(
      items: [
        for (final file in files) _GalleryItem(provider: FileImage(file))
      ],
      busy: false,
      onAdd: (picked) => change([...files, ...picked]),
      onReplace: (index, file) {
        final next = [...files];
        next[index] = file;
        change(next);
      },
      onMove: (index, direction) {
        final next = [...files];
        final moved = next[index];
        next[index] = next[index + direction];
        next[index + direction] = moved;
        change(next);
      },
      onDelete: (index) => change([...files]..removeAt(index)),
    );
  }
}

/// Detail mode: the BLoC owns the photos; this only adds the download.
class _ServerGallery extends StatefulWidget {
  final int productId;

  const _ServerGallery({required this.productId});

  @override
  State<_ServerGallery> createState() => _ServerGalleryState();
}

class _ServerGalleryState extends State<_ServerGallery> {
  int? _downloadingId;

  /// Saves the original through the system "save as" dialog (same policy as
  /// the shipping label download). The photo is a public S3 URL, so a plain
  /// Dio is used — the JWT must not go to S3.
  Future<void> _download(ProductImage image) async {
    setState(() => _downloadingId = image.id);
    try {
      final response = await Dio().get<List<int>>(
        image.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const []);
      if (bytes.isEmpty) throw const FormatException('empty');
      final path = image.imageUrl.split('?').first;
      final segment = path.substring(path.lastIndexOf('/') + 1);
      final dot = segment.lastIndexOf('.');
      // Saved name = the stored file name, like the web [다운로드].
      final base = dot > 0 ? segment.substring(0, dot) : segment;
      final isPng = segment.toLowerCase().endsWith('.png');
      final saved = await FileSaver.instance.saveAs(
        name: base.isEmpty ? 'product-image' : base,
        bytes: bytes,
        ext: isPng ? 'png' : 'jpg',
        mimeType: isPng ? MimeType.png : MimeType.jpeg,
      );
      // Cancel returns null — no toast.
      if (saved == null || saved.isEmpty || !mounted) return;
      showSuccessToast(context, '이미지를 저장했습니다.');
    } catch (_) {
      if (mounted) showErrorToast(context, '이미지 저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductImageGalleryBloc>();
    return BlocConsumer<ProductImageGalleryBloc, ProductImageGalleryState>(
      listenWhen: (previous, current) =>
          current.errorSeq != previous.errorSeq && current.actionError != null,
      listener: (context, state) => showErrorToast(context, state.actionError!),
      builder: (context, state) {
        final images = state.images;
        return _GalleryView(
          items: [
            for (final image in images)
              _GalleryItem(
                provider: image.imageUrl.startsWith('http')
                    ? NetworkImage(image.imageUrl)
                    : null,
                downloading: _downloadingId == image.id,
              ),
          ],
          busy: state.busy,
          isLoading: state.isLoading,
          loadError: state.loadError,
          onRetry: () => bloc.add(ProductImagesRequested(widget.productId)),
          onAdd: (files) => bloc.add(ProductImagesAdded(files)),
          onReplace: (index, file) => bloc.add(
            ProductImageReplaced(imageId: images[index].id, file: file),
          ),
          onMove: (index, direction) =>
              bloc.add(ProductImageMoved(index: index, direction: direction)),
          onDelete: (index) => bloc.add(ProductImageDeleted(images[index].id)),
          onDownload: (index) => images[index].imageUrl.startsWith('http') &&
                  _downloadingId == null
              ? _download(images[index])
              : null,
        );
      },
    );
  }
}

class _GalleryItem {
  /// null = a stored path this device cannot load (local server) → grey box.
  final ImageProvider? provider;
  final bool downloading;

  const _GalleryItem({required this.provider, this.downloading = false});
}

const _maxImageBytes = 20 * 1024 * 1024;
const _rejectMessage = 'JPEG/PNG·20MB 이하만 업로드 가능';

/// Same filter as the web (`ACCEPT` + `MAX_SIZE`): the server refuses the rest.
bool _isAllowedImage(File file) {
  final name = file.path.toLowerCase();
  final typeOk =
      name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png');
  return typeOk && file.lengthSync() <= _maxImageBytes;
}

class _GalleryView extends StatelessWidget {
  final List<_GalleryItem> items;
  final bool busy;
  final bool isLoading;
  final String? loadError;
  final VoidCallback? onRetry;
  final ValueChanged<List<File>> onAdd;
  final void Function(int index, File file) onReplace;
  final void Function(int index, int direction) onMove;
  final ValueChanged<int> onDelete;

  /// null = register mode (the photo is already on this device).
  final ValueChanged<int>? onDownload;

  const _GalleryView({
    required this.items,
    required this.busy,
    required this.onAdd,
    required this.onReplace,
    required this.onMove,
    required this.onDelete,
    this.isLoading = false,
    this.loadError,
    this.onRetry,
    this.onDownload,
  });

  /// Keeps JPEG/PNG ≤ 20MB and says so when anything was left out.
  List<File> _valid(BuildContext context, List<File> picked) {
    final valid = picked.where(_isAllowedImage).toList();
    if (valid.length < picked.length) showErrorToast(context, _rejectMessage);
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '상품 이미지',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            _PickMenu(
              multiple: true,
              enabled: !busy && !isLoading && loadError == null,
              onPicked: (picked) {
                final valid = _valid(context, picked);
                if (valid.isNotEmpty) onAdd(valid);
              },
              builder: (onPressed) => FilledButton(
                onPressed: onPressed,
                child: busy
                    ? const AppBusyLabel('이미지 업로드')
                    : const Text('이미지 업로드'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (loadError != null)
          Column(
            children: [
              Text(loadError!, style: TextStyle(color: scheme.error)),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          )
        else if (items.isEmpty)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '이미지 없음',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < items.length; i++)
                    SizedBox(width: width, child: _card(context, i)),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _card(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final item = items[index];
    final provider = item.provider;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.image, color: scheme.onSurfaceVariant),
    );
    final download = onDownload;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (provider == null)
                    placeholder
                  else
                    GestureDetector(
                      onTap: () =>
                          ZoomableImageViewer.show(context, image: provider),
                      child: ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Image(
                          image: provider,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => placeholder,
                        ),
                      ),
                    ),
                  if (index == 0)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandMain,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '대표',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foregroundLight,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _smallButton(
                  label: '◀',
                  onPressed:
                      busy || index == 0 ? null : () => onMove(index, -1),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _smallButton(
                  label: '▶',
                  onPressed: busy || index == items.length - 1
                      ? null
                      : () => onMove(index, 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _PickMenu(
                  multiple: false,
                  enabled: !busy,
                  onPicked: (picked) {
                    final valid = _valid(context, picked);
                    if (valid.isNotEmpty) onReplace(index, valid.first);
                  },
                  builder: (onPressed) =>
                      _smallButton(label: '대체', onPressed: onPressed),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _smallButton(
                  label: '삭제',
                  color: scheme.error,
                  onPressed: busy ? null : () => onDelete(index),
                ),
              ),
            ],
          ),
          if (download != null) ...[
            const SizedBox(height: 4),
            item.downloading
                ? _smallButton(label: '다운로드', onPressed: null, busy: true)
                : _smallButton(
                    label: '다운로드',
                    onPressed: provider == null ? null : () => download(index),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _smallButton({
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    bool busy = false,
  }) =>
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          textStyle: const TextStyle(fontSize: 12),
        ),
        onPressed: onPressed,
        child: busy ? AppBusyLabel(label) : Text(label),
      );
}

/// Camera / album menu in front of a button. The album picks several photos
/// when [multiple]; the camera always takes one.
class _PickMenu extends StatelessWidget {
  final bool multiple;
  final bool enabled;
  final ValueChanged<List<File>> onPicked;
  final Widget Function(VoidCallback? onPressed) builder;

  const _PickMenu({
    required this.multiple,
    required this.enabled,
    required this.onPicked,
    required this.builder,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery && multiple) {
        picked = await picker.pickMultiImage();
      } else {
        final one = await picker.pickImage(source: source);
        picked = one == null ? const [] : [one];
      }
      if (picked.isEmpty) return;
      onPicked([for (final x in picked) File(x.path)]);
    } catch (_) {
      if (context.mounted) showErrorToast(context, '이미지를 불러오지 못했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.photo_camera_outlined),
            onPressed: () => _pick(context, ImageSource.camera),
            child: const Text('카메라로 촬영'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.photo_library_outlined),
            onPressed: () => _pick(context, ImageSource.gallery),
            child: const Text('앨범에서 선택'),
          ),
        ],
        builder: (context, controller, _) => builder(
          enabled
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
        ),
      );
}
