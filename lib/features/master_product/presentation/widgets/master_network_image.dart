import 'package:flutter/material.dart';

/// Renders master photos, pool images, product gallery images and channel
/// thumbnails (FEATURE_2609_80 R12).
///
/// Counterpart of the web `resolveThumbUrl`: an `http` URL goes to
/// [Image.network]; anything else (local disk path, empty) becomes a grey box
/// with the [placeholder] text. Like the mobile thumbnail precedent, local
/// paths are not supported.
/// ❌ Not for the product representative photo (`Product.imageUrl`)
///    — use `ProductThumbnail(productId:)`.
class MasterNetworkImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final String placeholder;
  final BoxFit fit;

  const MasterNetworkImage({
    required this.url,
    required this.width,
    required this.height,
    super.key,
    this.placeholder = '없음',
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final src = url;
    final empty = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: scheme.surfaceContainerHighest,
      child: Text(
        placeholder,
        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
      ),
    );
    if (src == null || !src.startsWith('http')) {
      return empty;
    }
    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => empty,
    );
  }
}
