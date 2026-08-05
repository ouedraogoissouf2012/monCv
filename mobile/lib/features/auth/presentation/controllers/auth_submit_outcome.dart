/// Issue d'une tentative de soumission d'authentification (issue #248, C3).
///
/// Distingue explicitement l'erreur de validation LOCALE (aucun appel reseau)
/// de l'erreur BACKEND (crit. #248 : erreurs backend distinguees des erreurs de
/// validation locale).
enum AuthSubmitOutcome { success, invalidInput, backendError }
