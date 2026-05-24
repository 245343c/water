import 'dart:io';

import 'package:flutter/material.dart';

/// Displays a product/admin image from a local file path or remote URL.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
  });

  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  static bool isNetworkPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  static bool isLocalPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return !isNetworkPath(path);
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImage() {
    final p = path;
    if (p == null || p.isEmpty) {
      return _placeholder();
    }
    if (isNetworkPath(p)) {
      return Image.network(
        p,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    final file = File(p);
    if (!file.existsSync()) return _placeholder();
    return Image.file(file, width: width, height: height, fit: fit);
  }

  Widget _placeholder() {
    return SizedBox(
      width: width,
      height: height,
      child: placeholder ??
          const ColoredBox(
            color: Color(0xFFF3F4F6),
            child: Center(
              child: Icon(Icons.image_outlined, color: Color(0xFF9CA3AF), size: 32),
            ),
          ),
    );
  }
}
