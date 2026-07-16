import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cv.dart';
import '../../services/i_api_client.dart';
import '../../services/share_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/pdf_saver.dart';
import '../../widgets/cv_preview.dart';
import '../../widgets/public_qr_code.dart';

class PublicPortfolioScreen extends StatefulWidget {
  final String token;

  const PublicPortfolioScreen({super.key, required this.token});

  @override
  State<PublicPortfolioScreen> createState() => _PublicPortfolioScreenState();
}

class _PublicPortfolioScreenState extends State<PublicPortfolioScreen> {
  Cv? _cv;
  String? _error;
  bool _loading = true;
  String? _downloading;

  String get _publicUrl =>
      context.read<ShareService>().buildPublicPortfolioUrl(widget.token);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cv = await context.read<IApiClient>().getPublicCv(widget.token);
      if (mounted) setState(() => _cv = cv);
    } catch (_) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        setState(() => _error = l.publicPortfolioUnavailable);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(String format) async {
    setState(() => _downloading = format);
    try {
      final bytes = await context
          .read<IApiClient>()
          .downloadPublicCv(widget.token, format);
      await saveBytes(
        bytes,
        'moncv.$format',
        format == 'pdf'
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  Future<void> _contact() async {
    final email = _cv?.personalInfo?.email;
    if (email == null || email.isEmpty) return;
    await launchUrl(Uri(scheme: 'mailto', path: email));
  }

  Future<void> _shareWhatsApp() async {
    final api = context.read<IApiClient>();
    final share = context.read<ShareService>();
    await api.trackPublicShare(widget.token);
    await share.shareToWhatsApp(
          _publicUrl,
          title: _cv?.titre,
        );
  }

  void _showQr() {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.portfolioQrCode),
        content: PublicQrCode(url: _publicUrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.publicSurface,
      body: Column(
        children: [
          _PublicHeader(
            cv: _cv,
            downloading: _downloading,
            onContact: _contact,
            onDownload: _download,
            onQr: _showQr,
            onWhatsApp: _shareWhatsApp,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _cv == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded,
                  size: 52, color: AppColors.neutral350),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
      );
    }
    return CvPreviewWidget(cv: _cv!);
  }
}

class _PublicHeader extends StatelessWidget {
  final Cv? cv;
  final String? downloading;
  final VoidCallback onContact;
  final ValueChanged<String> onDownload;
  final VoidCallback onQr;
  final VoidCallback onWhatsApp;

  const _PublicHeader({
    required this.cv,
    required this.downloading,
    required this.onContact,
    required this.onDownload,
    required this.onQr,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final l = AppLocalizations.of(context)!;
    final actions = <Widget>[
      IconButton(
        tooltip: l.showQrCode,
        onPressed: cv == null ? null : onQr,
        icon: const Icon(Icons.qr_code_2_rounded),
      ),
      IconButton(
        tooltip: l.shareViaWhatsApp,
        onPressed: cv == null ? null : onWhatsApp,
        icon: const Icon(Icons.chat_outlined),
      ),
      if (cv?.publicDownloadsEnabled == true)
        PopupMenuButton<String>(
          tooltip: l.download,
          onSelected: onDownload,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'pdf', child: Text(l.downloadPdf)),
            PopupMenuItem(value: 'docx', child: Text(l.downloadDocx)),
          ],
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: downloading == null
                ? const Icon(Icons.download_outlined)
                : const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        ),
      if (cv?.publicContactEnabled == true &&
          cv?.personalInfo?.email?.isNotEmpty == true)
        FilledButton.icon(
          onPressed: onContact,
          icon: const Icon(Icons.mail_outline, size: 18),
          label: Text(compact ? l.contact : l.contactCandidate),
        ),
    ];

    return Material(
      color: Colors.white,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: compact ? 12 : 28, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.description_outlined,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MonCV',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    if (!compact && cv != null)
                      Text(
                        cv!.personalInfo?.fullName.isNotEmpty == true
                            ? cv!.personalInfo!.fullName
                            : cv!.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.neutral500),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
