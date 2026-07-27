package com.cvmobile.cv.domain.model;

/**
 * Langue maitrisee figurant sur un CV (valeur de domaine immuable).
 *
 * @param id     identifiant technique, {@code null} tant que non persiste
 * @param langue intitule de la langue (obligatoire)
 * @param niveau niveau CECRL, ou {@code null} si non renseigne
 */
public record Language(Long id, String langue, LanguageLevel niveau) {

    /**
     * Construit une langue en normalisant l'intitule et en validant l'invariant
     * (langue obligatoire).
     *
     * @throws IllegalArgumentException si la langue est vide ou blanche
     */
    public static Language of(Long id, String langue, LanguageLevel niveau) {
        return new Language(id, DomainText.requireText(langue, "langue"), niveau);
    }
}
