import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/pdf_saver.dart';

class PublicQrCode extends StatefulWidget {
  final String url;
  final double size;
  final bool showDownloadButton;

  const PublicQrCode({
    super.key,
    required this.url,
    this.size = 180,
    this.showDownloadButton = true,
  });

  @override
  State<PublicQrCode> createState() => _PublicQrCodeState();
}

class _PublicQrCodeState extends State<PublicQrCode> {
  final _boundaryKey = GlobalKey();
  bool _saving = false;

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      await saveBytes(
        data.buffer.asUint8List(),
        'moncv-qr-code.png',
        'image/png',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: QrImageView(
                data: widget.url,
                version: QrVersions.auto,
                size: widget.size,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF111827),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
        ),
        if (widget.showDownloadButton) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _saving ? null : _download,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined, size: 18),
            label: const Text('Télécharger le QR code'),
          ),
        ],
      ],
    );
  }
}
