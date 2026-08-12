import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../../../utils/app_colors.dart';

class PublicPortfolioHeader extends StatelessWidget {
  const PublicPortfolioHeader({
    super.key,
    required this.cv,
    required this.downloading,
    required this.sharing,
    required this.onContact,
    required this.onDownload,
    required this.onQr,
    required this.onWhatsApp,
  });

  final Cv? cv;
  final String? downloading;
  final bool sharing;
  final VoidCallback onContact;
  final ValueChanged<String> onDownload;
  final VoidCallback onQr;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Material(
      color: Colors.white,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 28,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _PortfolioIdentity(cv: cv, compact: compact)),
              ..._actions(context, compact),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, bool compact) {
    final l = AppLocalizations.of(context)!;
    return [
      IconButton(
        tooltip: l.showQrCode,
        onPressed: cv == null ? null : onQr,
        icon: const Icon(Icons.qr_code_2_rounded),
      ),
      IconButton(
        tooltip: l.shareViaWhatsApp,
        onPressed: cv == null || sharing ? null : onWhatsApp,
        icon: sharing
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chat_outlined),
      ),
      if (cv?.publicDownloadsEnabled == true)
        PopupMenuButton<String>(
          tooltip: l.download,
          enabled: downloading == null,
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
  }
}

class _PortfolioIdentity extends StatelessWidget {
  const _PortfolioIdentity({required this.cv, required this.compact});

  final Cv? cv;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MonCV',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (!compact && cv != null)
          Text(
            cv!.personalInfo?.fullName.isNotEmpty == true
                ? cv!.personalInfo!.fullName
                : cv!.titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
      ],
    );
  }
}
