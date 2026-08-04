import 'package:url_launcher/url_launcher.dart';

import '../domain/external_link_launcher.dart';

/// Implementation de [ExternalLinkLauncher] sur `url_launcher` (issue #246, A3).
///
/// Valide d'abord l'URL via [ExternalLinkPolicy] (schemas http/https), puis
/// tente l'ouverture. Aucune exception ne fuit : les echecs deviennent des
/// [LinkLaunchResult].
class UrlLauncherLinkLauncher implements ExternalLinkLauncher {
  const UrlLauncherLinkLauncher();

  @override
  Future<LinkLaunchResult> open(String? url) async {
    final uri = ExternalLinkPolicy.validate(url);
    if (uri == null) return LinkLaunchResult.invalidUrl;
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      return launched
          ? LinkLaunchResult.success
          : LinkLaunchResult.couldNotLaunch;
    } catch (_) {
      // Plateforme sans navigateur / MissingPluginException : echec propre.
      return LinkLaunchResult.couldNotLaunch;
    }
  }
}
