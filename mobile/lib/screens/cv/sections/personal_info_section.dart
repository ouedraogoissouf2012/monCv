import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/cv.dart';

class PersonalInfoSection extends StatefulWidget {
  final PersonalInfo? personalInfo;
  final Function(PersonalInfo) onChanged;
  final GlobalKey<FormState>? formKey;

  const PersonalInfoSection({
    super.key,
    this.personalInfo,
    required this.onChanged,
    this.formKey,
  });

  @override
  State<PersonalInfoSection> createState() => _PersonalInfoSectionState();
}

class _PersonalInfoSectionState extends State<PersonalInfoSection> {
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;
  late TextEditingController _villeController;
  late TextEditingController _codePostalController;
  late TextEditingController _paysController;
  late TextEditingController _titrePosteController;
  late TextEditingController _linkedInController;
  late TextEditingController _portfolioController;
  late TextEditingController _resumeController;

  String? _photoPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final info = widget.personalInfo;
    _nomController = TextEditingController(text: info?.nom);
    _prenomController = TextEditingController(text: info?.prenom);
    _emailController = TextEditingController(text: info?.email);
    _telephoneController = TextEditingController(text: info?.telephone);
    _adresseController = TextEditingController(text: info?.adresse);
    _villeController = TextEditingController(text: info?.ville);
    _codePostalController = TextEditingController(text: info?.codePostal);
    _paysController = TextEditingController(text: info?.pays);
    _titrePosteController = TextEditingController(text: info?.titrePoste);
    _linkedInController = TextEditingController(text: info?.linkedIn);
    _portfolioController = TextEditingController(text: info?.portfolio);
    _resumeController = TextEditingController(text: info?.resumeProfessionnel);
    _photoPath = info?.photoUrl;
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _photoPath = picked.path);
      _updatePersonalInfo();
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _paysController.dispose();
    _titrePosteController.dispose();
    _linkedInController.dispose();
    _portfolioController.dispose();
    _resumeController.dispose();
    super.dispose();
  }

  void _updatePersonalInfo() {
    widget.onChanged(PersonalInfo(
      nom: _nomController.text.isNotEmpty ? _nomController.text : null,
      prenom: _prenomController.text.isNotEmpty ? _prenomController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      telephone: _telephoneController.text.isNotEmpty ? _telephoneController.text : null,
      adresse: _adresseController.text.isNotEmpty ? _adresseController.text : null,
      ville: _villeController.text.isNotEmpty ? _villeController.text : null,
      codePostal: _codePostalController.text.isNotEmpty ? _codePostalController.text : null,
      pays: _paysController.text.isNotEmpty ? _paysController.text : null,
      titrePoste: _titrePosteController.text.isNotEmpty ? _titrePosteController.text : null,
      linkedIn: _linkedInController.text.isNotEmpty ? _linkedInController.text : null,
      portfolio: _portfolioController.text.isNotEmpty ? _portfolioController.text : null,
      resumeProfessionnel: _resumeController.text.isNotEmpty ? _resumeController.text : null,
      photoUrl: _photoPath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Photo de profil
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _photoPath != null
                        ? FileImage(File(_photoPath!))
                        : null,
                    child: _photoPath == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom *'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _updatePersonalInfo(),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _updatePersonalInfo(),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titrePosteController,
            decoration: const InputDecoration(
              labelText: 'Titre du poste',
              hintText: 'Ex: Developpeur Web',
            ),
            onChanged: (_) => _updatePersonalInfo(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _updatePersonalInfo(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(v.trim())) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telephoneController,
            decoration: const InputDecoration(
              labelText: 'Telephone',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _updatePersonalInfo(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adresseController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.location_on),
            ),
            onChanged: (_) => _updatePersonalInfo(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _villeController,
                  decoration: const InputDecoration(labelText: 'Ville'),
                  onChanged: (_) => _updatePersonalInfo(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _codePostalController,
                  decoration: const InputDecoration(labelText: 'Code postal'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updatePersonalInfo(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paysController,
            decoration: const InputDecoration(labelText: 'Pays'),
            onChanged: (_) => _updatePersonalInfo(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _linkedInController,
            decoration: const InputDecoration(
              labelText: 'LinkedIn',
              prefixIcon: Icon(Icons.link),
              hintText: 'https://linkedin.com/in/...',
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => _updatePersonalInfo(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _portfolioController,
            decoration: const InputDecoration(
              labelText: 'Portfolio / Site web',
              prefixIcon: Icon(Icons.language),
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => _updatePersonalInfo(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _resumeController,
            decoration: const InputDecoration(
              labelText: 'Resume professionnel',
              hintText: 'Decrivez-vous en quelques phrases...',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            onChanged: (_) => _updatePersonalInfo(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
    );
  }
}
