import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../widgets/secure_photo.dart';

class EditableProfilePhoto extends StatelessWidget {
  const EditableProfilePhoto({
    super.key,
    required this.loading,
    required this.onTap,
    this.bytes,
    this.url,
  });

  final bool loading;
  final VoidCallback? onTap;
  final Uint8List? bytes;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = Icon(
      Icons.person_outline_rounded,
      size: 40,
      color: colors.primary.withValues(alpha: 0.5),
    );
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            backgroundImage:
                bytes == null ? null : MemoryImage(bytes!) as ImageProvider,
            child: _content(colors, fallback),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _content(ColorScheme colors, Widget fallback) {
    if (loading) {
      return CircularProgressIndicator(strokeWidth: 2, color: colors.primary);
    }
    if (bytes != null) return null;
    if (url == null) return fallback;
    return ClipOval(
      child: SecurePhoto(
        url: url!,
        width: 96,
        height: 96,
        fallback: fallback,
      ),
    );
  }
}
