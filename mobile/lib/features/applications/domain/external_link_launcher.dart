/// Resultat d'une tentative d'ouverture de lien externe (issue #246, A3).
///
/// Type ferme : la presentation mappe chaque cas vers un message localise. Le
/// domaine ne construit aucun texte utilisateur.
enum LinkLaunchResult {
  /// Ouverture reussie.
  success,

  /// URL vide, mal formee, ou schema non autorise (autre que http/https).
  invalidUrl,

  /// URL valide mais aucune application n'a pu l'ouvrir.
  couldNotLaunch,
}

/// Port d'ouverture d'un lien externe (issue #246, A3).
///
/// Abstrait `url_launcher` derriere le domaine, avec **validation** : seuls les
/// schemas `http`/`https` sont acceptes (le monolithe faisait
/// `launchUrl(Uri.tryParse(url))` sans controle — n'importe quel schema, dont
/// `javascript:`/`file:`, pouvait etre lance). Testable via un double.
abstract interface class ExternalLinkLauncher {
  Future<LinkLaunchResult> open(String? url);
}

/// Validation partagee des URLs externes (schemas autorises). Extraite pour
/// etre testable independamment de l'ouverture reelle.
abstract final class ExternalLinkPolicy {
  static const Set<String> allowedSchemes = {'http', 'https'};

  /// Analyse [url] et retourne l'[Uri] si (et seulement si) elle est absolue,
  /// possede un hote et un schema autorise ; sinon `null`.
  static Uri? validate(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) return null;
    if (!allowedSchemes.contains(uri.scheme.toLowerCase())) return null;
    return uri;
  }
}
