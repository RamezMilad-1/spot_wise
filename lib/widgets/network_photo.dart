import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// One image widget for every source the app uses:
///  * `http(s)://`  → cached network image (seed/demo photos, OSM, picsum)
///  * `data:` URI   → base64 image picked from camera/gallery
///  * null/empty    → a tasteful placeholder
///
/// Always falls back to the placeholder on error, so nothing renders broken.
class NetworkPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  const NetworkPhoto(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    final src = url ?? '';
    if (src.isEmpty) {
      child = _placeholder(context);
    } else if (src.startsWith('data:')) {
      child = _memory(context, src);
    } else {
      child = CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, _) => _loading(context),
        errorWidget: (_, _, _) => _placeholder(context),
      );
    }

    final sized = SizedBox(width: width, height: height, child: child);
    return radius != null
        ? ClipRRect(borderRadius: radius!, child: sized)
        : sized;
  }

  Widget _memory(BuildContext context, String dataUri) {
    try {
      final bytes = base64Decode(dataUri.split(',').last);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } catch (_) {
      return _placeholder(context);
    }
  }

  Widget _loading(BuildContext context) =>
      Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.photo_outlined, color: scheme.outline, size: 28),
    );
  }
}
