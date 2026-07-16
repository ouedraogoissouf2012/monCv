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
import 'widgets/public_portfolio_header.dart';

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
  bool _sharing = false;
  int _loadVersion = 0;

  String get _publicUrl =>
      context.read<ShareService>().buildPublicPortfolioUrl(widget.token);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PublicPortfolioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token == widget.token) return;
    setState(() {
      _cv = null;
      _error = null;
      _loading = true;
    });
    _load();
  }

  @override
  void dispose() {
    _loadVersion++;
    super.dispose();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    final token = widget.token;
    try {
      final cv = await context.read<IApiClient>().getPublicCv(token);
      if (_isCurrentLoad(version, token)) setState(() => _cv = cv);
    } catch (_) {
      if (!mounted || version != _loadVersion || token != widget.token) return;
      final unavailableMessage =
          AppLocalizations.of(context)!.publicPortfolioUnavailable;
      setState(() => _error = unavailableMessage);
    } finally {
      if (_isCurrentLoad(version, token)) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isCurrentLoad(int version, String token) =>
      mounted && version == _loadVersion && token == widget.token;

  Future<void> _download(String format) async {
    if (_downloading != null) return;
    final token = widget.token;
    setState(() => _downloading = format);
    try {
      final bytes = await context.read<IApiClient>().downloadPublicCv(
            token,
            format,
          );
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
    if (email == null || email.isEmpty || email.contains(RegExp(r'[\r\n]'))) {
      return;
    }
    await launchUrl(Uri(scheme: 'mailto', path: email));
  }

  Future<void> _shareWhatsApp() async {
    if (_sharing) return;
    final shareService = context.read<ShareService>();
    final apiClient = context.read<IApiClient>();
    setState(() => _sharing = true);
    try {
      final launched = await shareService.shareToWhatsApp(
        _publicUrl,
        title: _cv?.titre,
      );
      if (launched) {
        try {
          await apiClient.trackPublicShare(widget.token);
        } catch (_) {
          // Une metrique indisponible ne doit jamais bloquer le partage.
        }
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
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
          PublicPortfolioHeader(
            cv: _cv,
            downloading: _downloading,
            sharing: _sharing,
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
              const Icon(
                Icons.link_off_rounded,
                size: 52,
                color: AppColors.neutral350,
              ),
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
