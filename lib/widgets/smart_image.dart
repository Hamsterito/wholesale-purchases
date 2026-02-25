import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SmartImage extends StatefulWidget {
  const SmartImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
  });

  final String path;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  @override
  State<SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<SmartImage> {
  static const int _decodedCacheLimit = 120;
  static final LinkedHashMap<String, Uint8List?> _decodedCache =
      LinkedHashMap<String, Uint8List?>();

  Uint8List? _decodedBytes;
  bool _isDecoding = false;

  @override
  void initState() {
    super.initState();
    _prepareDecodedBytes();
  }

  @override
  void didUpdateWidget(covariant SmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _prepareDecodedBytes();
    }
  }

  void _prepareDecodedBytes() {
    final path = widget.path.trim();
    final isEncoded = _isDataUrl(path) || _isBase64(path);
    if (!isEncoded || path.isEmpty) {
      _decodedBytes = null;
      _isDecoding = false;
      return;
    }

    final cached = _readFromCache(path);
    if (cached.hit) {
      _decodedBytes = cached.bytes;
      _isDecoding = false;
      return;
    }

    _decodedBytes = null;
    _isDecoding = true;

    compute<String, Uint8List?>(_decodeEncodedImagePath, path)
        .then((bytes) {
          if (!mounted || widget.path.trim() != path) return;
          _writeToCache(path, bytes);
          setState(() {
            _decodedBytes = bytes;
            _isDecoding = false;
          });
        })
        .catchError((_) {
          if (!mounted || widget.path.trim() != path) return;
          _writeToCache(path, null);
          setState(() {
            _decodedBytes = null;
            _isDecoding = false;
          });
        });
  }

  _CacheLookup _readFromCache(String path) {
    if (!_decodedCache.containsKey(path)) {
      return const _CacheLookup(hit: false);
    }
    final bytes = _decodedCache.remove(path);
    _decodedCache[path] = bytes;
    return _CacheLookup(hit: true, bytes: bytes);
  }

  void _writeToCache(String path, Uint8List? bytes) {
    _decodedCache.remove(path);
    _decodedCache[path] = bytes;
    while (_decodedCache.length > _decodedCacheLimit) {
      _decodedCache.remove(_decodedCache.keys.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePlaceholder =
        widget.placeholder ??
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.image,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 48,
          ),
        );

    final path = widget.path.trim();
    final isDataUrl = _isDataUrl(path);
    final isBase64 = _isBase64(path);
    final isEncoded = isDataUrl || isBase64;
    final isNetwork = _isNetwork(path);

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio =
            MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
        final logicalWidth = _resolveLogicalDimension(
          constraints.maxWidth,
          widget.width,
        );
        final logicalHeight = _resolveLogicalDimension(
          constraints.maxHeight,
          widget.height,
        );
        final cacheWidth = _toCacheDimension(logicalWidth, devicePixelRatio);
        final cacheHeight = _toCacheDimension(logicalHeight, devicePixelRatio);

        if (path.isEmpty) {
          return safePlaceholder;
        }

        if (isEncoded) {
          if (_isDecoding) {
            return safePlaceholder;
          }
          final bytes = _decodedBytes;
          if (bytes == null) {
            return safePlaceholder;
          }
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: widget.filterQuality,
            isAntiAlias: true,
            gaplessPlayback: true,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (_, __, ___) => safePlaceholder,
          );
        }

        if (isNetwork) {
          return Image.network(
            path,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: widget.filterQuality,
            isAntiAlias: true,
            gaplessPlayback: true,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (_, __, ___) => safePlaceholder,
          );
        }

        return Image.asset(
          path,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          filterQuality: widget.filterQuality,
          isAntiAlias: true,
          gaplessPlayback: true,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (_, __, ___) => safePlaceholder,
        );
      },
    );

    final borderRadius = widget.borderRadius;
    if (borderRadius == null) {
      return content;
    }

    return ClipRRect(borderRadius: borderRadius, child: content);
  }

  bool _isDataUrl(String value) => value.startsWith('data:image');
  bool _isBase64(String value) => value.startsWith('base64:');
  bool _isNetwork(String value) =>
      value.startsWith('http://') || value.startsWith('https://');
}

class _CacheLookup {
  const _CacheLookup({required this.hit, this.bytes});

  final bool hit;
  final Uint8List? bytes;
}

double? _resolveLogicalDimension(double constraint, double? fallback) {
  if (constraint.isFinite && constraint > 0) return constraint;
  if (fallback != null && fallback.isFinite && fallback > 0) return fallback;
  return null;
}

int? _toCacheDimension(double? logical, double devicePixelRatio) {
  if (logical == null || !logical.isFinite || logical <= 0) return null;
  final value = (logical * devicePixelRatio).round();
  if (value <= 0) return null;
  final clamped = value.clamp(16, 4096);
  return clamped.toInt();
}

Uint8List? _decodeEncodedImagePath(String rawPath) {
  final path = rawPath.trim();
  if (path.isEmpty) return null;

  String? encoded;
  if (path.startsWith('data:image')) {
    final commaIndex = path.indexOf(',');
    if (commaIndex <= 0) return null;
    encoded = path.substring(commaIndex + 1);
  } else if (path.startsWith('base64:')) {
    final firstColon = path.indexOf(':');
    if (firstColon < 0) return null;
    final secondColon = path.indexOf(':', firstColon + 1);
    encoded = secondColon > 0
        ? path.substring(secondColon + 1)
        : path.substring(firstColon + 1);
  }

  if (encoded == null || encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}
