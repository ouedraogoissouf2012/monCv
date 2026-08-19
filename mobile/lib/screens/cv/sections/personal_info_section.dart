import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection_container.dart';
import '../../../features/ai/application/generate_resume_usecase.dart';
import '../../../features/cv/application/upload_profile_photo_usecase.dart';
import '../../../features/cv/presentation/personal_info/ai_resume_field.dart';
import '../../../features/cv/presentation/personal_info/fields/contact_fields.dart';
import '../../../features/cv/presentation/personal_info/fields/identity_fields.dart';
import '../../../features/cv/presentation/personal_info/fields/sensitive_identity_fields.dart';
import '../../../features/cv/presentation/personal_info/fields/location_fields.dart';
import '../../../features/cv/presentation/personal_info/fields/online_fields.dart';
import '../../../features/cv/presentation/personal_info/personal_info_form_controller.dart';
import '../../../features/cv/presentation/personal_info/photo/profile_photo_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/cv/domain/entities/personal_info.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';

/// Section « Informations personnelles » du formulaire CV (issue #242).
///
/// Orchestrateur : compose des widgets specialises (groupes de champs, photo,
/// resume IA) autour d'un [PersonalInfoFormController]. Ne possede plus ni les
/// controllers, ni les listes de pays, ni les appels transport — chacun vit
/// dans sa brique dediee (D1-D5a). Signature publique inchangee.
class PersonalInfoSection extends StatefulWidget {
  const PersonalInfoSection({
    super.key,
    this.personalInfo,
    required this.onChanged,
    this.formKey,
    this.uploadPhoto,
    this.generateResume,
  });

  final PersonalInfo? personalInfo;
  final ValueChanged<PersonalInfo> onChanged;
  final GlobalKey<FormState>? formKey;

  /// Use cases injectables (tests) ; par defaut resolus via le service locator.
  final UploadProfilePhotoUseCase? uploadPhoto;
  final GenerateResumeUseCase? generateResume;

  @override
  State<PersonalInfoSection> createState() => _PersonalInfoSectionState();
}

class _PersonalInfoSectionState extends State<PersonalInfoSection> {
  late final PersonalInfoFormController _controller;
  late final UploadProfilePhotoUseCase _uploadPhoto;
  late final GenerateResumeUseCase _generateResume;
  bool _cvIsForMe = false;

  @override
  void initState() {
    super.initState();
    _controller =
        PersonalInfoFormController.fromPersonalInfo(widget.personalInfo);
    _uploadPhoto = widget.uploadPhoto ?? sl<UploadProfilePhotoUseCase>();
    _generateResume = widget.generateResume ?? sl<GenerateResumeUseCase>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(_controller.toPersonalInfo());

  void _applyAccountIdentity(bool enabled) {
    User? user;
    try {
      user = Provider.of<AuthProvider>(context, listen: false).user;
    } catch (_) {}
    setState(() => _cvIsForMe = enabled);
    if (!enabled || user == null) {
      _notify();
      return;
    }
    if (user.prenom != null && user.prenom!.trim().isNotEmpty) {
      _controller.prenom.text = user.prenom!.trim();
    }
    if (user.nom != null && user.nom!.trim().isNotEmpty) {
      _controller.nom.text = user.nom!.trim();
    }
    if (user.email.trim().isNotEmpty) {
      _controller.email.text = user.email.trim();
    }
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePhotoField(
            controller: _controller,
            uploadPhoto: _uploadPhoto,
            onChanged: _notify,
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _cvIsForMe,
            onChanged: (v) => _applyAccountIdentity(v ?? false),
            title: Text(l.cvIsForMe),
            subtitle: Text(l.cvIsForMeHelp),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          _GroupLabel(l.identity.toUpperCase()),
          IdentityFields(controller: _controller, onChanged: _notify),
          const SizedBox(height: 20),
          _GroupLabel(l.sensitiveInfo),
          SensitiveIdentityFields(controller: _controller, onChanged: _notify),
          const SizedBox(height: 20),
          _GroupLabel(l.coordinates),
          ContactFields(controller: _controller, onChanged: _notify),
          const SizedBox(height: 20),
          _GroupLabel(l.location.toUpperCase()),
          LocationFields(
            controller: _controller,
            onChanged: _notify,
            // Rafraichit le helper telephone et les suggestions de ville.
            onCountrySelected: () => setState(() {}),
          ),
          const SizedBox(height: 20),
          _GroupLabel(l.online),
          OnlineFields(controller: _controller, onChanged: _notify),
          const SizedBox(height: 20),
          _GroupLabel(l.about),
          const SizedBox(height: 8),
          AiResumeField(
            controller: _controller,
            generateResume: _generateResume,
            onChanged: _notify,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Intitule de groupe de champs (petit label attenue). Local a la section.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
