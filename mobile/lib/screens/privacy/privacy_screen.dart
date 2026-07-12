import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/landing'),
        ),
        title: const Text('Confidentialité'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.verified_user_outlined,
              size: 42, color: colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            'Vos données restent sous votre contrôle',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'MonCV stocke les informations nécessaires à la création, l’édition, l’export et le partage de vos CV.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const _PrivacySection(
            title: 'Données stockées',
            items: [
              'Compte: email, nom et prénom.',
              'CV: identité, contacts, expériences, formations, compétences, langues, certifications, projets, style et liens de partage.',
              'Fichiers: photos importées et documents générés localement selon les actions demandées.',
            ],
          ),
          const _PrivacySection(
            title: 'Utilisation de l’IA',
            items: [
              'Aucun contenu de CV n’est envoyé à l’IA sans consentement explicite dans l’écran concerné.',
              'Les résultats IA sont affichés avant application et peuvent être refusés.',
              'En absence de clé IA, l’application utilise des corrections locales limitées quand elles existent.',
            ],
          ),
          const _PrivacySection(
            title: 'Vos droits',
            items: [
              'Vous pouvez exporter vos données depuis le profil.',
              'Vous pouvez supprimer votre compte depuis le profil.',
              'La suppression du compte supprime aussi les CV rattachés côté backend.',
            ],
          ),
          const _PrivacySection(
            title: 'Sécurité PWA',
            items: [
              'En production, l’application doit utiliser HTTPS et une API HTTPS.',
              'Le stockage web des tokens repose sur le stockage local du navigateur: utilisez un appareil de confiance.',
              'La cible recommandée pour une version entreprise est une session serveur avec cookies HttpOnly/SameSite.',
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _PrivacySection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
