import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/di/injection_container.dart';
import '../features/media/domain/secure_photo_repository.dart';

class SecurePhoto extends StatefulWidget {
  const SecurePhoto({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.repository,
  });

  final String url;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Port de chargement d'image (issue #258). Injectable pour les tests ; par
  /// defaut resolu via le service locator, jamais le transport direct.
  final SecurePhotoRepository? repository;

  @override
  State<SecurePhoto> createState() => _SecurePhotoState();
}

class _SecurePhotoState extends State<SecurePhoto> {
  late final SecurePhotoRepository _repo =
      widget.repository ?? sl<SecurePhotoRepository>();
  Future<Uint8List?>? _photo;

  @override
  void initState() {
    super.initState();
    _photo = _repo.load(widget.url);
  }

  @override
  void didUpdateWidget(covariant SecurePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _photo = _repo.load(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FutureBuilder<Uint8List?>(
        future: _photo,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) return widget.fallback;
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => widget.fallback,
          );
        },
      ),
    );
  }
}
