import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';

/// 상품 썸네일 위젯.
///
/// **용도**: 상품 이미지를 `GET /api/products/{id}/image` (바이너리)로 불러와
/// [Image.memory]로 표시한다. 로딩 중 스피너, 실패/없음 시 회색 플레이스홀더.
///
/// **파일**: lib/features/purchase_list/presentation/widgets/product_thumbnail.dart
///
/// **사용 예제**:
/// ```dart
/// ProductThumbnail(productId: 12, size: 48)
///
/// // Tap to enlarge + small magnifier at the bottom-right (loaded image only)
/// ProductThumbnail(productId: 12, size: 64, zoomable: true)
/// ```
///
/// ⚠️ [zoomable] uses the shared `ImageWithZoomButton` with the bytes already
/// loaded for the thumbnail — no extra request. Placeholder/loading states
/// are not tappable. Inside a tappable card the image tap opens the viewer
/// instead of the card action.
///
/// 이미지 fetch 패턴은 product_detail_page.dart 의 `_loadProductImage` 와 동일하다.
/// productId 가 바뀔 때만 재요청하도록 future 를 캐시한다.
class ProductThumbnail extends StatefulWidget {
  final int productId;
  final double size;

  /// Tap opens the full-screen viewer; a magnifier sits bottom-right.
  final bool zoomable;

  const ProductThumbnail({
    required this.productId,
    this.size = 48,
    this.zoomable = false,
    super.key,
  });

  @override
  State<ProductThumbnail> createState() => _ProductThumbnailState();
}

class _ProductThumbnailState extends State<ProductThumbnail> {
  Future<Uint8List?> _future = Future.value(null);

  @override
  void initState() {
    super.initState();
    _future = _loadImage(widget.productId);
  }

  @override
  void didUpdateWidget(covariant ProductThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _future = _loadImage(widget.productId);
    }
  }

  Future<Uint8List?> _loadImage(int productId) async {
    try {
      final response = await getIt<DioClient>().get(
        '/api/products/$productId/image',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Uint8List;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _buildThumb(context);
    if (!widget.zoomable) {
      return thumb;
    }
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return thumb;
        }
        return ImageWithZoomButton(
          image: MemoryImage(bytes),
          iconSize: 14,
          child: thumb,
        );
      },
    );
  }

  Widget _buildThumb(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<Uint8List?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
              );
            }
            return _placeholder();
          },
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Theme.of(context).colorScheme.outlineVariant,
      child: Icon(
        Icons.image,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: widget.size * 0.5,
      ),
    );
  }
}
