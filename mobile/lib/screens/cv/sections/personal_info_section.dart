import 'package:flutter/material.dart';
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Identité ───────────────────────────────────
          const _GroupLabel('IDENTITÉ'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomCtrl,
                  decoration: const InputDecoration(labelText: 'Prénom *'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _notify(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _notify(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titrePosteCtrl,
            decoration: const InputDecoration(
              labelText: 'Titre du poste',
              hintText: 'Ex : Développeur Web Senior',
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
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _notify(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telCtrl,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _notify(),
          ),

          // ── Localisation ───────────────────────────────
          const SizedBox(height: 20),
          const _GroupLabel('LOCALISATION'),
          TextFormField(
            controller: _adresseCtrl,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _villeCtrl,
                  decoration: const InputDecoration(labelText: 'Ville'),
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cpCtrl,
                  decoration: const InputDecoration(labelText: 'Code postal'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paysCtrl,
            decoration: const InputDecoration(
              labelText: 'Pays',
              prefixIcon: Icon(Icons.flag_outlined, size: 20),
            ),
            onChanged: (_) => _notify(),
          ),

          // ── En ligne ───────────────────────────────────
          const SizedBox(height: 20),
          const _GroupLabel('EN LIGNE'),
          TextFormField(
            controller: _linkedInCtrl,
            decoration: const InputDecoration(
              labelText: 'LinkedIn',
              prefixIcon: Icon(Icons.link_rounded, size: 20),
              hintText: 'linkedin.com/in/...',
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
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => _notify(),
          ),

          // ── À propos ───────────────────────────────────
          const SizedBox(height: 20),
          const _GroupLabel('À PROPOS'),
          TextFormField(
            controller: _resumeCtrl,
            decoration: const InputDecoration(
              labelText: 'Résumé professionnel',
              hintText: 'Décrivez-vous en quelques phrases...',
              alignLabelWithHint: true,
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

// ── Widget helper ─────────────────────────────────────────────

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
