import 'package:flutter/material.dart';
import '../../../models/cv.dart';

class PersonalInfoSection extends StatefulWidget {
  final PersonalInfo? personalInfo;
  final Function(PersonalInfo) onChanged;

  const PersonalInfoSection({
    super.key,
    this.personalInfo,
    required this.onChanged,
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prenom'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _updatePersonalInfo(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _updatePersonalInfo(),
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
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _updatePersonalInfo(),
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
    );
  }
}
