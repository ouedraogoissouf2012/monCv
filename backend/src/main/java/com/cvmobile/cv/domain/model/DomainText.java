package com.cvmobile.cv.domain.model;

/**
 * Utilitaires de normalisation des champs texte du domaine CV.
 *
 * <p>Le domaine ne fait confiance a aucune source (formulaire, import, IA) :
 * il normalise systematiquement les chaines pour eviter des etats sales
 * (espaces superflus, chaine blanche traitee comme "renseignee"). Sans
 * dependance Spring/JPA — 100% domaine.
 */
final class DomainText {

    private DomainText() {
    }

    /**
     * Retire les espaces de bordure et convertit une chaine nulle ou blanche
     * en {@code null}, afin qu'un champ non renseigne soit representable de
     * facon unique.
     *
     * @param value la valeur brute, potentiellement nulle
     * @return la valeur nettoyee, ou {@code null} si vide/blanche
     */
    static String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.strip();
        return trimmed.isEmpty() ? null : trimmed;
    }

    /**
     * Exige qu'une valeur soit renseignee apres normalisation.
     *
     * @param value      la valeur brute
     * @param fieldName  le nom du champ pour le message d'erreur
     * @return la valeur normalisee, garantie non nulle et non blanche
     * @throws IllegalArgumentException si la valeur est nulle ou blanche
     */
    static String requireText(String value, String fieldName) {
        String normalized = normalize(value);
        if (normalized == null) {
            throw new IllegalArgumentException(
                    "Le champ '" + fieldName + "' est obligatoire et ne peut etre vide.");
        }
        return normalized;
    }
}
