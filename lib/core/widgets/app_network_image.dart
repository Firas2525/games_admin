import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Drop-in replacement for [Image.network] that caches images on disk & memory
/// (via `cached_network_image`) so banners, categories, games, etc. load
/// instantly after the first view and work offline.
///
/// - Supports `data:image/...;base64,` URIs (decoded once and memoized).
/// - Keeps the same `errorBuilder` / `loadingBuilder` signatures as
///   [Image.network] so existing call sites work unchanged.
class AppNetworkImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final Widget? placeholder;
  final Duration fadeInDuration;

  const AppNetworkImage(
    this.src, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
    this.loadingBuilder,
    this.placeholder,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  static final Map<String, Uint8List> _base64Cache = {};

  static Uint8List? _decodeDataUri(String uri) {
    final cached = _base64Cache[uri];
    if (cached != null) return cached;
    try {
      final comma = uri.indexOf(',');
      if (comma == -1) return null;
      final bytes = base64Decode(uri.substring(comma + 1));
      if (_base64Cache.length > 100) _base64Cache.clear();
      _base64Cache[uri] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _error(BuildContext context, Object error) {
    if (errorBuilder != null) return errorBuilder!(context, error, null);
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 22),
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.white.withValues(alpha: 0.04),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = src.trim();
    if (url.isEmpty) return _error(context, 'empty url');

    // Inline base64 images
    if (url.startsWith('data:')) {
      final bytes = _decodeDataUri(url);
      if (bytes == null) return _error(context, 'invalid data uri');
      return Image.memory(
        bytes,
        key: ValueKey('mem_${bytes.length}_${url.hashCode}'),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        gaplessPlayback: false,
        errorBuilder: (ctx, e, st) => _error(ctx, e),
      );
    }

    // Raw Base64 string without data: header
    if (!url.startsWith('http://') && !url.startsWith('https://') && url.length > 50) {
      try {
        final bytes = base64Decode(url.replaceAll(RegExp(r'\s+'), ''));
        return Image.memory(
          bytes,
          key: ValueKey('raw_mem_${bytes.length}_${url.hashCode}'),
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          color: color,
          colorBlendMode: colorBlendMode,
          errorBuilder: (ctx, e, st) => _error(ctx, e),
        );
      } catch (_) {}
    }

    return CachedNetworkImage(
      key: ValueKey('cni_$url'),
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment is Alignment ? alignment as Alignment : Alignment.center,
      color: color,
      colorBlendMode: colorBlendMode,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholderFadeInDuration: Duration.zero,
      useOldImageOnUrlChange: false,
      progressIndicatorBuilder: loadingBuilder != null
          ? (ctx, _, progress) => loadingBuilder!(
                ctx,
                const SizedBox.shrink(),
                ImageChunkEvent(
                  cumulativeBytesLoaded: progress.downloaded,
                  expectedTotalBytes: progress.totalSize,
                ),
              )
          : null,
      placeholder: loadingBuilder == null ? (ctx, _) => placeholder ?? _defaultPlaceholder() : null,
      errorWidget: (ctx, _, error) => _error(ctx, error),
    );
  }
}
