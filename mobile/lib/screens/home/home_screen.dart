// mobile/lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cv_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cv_card.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CvProvider>().loadCvs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return AppScaffold(
      currentIndex: 0,
      title: 'Mes CVs',
      actions: isDesktop
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/cvs/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau CV'),
                ),
              ),
            ]
          : null,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/cvs/create'),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau CV'),
            ),
      body: Consumer<CvProvider>(
        builder: (context, cvProvider, _) {
          if (cvProvider.isLoading && cvProvider.cvs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cvProvider.cvs.isEmpty) {
            return const _EmptyState();
          }
          final crossAxisCount = isDesktop
              ? (MediaQuery.of(context).size.width > 1200 ? 3 : 2)
              : 1;
          return GridView.builder(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.4,
            ),
            itemCount: cvProvider.cvs.length,
            itemBuilder: (context, index) {
              final cv = cvProvider.cvs[index];
              return CvCard(
                cv: cv,
                onTap: () => context.push('/cvs/${cv.id}'),
                onEdit: () => context.push('/cvs/${cv.id}/edit', extra: cv),
                onDownloadPdf: () => _downloadPdf(context, cv.id!),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, int cvId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final apiService = ApiService();
      await apiService.downloadCvPdf(cvId);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erreur téléchargement PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.description_outlined,
                  size: 50, color: colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun CV pour l\'instant',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier CV professionnel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/cvs/create'),
              icon: const Icon(Icons.add),
              label: const Text('Créer mon premier CV'),
            ),
          ],
        ),
      ),
    );
  }
}
