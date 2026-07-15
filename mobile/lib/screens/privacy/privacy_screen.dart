import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/landing'),
        ),
        title: Text(l.privacy),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.verified_user_outlined,
              size: 42, color: colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            l.privacyControlTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            l.privacyIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _PrivacySection(
            title: l.privacyStoredDataTitle,
            items: [
              l.privacyStoredAccount,
              l.privacyStoredCv,
              l.privacyStoredFiles,
            ],
          ),
          _PrivacySection(
            title: l.privacyAiTitle,
            items: [
              l.privacyAiConsent,
              l.privacyAiReview,
              l.privacyAiFallback,
            ],
          ),
          _PrivacySection(
            title: l.privacyRightsTitle,
            items: [
              l.privacyRightsExport,
              l.privacyRightsDelete,
              l.privacyRightsCascade,
            ],
          ),
          _PrivacySection(
            title: l.privacyPwaTitle,
            items: [
              l.privacyPwaHttps,
              l.privacyPwaStorage,
              l.privacyPwaEnterprise,
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
