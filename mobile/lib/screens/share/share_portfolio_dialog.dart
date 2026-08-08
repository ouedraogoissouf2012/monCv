import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/injection_container.dart';
import '../../core/error/result.dart';
import '../../features/cv_share/domain/cv_share_repository.dart';
import '../../features/public_portfolio/domain/public_portfolio_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cv.dart';
import '../../services/share_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/public_qr_code.dart';
import 'widgets/share_metric.dart';

class SharePortfolioDialog extends StatefulWidget {
  final Cv cv;

  /// Ports d'acces (issue #258). Injectables pour les tests ; par defaut
  /// resolus via le service locator, jamais le transport direct.
  final CvShareRepository? shareRepository;
  final PublicPortfolioRepository? publicPortfolioRepository;

  const SharePortfolioDialog({
    super.key,
    required this.cv,
    this.shareRepository,
    this.publicPortfolioRepository,
  });

  @override
  State<SharePortfolioDialog> createState() => _SharePortfolioDialogState();
}

class _SharePortfolioDialogState extends State<SharePortfolioDialog> {
  Cv? _cv;
  bool _loading = true;
  bool _saving = false;
  bool _sharing = false;
  String? _error;

  late final CvShareRepository _shareRepo =
      widget.shareRepository ?? sl<CvShareRepository>();
  late final PublicPortfolioRepository _publicPortfolio =
      widget.publicPortfolioRepository ?? sl<PublicPortfolioRepository>();

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
    final result = await _shareRepo.generateLink(widget.cv.id!);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() => _cv = data);
      case Failure():
        setState(() =>
            _error = AppLocalizations.of(context)!.publicLinkActivationFailed);
    }
    setState(() => _loading = false);
  }

  Future<void> _updateSettings({bool? contact, bool? downloads}) async {
    final current = _cv;
    if (current == null || _saving) return;
    final contactEnabled = contact ?? current.publicContactEnabled;
    final downloadsEnabled = downloads ?? current.publicDownloadsEnabled;
    setState(() => _saving = true);
    final result = await _shareRepo.updateSettings(
      current.id!,
      contactEnabled: contactEnabled,
      downloadsEnabled: downloadsEnabled,
    );
    if (!mounted) return;
    if (result case Success(:final data)) setState(() => _cv = data);
    setState(() => _saving = false);
  }

  Future<void> _regenerate() async {
    if (_cv == null || _saving) return;
    setState(() => _saving = true);
    final result = await _shareRepo.regenerateLink(_cv!.id!);
    if (!mounted) return;
    if (result case Success(:final data)) setState(() => _cv = data);
    setState(() => _saving = false);
  }

  Future<void> _deactivate() async {
    if (_cv == null || _saving) return;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final result = await _shareRepo.deactivateLink(_cv!.id!);
    if (!mounted) return;
    if (result.isSuccess) {
      navigator.pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _shareWhatsApp() async {
    final url = _url;
    final cv = _cv;
    if (url == null || cv?.shareToken == null || _sharing) return;
    final shareService = context.read<ShareService>();
    setState(() => _sharing = true);
    try {
      final launched =
          await shareService.shareToWhatsApp(url, title: cv!.titre);
      // trackShare est best-effort : le port absorbe toute erreur de metrique.
      if (launched) await _publicPortfolio.trackShare(cv.shareToken!);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareLinkedIn() async {
    final url = _url;
    final token = _cv?.shareToken;
    if (url == null || token == null || _sharing) return;
    final shareService = context.read<ShareService>();
    setState(() => _sharing = true);
    try {
      final launched = await shareService.shareToLinkedIn(url);
      if (launched) await _publicPortfolio.trackShare(token);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.publicRecruiterPortfolio),
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
            label: Text(l.deactivate),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.close),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final cv = _cv!;
    final url = _url!;
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.publicPortfolioDescription,
          style: const TextStyle(color: AppColors.neutral500, height: 1.4),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ShareMetric(
                label: l.views,
                value: cv.viewCount,
                icon: Icons.visibility_outlined),
            ShareMetric(
                label: l.downloads,
                value: cv.downloadCount,
                icon: Icons.download_outlined),
            ShareMetric(
                label: l.shares,
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
              label: Text(l.copy),
            ),
            OutlinedButton.icon(
              onPressed: _sharing ? null : _shareWhatsApp,
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp'),
            ),
            OutlinedButton.icon(
              onPressed: _sharing ? null : _shareLinkedIn,
              icon: const Icon(Icons.work_outline, size: 18),
              label: const Text('LinkedIn'),
            ),
            IconButton(
              tooltip: l.regeneratePublicLink,
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
          title: Text(l.allowPublicContact),
          subtitle: Text(l.allowPublicContactDescription),
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
          title: Text(l.allowPublicDownloads),
          subtitle: Text(l.allowPublicDownloadsDescription),
        ),
        const Divider(height: 32),
        Center(child: PublicQrCode(url: url, size: 170)),
      ],
    );
  }
}
