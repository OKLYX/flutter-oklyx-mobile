import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';
import '../../domain/entities/product_thumbnail.dart';

/// One seller's thumbnail card: image + source badge + actions (regenerate /
/// upload override / delete) + tap-to-zoom, with a busy spinner overlay.
///
/// ⚠️ The image is shown with `Image.network` directly — unlike product images
/// (byte-fetch via Dio). Thumbnails live on S3 with public-read (anonymous GET
/// 200), so no JWT is needed and `Image.network` is safe. A cache-buster keyed on
/// [ProductThumbnail.generatedAt] forces a reload after regenerate/override.
class ThumbnailSellerCard extends StatelessWidget {
  final ProductThumbnail thumbnail;
  final bool isBusy;
  final VoidCallback onRegenerate;
  final VoidCallback onUpload;
  final VoidCallback onDelete;

  const ThumbnailSellerCard({
    super.key,
    required this.thumbnail,
    required this.isBusy,
    required this.onRegenerate,
    required this.onUpload,
    required this.onDelete,
  });

  String get _bustedUrl {
    final sep = thumbnail.imageUrl.contains('?') ? '&' : '?';
    final buster = Uri.encodeComponent(
      thumbnail.generatedAt.isNotEmpty ? thumbnail.generatedAt : '${DateTime.now()}',
    );
    return '${thumbnail.imageUrl}${sep}t=$buster';
  }

  @override
  Widget build(BuildContext context) {
    final url = _bustedUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    thumbnail.sellerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SourceBadge(isManual: thumbnail.isManualOverride),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: thumbnail.imageUrl.isEmpty
                        ? null
                        : () => ZoomableImageViewer.show(
                              context,
                              image: NetworkImage(url),
                            ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: thumbnail.imageUrl.isEmpty
                            ? _placeholder(icon: Icons.image)
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return _placeholder(
                                    child: const CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stack) =>
                                    _placeholder(icon: Icons.broken_image),
                              ),
                      ),
                    ),
                  ),
                  if (isBusy)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.black38,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  icon: Icons.refresh,
                  label: '재생성',
                  onPressed: isBusy ? null : onRegenerate,
                ),
                _actionButton(
                  icon: Icons.upload,
                  label: '직접 업로드',
                  onPressed: isBusy ? null : onUpload,
                ),
                _actionButton(
                  icon: Icons.delete_outline,
                  label: '삭제',
                  onPressed: isBusy ? null : onDelete,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder({IconData? icon, Widget? child}) {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey[300],
      child: Center(
        child: child ?? Icon(icon, color: Colors.grey[500], size: 48),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final bool isManual;

  const _SourceBadge({required this.isManual});

  @override
  Widget build(BuildContext context) {
    final color = isManual ? Colors.deepPurple : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isManual ? '직접 업로드' : '자동 생성',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
