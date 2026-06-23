import 'package:flutter/material.dart';

/// Full-screen image viewer with pinch-zoom, a close button, and
/// tap-outside-to-dismiss. Use this everywhere an enlarged image view is
/// needed instead of re-implementing the dialog per page.
///
/// **Purpose**: Show any image full-screen with zoom/pan, a top-right close
/// button, and dismissal by tapping the empty (black) area around the image.
/// **File**: lib/shared/widgets/zoomable_image_viewer.dart
///
/// **Why a shared widget**: Multiple pages need "tap image → enlarge" behaviour.
/// Centralising it keeps the close/zoom/dismiss UX identical everywhere and
/// avoids duplicated dialog code.
///
/// **Image source**: Accepts an [ImageProvider] so it works with both
/// authenticated byte images (`MemoryImage(bytes)`) — the project's usual
/// pattern via `GET /api/products/{id}/image` — and URL images
/// (`NetworkImage(url)`).
///
/// **Usage — open directly**:
/// ```dart
/// ZoomableImageViewer.show(context, image: MemoryImage(bytes));
/// ```
///
/// **Usage — from a tappable thumbnail**:
/// ```dart
/// GestureDetector(
///   onTap: () => ZoomableImageViewer.show(context, image: MemoryImage(bytes)),
///   child: Image.memory(bytes),
/// )
/// ```
///
/// **Usage — with the built-in magnifier button overlay**:
/// ```dart
/// ImageWithZoomButton(
///   image: MemoryImage(bytes),
///   child: Image.memory(bytes, fit: BoxFit.cover),
/// )
/// ```
///
/// ⚠️ Pass an [ImageProvider], not a widget. Build it from the same bytes/URL
/// already used for the thumbnail so no extra network call is made.
/// ❌ Do not re-implement this dialog inside a page (see `_showImageDialog`
/// removed from `product_detail_page.dart`).
class ZoomableImageViewer extends StatelessWidget {
  /// The image to display full-screen.
  final ImageProvider image;

  const ZoomableImageViewer({super.key, required this.image});

  /// Opens the viewer as a full-screen dialog.
  ///
  /// Dismissible by the close button or by tapping the area around the image.
  static Future<void> show(
    BuildContext context, {
    required ImageProvider image,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => ZoomableImageViewer(image: image),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Outer detector dismisses on tap. Taps land here for any point NOT on the
    // image itself (the surrounding/letterbox area), because the inner image
    // detector only covers the displayed image bounds.
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Pinch to zoom / pan over the full screen.
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  // FittedBox sizes the inner detector to the *displayed*
                  // image, so taps outside the image fall through to the
                  // outer dismiss detector while taps on the image are kept.
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: GestureDetector(
                      onTap: () {}, // absorb taps on the image (stay open)
                      child: Image(image: image),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thumbnail wrapper that overlays a magnifier button at the bottom-right
/// corner; tapping the button (or the image) opens [ZoomableImageViewer].
///
/// **Purpose**: Standard "image + 돋보기 button" combo used on detail/inquiry
/// pages so users can enlarge an image.
/// **File**: lib/shared/widgets/zoomable_image_viewer.dart
///
/// **Usage**:
/// ```dart
/// ImageWithZoomButton(
///   image: MemoryImage(bytes),
///   child: ClipRRect(
///     borderRadius: BorderRadius.circular(8),
///     child: Image.memory(bytes, width: 200, height: 200, fit: BoxFit.cover),
///   ),
/// )
/// ```
///
/// ⚠️ [child] is the displayed thumbnail; [image] is the source opened in the
/// full-screen viewer. They normally come from the same bytes/URL.
/// ❌ Do not place this inside another `GestureDetector` whose `onTap` conflicts
/// with opening the viewer.
class ImageWithZoomButton extends StatelessWidget {
  /// Image opened full-screen when the button or thumbnail is tapped.
  final ImageProvider image;

  /// The thumbnail shown in place.
  final Widget child;

  /// Whether tapping the thumbnail itself (not only the button) opens the
  /// viewer. Defaults to true.
  final bool tapImageToZoom;

  const ImageWithZoomButton({
    super.key,
    required this.image,
    required this.child,
    this.tapImageToZoom = true,
  });

  @override
  Widget build(BuildContext context) {
    void open() => ZoomableImageViewer.show(context, image: image);

    return Stack(
      children: [
        if (tapImageToZoom)
          GestureDetector(onTap: open, child: child)
        else
          child,
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: open,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
