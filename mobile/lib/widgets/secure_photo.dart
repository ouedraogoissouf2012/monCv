import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/i_api_client.dart';

class SecurePhoto extends StatefulWidget {
  const SecurePhoto({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<SecurePhoto> createState() => _SecurePhotoState();
}

class _SecurePhotoState extends State<SecurePhoto> {
  Future<Uint8List?>? _photo;
  IApiClient? _api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = context.read<IApiClient>();
    if (_api != api || _photo == null) {
      _api = api;
      _photo = api.loadPhoto(widget.url);
    }
  }

  @override
  void didUpdateWidget(covariant SecurePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _api != null) {
      _photo = _api!.loadPhoto(widget.url);
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
