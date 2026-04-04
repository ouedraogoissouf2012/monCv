import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../models/cv.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';

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
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _adresseCtrl;
  late TextEditingController _villeCtrl;
  late TextEditingController _cpCtrl;
  late TextEditingController _paysCtrl;
  late TextEditingController _titrePosteCtrl;
  late TextEditingController _linkedInCtrl;
  late TextEditingController _portfolioCtrl;
  late TextEditingController _resumeCtrl;

  String? _photoUrl;
  bool _uploadingPhoto = false;
  Uint8List? _photoBytes; // Pour afficher localement en web

  // Indicatifs téléphoniques par pays
  static const _countryDialCodes = <String, String>{
    'Afghanistan': '+93', 'Afrique du Sud': '+27', 'Albanie': '+355',
    'Algérie': '+213', 'Allemagne': '+49', 'Angola': '+244',
    'Arabie Saoudite': '+966', 'Argentine': '+54', 'Arménie': '+374',
    'Australie': '+61', 'Autriche': '+43', 'Azerbaïdjan': '+994',
    'Bahreïn': '+973', 'Bangladesh': '+880', 'Belgique': '+32',
    'Bénin': '+229', 'Biélorussie': '+375', 'Bolivie': '+591',
    'Bosnie-Herzégovine': '+387', 'Brésil': '+55', 'Bulgarie': '+359',
    'Burkina Faso': '+226', 'Burundi': '+257', 'Cambodge': '+855',
    'Cameroun': '+237', 'Canada': '+1', 'Chili': '+56', 'Chine': '+86',
    'Chypre': '+357', 'Colombie': '+57', 'Congo': '+242',
    'Corée du Sud': '+82', 'Costa Rica': '+506', "Côte d'Ivoire": '+225',
    'Croatie': '+385', 'Cuba': '+53', 'Danemark': '+45', 'Djibouti': '+253',
    'Égypte': '+20', 'Émirats arabes unis': '+971', 'Équateur': '+593',
    'Espagne': '+34', 'Estonie': '+372', 'Éthiopie': '+251',
    'Finlande': '+358', 'France': '+33', 'Gabon': '+241', 'Géorgie': '+995',
    'Ghana': '+233', 'Grèce': '+30', 'Guatemala': '+502', 'Guinée': '+224',
    'Haïti': '+509', 'Hongrie': '+36', 'Inde': '+91', 'Indonésie': '+62',
    'Irak': '+964', 'Iran': '+98', 'Irlande': '+353', 'Islande': '+354',
    'Israël': '+972', 'Italie': '+39', 'Japon': '+81', 'Jordanie': '+962',
    'Kazakhstan': '+7', 'Kenya': '+254', 'Kosovo': '+383', 'Koweït': '+965',
    'Laos': '+856', 'Lettonie': '+371', 'Liban': '+961', 'Libye': '+218',
    'Lituanie': '+370', 'Luxembourg': '+352', 'Madagascar': '+261',
    'Malaisie': '+60', 'Mali': '+223', 'Maroc': '+212', 'Maurice': '+230',
    'Mauritanie': '+222', 'Mexique': '+52', 'Moldova': '+373',
    'Mongolie': '+976', 'Monténégro': '+382', 'Mozambique': '+258',
    'Myanmar': '+95', 'Namibie': '+264', 'Népal': '+977',
    'Nicaragua': '+505', 'Niger': '+227', 'Nigéria': '+234',
    'Norvège': '+47', 'Nouvelle-Zélande': '+64', 'Oman': '+968',
    'Ouganda': '+256', 'Ouzbékistan': '+998', 'Pakistan': '+92',
    'Panama': '+507', 'Paraguay': '+595', 'Pays-Bas': '+31', 'Pérou': '+51',
    'Philippines': '+63', 'Pologne': '+48', 'Portugal': '+351',
    'Qatar': '+974', 'République tchèque': '+420', 'Roumanie': '+40',
    'Royaume-Uni': '+44', 'Russie': '+7', 'Rwanda': '+250',
    'Sénégal': '+221', 'Serbie': '+381', 'Sierra Leone': '+232',
    'Singapour': '+65', 'Slovaquie': '+421', 'Slovénie': '+386',
    'Somalie': '+252', 'Soudan': '+249', 'Sri Lanka': '+94', 'Suède': '+46',
    'Suisse': '+41', 'Syrie': '+963', 'Taïwan': '+886', 'Tanzanie': '+255',
    'Thaïlande': '+66', 'Togo': '+228', 'Tunisie': '+216',
    'Turkménistan': '+993', 'Turquie': '+90', 'Ukraine': '+380',
    'Uruguay': '+598', 'Venezuela': '+58', 'Vietnam': '+84',
    'Yémen': '+967', 'Zimbabwe': '+263',
  };

  @override
  void initState() {
    super.initState();
    final i = widget.personalInfo;
    _nomCtrl = TextEditingController(text: i?.nom);
    _prenomCtrl = TextEditingController(text: i?.prenom);
    _emailCtrl = TextEditingController(text: i?.email);
    _telCtrl = TextEditingController(text: i?.telephone);
    _adresseCtrl = TextEditingController(text: i?.adresse);
    _villeCtrl = TextEditingController(text: i?.ville);
    _cpCtrl = TextEditingController(text: i?.codePostal);
    _paysCtrl = TextEditingController(text: i?.pays);
    _titrePosteCtrl = TextEditingController(text: i?.titrePoste);
    _linkedInCtrl = TextEditingController(text: i?.linkedIn);
    _portfolioCtrl = TextEditingController(text: i?.portfolio);
    _resumeCtrl = TextEditingController(text: i?.resumeProfessionnel);
    _photoUrl = i?.photoUrl;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await _showSourceDialog();
    if (source == null || !mounted) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      // Lire les bytes pour affichage immediat
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      // Afficher localement tout de suite
      setState(() {
        _photoBytes = bytes;
        _uploadingPhoto = false;
      });

      // Tenter l'upload au backend en arriere-plan
      try {
        String url;
        if (kIsWeb) {
          url = await ApiService().uploadPhotoBytes(
            bytes,
            picked.name,
            picked.mimeType ?? 'image/jpeg',
          );
        } else {
          url = await ApiService().uploadPhoto(picked);
        }
        if (!mounted) return;
        setState(() {
          _photoUrl = ApiConstants.baseUrl.replaceAll('/api', '') + url;
        });
      } catch (e) {
        // Upload echoue — la photo reste affichee localement via _photoBytes
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Photo visible localement (upload: $e)'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ));
        }
      }
      _notify();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<ImageSource?> _showSourceDialog() {
    // En web, on va directement à la galerie (pas de caméra)
    if (kIsWeb) {
      return Future.value(ImageSource.gallery);
    }
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (_photoUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Supprimer la photo',
                    style:
                        TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _photoUrl = null;
                    _photoBytes = null;
                  });
                  _notify();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _cpCtrl.dispose();
    _paysCtrl.dispose();
    _titrePosteCtrl.dispose();
    _linkedInCtrl.dispose();
    _portfolioCtrl.dispose();
    _resumeCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(PersonalInfo(
      nom: _nomCtrl.text.isNotEmpty ? _nomCtrl.text : null,
      prenom: _prenomCtrl.text.isNotEmpty ? _prenomCtrl.text : null,
      email: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : null,
      telephone: _telCtrl.text.isNotEmpty ? _telCtrl.text : null,
      adresse: _adresseCtrl.text.isNotEmpty ? _adresseCtrl.text : null,
      ville: _villeCtrl.text.isNotEmpty ? _villeCtrl.text : null,
      codePostal: _cpCtrl.text.isNotEmpty ? _cpCtrl.text : null,
      pays: _paysCtrl.text.isNotEmpty ? _paysCtrl.text : null,
      titrePoste: _titrePosteCtrl.text.isNotEmpty ? _titrePosteCtrl.text : null,
      linkedIn: _linkedInCtrl.text.isNotEmpty ? _linkedInCtrl.text : null,
      portfolio: _portfolioCtrl.text.isNotEmpty ? _portfolioCtrl.text : null,
      resumeProfessionnel: _resumeCtrl.text.isNotEmpty ? _resumeCtrl.text : null,
      photoUrl: _photoUrl,
    ));
  }

  void _onCountryChanged(String country) {
    _paysCtrl.text = country;
    _notify();
    // Auto-ajouter l'indicatif au numéro si le champ est vide ou commence par 0
    final code = _countryDialCodes[country];
    if (code != null) {
      final tel = _telCtrl.text.trim();
      if (tel.isEmpty) {
        _telCtrl.text = '$code ';
        _telCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _telCtrl.text.length),
        );
      } else if (tel.startsWith('0')) {
        _telCtrl.text = '$code ${tel.substring(1)}';
        _telCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _telCtrl.text.length),
        );
      }
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Photo de profil ────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!) as ImageProvider
                        : _photoUrl != null
                            ? NetworkImage(_photoUrl!) as ImageProvider
                            : null,
                    child: _uploadingPhoto
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          )
                        : _photoUrl == null && _photoBytes == null
                            ? Icon(Icons.person_outline_rounded,
                                size: 40,
                                color: colorScheme.primary
                                    .withValues(alpha: 0.5))
                            : null,
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Photo de profil (optionnel)',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Identité ───────────────────────────────────
          const _GroupLabel('IDENTITÉ'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    helperText: 'Ex : Issouf',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _notify(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    helperText: 'Ex : Ouedraogo',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _notify(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titrePosteCtrl,
            decoration: const InputDecoration(
              labelText: 'Titre du poste',
              helperText: 'Le poste que vous visez ou occupez',
              hintText: 'Ex : Développeur Full Stack',
            ),
            onChanged: (_) => _notify(),
          ),

          // ── Coordonnées ────────────────────────────────
          const SizedBox(height: 20),
          const _GroupLabel('COORDONNÉES'),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email *',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              helperText: 'Votre email professionnel de contact',
              hintText: 'Ex : issouf.ouedraogo@email.com',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _notify(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
                return 'Email invalide (ex: nom@domaine.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telCtrl,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              helperText: _paysCtrl.text.isNotEmpty
                  ? 'Indicatif ${_countryDialCodes[_paysCtrl.text] ?? "auto"} ajouté selon le pays'
                  : 'Sélectionnez un pays pour l\'indicatif auto',
              hintText: 'Ex : +225 0544210112',
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _notify(),
          ),

          // ── Localisation ───────────────────────────────
          const SizedBox(height: 20),
          const _GroupLabel('LOCALISATION'),
          _PaysAutocomplete(
            controller: _paysCtrl,
            onChanged: _onCountryChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _villeCtrl,
            decoration: const InputDecoration(
              labelText: 'Ville',
              helperText: 'Optionnel — la ville où vous résidez',
              hintText: 'Ex : Abidjan',
            ),
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _adresseCtrl,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              helperText: 'Optionnel — votre adresse postale',
              hintText: 'Ex : Cocody, Riviera 3',
            ),
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cpCtrl,
            decoration: const InputDecoration(
              labelText: 'Code postal',
              helperText: 'Optionnel',
              hintText: 'Ex : 01 BP 1234',
            ),
            keyboardType: TextInputType.text,
            onChanged: (_) => _notify(),
          ),

          // ── En ligne ───────────────────────────────────
          const SizedBox(height: 20),
          const _GroupLabel('EN LIGNE'),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Optionnel — ajoutez vos liens professionnels',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          TextFormField(
            controller: _linkedInCtrl,
            decoration: const InputDecoration(
              labelText: 'LinkedIn',
              prefixIcon: Icon(Icons.link_rounded, size: 20),
              hintText: 'Ex : linkedin.com/in/issouf-ouedraogo',
              helperText: 'Optionnel — votre profil LinkedIn',
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _portfolioCtrl,
            decoration: const InputDecoration(
              labelText: 'Portfolio / Site web',
              prefixIcon: Icon(Icons.language_rounded, size: 20),
              hintText: 'Ex : github.com/issouf',
              helperText: 'Optionnel — votre site ou portfolio',
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => _notify(),
          ),

          // ── À propos ───────────────────────────────────
          const SizedBox(height: 20),
          Row(
            children: [
              const _GroupLabel('À PROPOS'),
              const Spacer(),
              _AiResumeButton(
                onGenerated: (text) {
                  setState(() => _resumeCtrl.text = text);
                  _notify();
                },
                titrePoste: _titrePosteCtrl.text,
              ),
            ],
          ),
          TextFormField(
            controller: _resumeCtrl,
            decoration: const InputDecoration(
              labelText: 'Resume professionnel',
              hintText: 'Ex : Developpeur Full Stack avec 3 ans d\'experience...',
              alignLabelWithHint: true,
              helperText: 'Cliquez sur le bouton IA pour generer automatiquement',
            ),
            maxLines: 4,
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Bouton IA pour generer le resume ──────────────────────────

class _AiResumeButton extends StatefulWidget {
  final Function(String) onGenerated;
  final String titrePoste;
  const _AiResumeButton({required this.onGenerated, required this.titrePoste});

  @override
  State<_AiResumeButton> createState() => _AiResumeButtonState();
}

class _AiResumeButtonState extends State<_AiResumeButton> {
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final resume = await ApiService().generateResume(
        widget.titrePoste,
        null,
        null,
      );
      if (!mounted) return;
      widget.onGenerated(resume);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Resume genere par l\'IA'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF10B981),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _loading ? null : _generate,
      icon: _loading
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_awesome_rounded, size: 16),
      label: Text(_loading ? 'Generation...' : 'Generer avec l\'IA',
          style: const TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        foregroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }
}

// ── Widget helper ─────────────────────────────────────────────

class _PaysAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  static const _countries = [
    'Afghanistan', 'Afrique du Sud', 'Albanie', 'Algérie', 'Allemagne',
    'Angola', 'Arabie Saoudite', 'Argentine', 'Arménie', 'Australie',
    'Autriche', 'Azerbaïdjan', 'Bahreïn', 'Bangladesh', 'Belgique',
    'Bénin', 'Biélorussie', 'Bolivie', 'Bosnie-Herzégovine', 'Brésil',
    'Bulgarie', 'Burkina Faso', 'Burundi', 'Cambodge', 'Cameroun',
    'Canada', 'Chili', 'Chine', 'Chypre', 'Colombie', 'Congo',
    'Corée du Sud', 'Costa Rica', "Côte d'Ivoire", 'Croatie', 'Cuba',
    'Danemark', 'Djibouti', 'Égypte', 'Émirats arabes unis', 'Équateur',
    'Espagne', 'Estonie', 'Éthiopie', 'Finlande', 'France', 'Gabon',
    'Géorgie', 'Ghana', 'Grèce', 'Guatemala', 'Guinée', 'Haïti',
    'Hongrie', 'Inde', 'Indonésie', 'Irak', 'Iran', 'Irlande',
    'Islande', 'Israël', 'Italie', 'Japon', 'Jordanie', 'Kazakhstan',
    'Kenya', 'Kosovo', 'Koweït', 'Laos', 'Lettonie', 'Liban',
    'Libye', 'Lituanie', 'Luxembourg', 'Madagascar', 'Malaisie',
    'Mali', 'Maroc', 'Maurice', 'Mauritanie', 'Mexique', 'Moldova',
    'Mongolie', 'Monténégro', 'Mozambique', 'Myanmar', 'Namibie',
    'Népal', 'Nicaragua', 'Niger', 'Nigéria', 'Norvège', 'Nouvelle-Zélande',
    'Oman', 'Ouganda', 'Ouzbékistan', 'Pakistan', 'Panama', 'Paraguay',
    'Pays-Bas', 'Pérou', 'Philippines', 'Pologne', 'Portugal', 'Qatar',
    'République tchèque', 'Roumanie', 'Royaume-Uni', 'Russie', 'Rwanda',
    'Sénégal', 'Serbie', 'Sierra Leone', 'Singapour', 'Slovaquie',
    'Slovénie', 'Somalie', 'Soudan', 'Sri Lanka', 'Suède', 'Suisse',
    'Syrie', 'Taïwan', 'Tanzanie', 'Thaïlande', 'Togo', 'Tunisie',
    'Turkménistan', 'Turquie', 'Ukraine', 'Uruguay', 'Venezuela',
    'Vietnam', 'Yémen', 'Zimbabwe',
  ];

  const _PaysAutocomplete({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const [];
        return _countries.where((c) => c
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        controller.text = selection;
        onChanged(selection);
      },
      fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
        ctrl.text = controller.text;
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Pays',
            prefixIcon: Icon(Icons.flag_outlined, size: 20),
            helperText: 'Sélectionnez pour ajouter l\'indicatif téléphonique',
            hintText: 'Ex : Côte d\'Ivoire',
          ),
          onChanged: (v) {
            controller.text = v;
            onChanged(v);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.flag_outlined, size: 16),
                    title: Text(option, style: const TextStyle(fontSize: 13)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

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
