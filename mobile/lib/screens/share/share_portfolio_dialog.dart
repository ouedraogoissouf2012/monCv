import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cv.dart';
import '../../services/i_api_client.dart';
import '../../services/share_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/public_qr_code.dart';

class SharePortfolioDialog extends StatefulWidget {
  final Cv cv;

  const SharePortfolioDialog({super.key, required this.cv});

  @override
  State<SharePortfolioDialog> createState() => _SharePortfolioDialogState();
}

class _SharePortfolioDialogState extends State<SharePortfolioDialog> {
  Cv? _cv;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? get _url {
    final token = _cv?.shareToken;
    return token == null
        ? null
        : context.read<ShareService>().buildPublicPortfolioUrl(token);
  }

  @override
  void initState() {
    super.initState();
    _activate();
  }

  Future<void> _activate() async {
    try {
      final cv =
          await context.read<IApiClient>().generateShareLink(widget.cv.id!);
      if (mounted) setState(() => _cv = cv);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible d’activer le lien public.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateSettings({bool? contact, bool? downloads}) async {
    final current = _cv;
    if (current == null || _saving) return;
    final contactEnabled = contact ?? current.publicContactEnabled;
    final downloadsEnabled = downloads ?? current.publicDownloadsEnabled;
    setState(() => _saving = true);
    try {
      final cv = await context.read<IApiClient>().updateShareSettings(
            current.id!,
            contactEnabled: contactEnabled,
            downloadsEnabled: downloadsEnabled,
          );
      if (mounted) setState(() => _cv = cv);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _regenerate() async {
    if (_cv == null || _saving) return;
    setState(() => _saving = true);
    try {
      final cv = await context.read<IApiClient>().regenerateShareLink(_cv!.id!);
      if (mounted) setState(() => _cv = cv);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    if (_cv == null || _saving) return;
    setState(() => _saving = true);
    await context.read<IApiClient>().deactivateShareLink(_cv!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _shareWhatsApp() async {
    final url = _url;
    if (url == null) return;
    await context.read<IApiClient>().trackPublicShare(_cv!.shareToken!);
    await context.read<ShareService>().shareToWhatsApp(url, title: _cv!.titre);
  }

  Future<void> _shareLinkedIn() async {
    final url = _url;
    if (url == null) return;
    await context.read<IApiClient>().trackPublicShare(_cv!.shareToken!);
    await context.read<ShareService>().shareToLinkedIn(url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Portfolio public recruteur'),
      content: SizedBox(
        width: 560,
        child: _loading
            ? const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Text(_error!)
                : SingleChildScrollView(child: _buildContent()),
      ),
      actions: [
        if (_cv != null)
          TextButton.icon(
            onPressed: _saving ? null : _deactivate,
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('Désactiver'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final cv = _cv!;
    final url = _url!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ce lien ouvre une présentation professionnelle de votre CV sans connexion.',
          style: TextStyle(color: AppColors.neutral500, height: 1.4),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Metric(
                label: 'Vues',
                value: cv.viewCount,
                icon: Icons.visibility_outlined),
            _Metric(
                label: 'Téléchargements',
                value: cv.downloadCount,
                icon: Icons.download_outlined),
            _Metric(
                label: 'Partages',
                value: cv.shareCount,
                icon: Icons.share_outlined),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral75,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(url,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  context.read<ShareService>().copyToClipboard(url),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copier'),
            ),
            OutlinedButton.icon(
              onPressed: _shareWhatsApp,
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp'),
            ),
            OutlinedButton.icon(
              onPressed: _shareLinkedIn,
              icon: const Icon(Icons.work_outline, size: 18),
              label: const Text('LinkedIn'),
            ),
            IconButton(
              tooltip: 'Régénérer le lien',
              onPressed: _saving ? null : _regenerate,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const Divider(height: 32),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: cv.publicContactEnabled,
          onChanged: _saving
              ? null
              : (value) => _updateSettings(
                    contact: value,
                    downloads: value ? null : false,
                  ),
          title: const Text('Autoriser le contact'),
          subtitle: const Text('Affiche l’e-mail et le bouton de contact.'),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: cv.publicDownloadsEnabled,
          onChanged: _saving
              ? null
              : (value) => _updateSettings(
                    contact: value ? true : null,
                    downloads: value,
                  ),
          title: const Text('Autoriser PDF et DOCX'),
          subtitle: const Text(
              'Les fichiers contiennent les coordonnées autorisées du CV.'),
        ),
        const Divider(height: 32),
        Center(child: PublicQrCode(url: url, size: 170)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral150),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.neutral500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
