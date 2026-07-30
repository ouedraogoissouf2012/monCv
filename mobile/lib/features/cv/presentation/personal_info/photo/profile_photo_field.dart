import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/error/result.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../screens/cv/widgets/editable_profile_photo.dart';
import '../../../application/upload_profile_photo_usecase.dart';
import '../personal_info_form_controller.dart';

/// Champ photo de profil : selection (galerie/camera), apercu local immediat et
/// upload via [UploadProfilePhotoUseCase] (issue #242).
///
/// Ne parle JAMAIS au transport directement : l'upload passe par le use case
/// (D4), qui renvoie un [Result]. L'echec laisse la photo affichee localement
/// (via les bytes du [PersonalInfoFormController]) sans bloquer l'utilisateur.
class ProfilePhotoField extends StatefulWidget {
  const ProfilePhotoField({
    super.key,
    required this.controller,
    required this.uploadPhoto,
    required this.onChanged,
    this.picker,
  });

  final PersonalInfoFormController controller;
  final UploadProfilePhotoUseCase uploadPhoto;
  final VoidCallback onChanged;

  /// Injectable pour les tests ; par defaut un [ImagePicker] reel.
  final ImagePicker? picker;

  @override
  State<ProfilePhotoField> createState() => _ProfilePhotoFieldState();
}

class _ProfilePhotoFieldState extends State<ProfilePhotoField> {
  bool _uploading = false;

  Future<void> _pick() async {
    final l = AppLocalizations.of(context)!;
    final picker = widget.picker ?? ImagePicker();
    final source = await _chooseSource();
    if (source == null || !mounted) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    // Apercu local immediat (l'utilisateur voit sa photo tout de suite).
    setState(() {
      widget.controller.photoBytes = bytes;
      _uploading = false;
    });

    final result = kIsWeb
        ? await widget.uploadPhoto(PhotoBytesSource(
            bytes: bytes,
            filename: picked.name,
            mimeType: picked.mimeType ?? 'image/jpeg',
          ))
        : await widget.uploadPhoto(PhotoFileSource(picked.path));
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() => widget.controller.photoUrl = data);
      case Failure():
        // La photo reste visible en local ; on informe sans bloquer.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.photoLocalOnly('')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
    }
    widget.onChanged();
  }

  Future<ImageSource?> _chooseSource() {
    final l = AppLocalizations.of(context)!;
    if (kIsWeb) return Future.value(ImageSource.gallery);
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.gallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.camera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (widget.controller.photoUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text(l.removePhoto,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(widget.controller.clearPhoto);
                  widget.onChanged();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Center(
          child: EditableProfilePhoto(
            bytes: widget.controller.photoBytes,
            url: widget.controller.photoUrl,
            loading: _uploading,
            onTap: _uploading ? null : _pick,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            l.profilePhotoOptional,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    );
  }
}
