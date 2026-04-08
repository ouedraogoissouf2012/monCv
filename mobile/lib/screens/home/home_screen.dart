import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cv_provider.dart';
import '../../services/api_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cv_card.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';

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
      actions: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Importer un CV (PDF/DOCX)',
              onPressed: () => _importCv(context),
            ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/cvs/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau CV'),
                ),
              ),
          ],
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
              ? (MediaQuery.of(context).size.width >= 1200 ? 3 : 2)
              : 1;
          return Column(
            children: [
              if (cvProvider.isOffline) const _OfflineBanner(),
              Expanded(child: GridView.builder(
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
                onDownloadPdf: () => _downloadPdf(context, cv),
                onDownloadDocx: () => _downloadDocx(context, cv.id!),
                onDelete: () => _confirmDelete(context, cv.id!, cv.titre),
                onDuplicate: () => _duplicateCv(context, cv.id!),
                onShare: () => _shareLink(context, cv.id!),
              );
            },
          )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, int cvId, String titre) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final cvProvider = context.read<CvProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le CV'),
        content: Text('Voulez-vous vraiment supprimer "$titre" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await cvProvider.deleteCv(cvId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'CV supprimé' : cvProvider.error ?? 'Erreur'),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            success ? const Color(0xFF10B981) : errorColor,
      ),
    );
  }

  Future<void> _duplicateCv(BuildContext context, int cvId) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final cvProvider = context.read<CvProvider>();

    final success = await cvProvider.duplicateCv(cvId);
    messenger.showSnackBar(
      SnackBar(
        content:
            Text(success ? 'CV dupliqué ✓' : cvProvider.error ?? 'Erreur'),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            success ? const Color(0xFF10B981) : errorColor,
      ),
    );
  }

  Future<void> _shareLink(BuildContext context, int cvId) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final url = await ShareService().generateShareLink(cvId);
      if (!mounted || url == null) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lien de partage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Partagez ce lien pour que n\'importe qui puisse voir votre CV :',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
            FilledButton.icon(
              onPressed: () {
                ShareService().copyToClipboard(url);
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Lien copié dans le presse-papier ✓'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copier'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadPdf(BuildContext context, cv) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Génération du PDF en cours…'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    try {
      await PdfService().downloadPdf(cv);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF téléchargé ✓'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur PDF: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importCv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final cvProvider = context.read<CvProvider>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Import du CV en cours...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final cv = await ApiService().importCv(file.path!, file.name);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('CV "${cv.titre}" importe avec succes'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      await cvProvider.loadCvs();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur import: ${e.toString().replaceAll('Exception: ', '')}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadDocx(BuildContext context, int cvId) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Telechargement DOCX en cours...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    try {
      await PdfService().downloadDocx(cvId);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('DOCX telecharge'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur DOCX: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF59E0B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode hors ligne — données en cache',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
