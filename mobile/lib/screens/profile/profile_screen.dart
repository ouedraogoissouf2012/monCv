import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/theme_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cvProvider = context.watch<CvProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final cvCount = cvProvider.cvs.length;

    return AppScaffold(
      currentIndex: 2,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Avatar + nom
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        _initials(user?.fullName),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? 'Utilisateur',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistiques
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.description_outlined,
                    label: 'CVs créés',
                    value: '$cvCount',
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _StatCard(
                    icon: Icons.download_outlined,
                    label: 'Téléchargements',
                    value: '—',
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _StatCard(
                    icon: Icons.share_outlined,
                    label: 'Partages',
                    value: '—',
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Informations
            const _SectionTitle('Informations'),
            const SizedBox(height: 12),
            _InfoCard(children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Nom complet',
                value: user?.fullName ?? '—',
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user?.email ?? '—',
              ),
            ]),

            const SizedBox(height: 28),

            // Apparence
            const _SectionTitle('Apparence'),
            const SizedBox(height: 12),
            const ThemeSelector(),

            const SizedBox(height: 32),

            const _SectionTitle('Confidentialité'),
            const SizedBox(height: 12),
            _InfoCard(children: [
              _ActionRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Politique de confidentialité',
                value: 'Données, IA, export et suppression',
                onTap: () => context.push('/privacy'),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.file_download_outlined,
                label: 'Exporter mes données',
                value: 'Copie JSON de votre compte et de vos CV',
                onTap: () => _exportUserData(context),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.delete_forever_outlined,
                label: 'Supprimer mon compte',
                value: 'Suppression du compte et des CV associés',
                danger: true,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ]),

            const SizedBox(height: 32),

            // Déconnexion
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await ApiService().exportUserData();
      const encoder = JsonEncoder.withIndent('  ');
      await Clipboard.setData(ClipboardData(text: encoder.convert(data)));
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Export copié dans le presse-papier'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF10B981),
      ));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Export impossible : $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action supprime votre compte et les CV associés côté serveur. Elle est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final rootContext = context;
              Navigator.pop(ctx);
              try {
                await ApiService().deleteAccount();
                if (!rootContext.mounted) return;
                rootContext.read<AuthProvider>().logout();
                rootContext.go('/landing');
              } catch (e) {
                if (!rootContext.mounted) return;
                ScaffoldMessenger.of(rootContext).showSnackBar(SnackBar(
                  content: Text('Suppression impossible : $e'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        )),
                const SizedBox(height: 2),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
    );
  }
}
