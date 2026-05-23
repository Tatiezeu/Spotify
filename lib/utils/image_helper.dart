import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Centralized image utility that correctly resolves local file paths vs network URLs.
///
/// This prevents the common Flutter error where a local file path from image_picker
/// (e.g. `/private/var/mobile/...`) is incorrectly passed to [NetworkImage], which
/// expects an HTTP(S) URL.
class ImageHelper {
  /// Returns true if [url] is a network URL (http/https/blob).
  static bool isNetworkUrl(String url) {
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('blob:');
  }

  /// Returns the correct [ImageProvider] for the given [url].
  ///
  /// - Network URLs → [NetworkImage]
  /// - Local file paths → [FileImage] (on mobile/desktop) or [NetworkImage] fallback (on web)
  /// - Empty/null → returns null
  static ImageProvider? getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;

    if (isNetworkUrl(url)) {
      return NetworkImage(url);
    }

    // On web, File I/O is not available — fall back to NetworkImage
    if (kIsWeb) {
      return NetworkImage(url);
    }

    // Local file path (e.g. from image_picker)
    return FileImage(File(url));
  }

  /// Builds an [Image] widget that correctly handles both network and local file URLs.
  ///
  /// Drop-in replacement for `Image.network(url, ...)` throughout the codebase.
  static Widget imageWidget(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    final defaultErrorBuilder = errorBuilder ??
        (BuildContext context, Object error, StackTrace? stackTrace) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFF282828),
            child: const Icon(Icons.music_note, color: Colors.white38),
          );
        };

    if (isNetworkUrl(url)) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: defaultErrorBuilder,
      );
    }

    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: defaultErrorBuilder,
      );
    }

    // Local file
    return Image.file(
      File(url),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: defaultErrorBuilder,
    );
  }
}
