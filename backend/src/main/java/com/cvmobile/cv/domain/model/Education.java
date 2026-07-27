package com.cvmobile.cv.domain.model;

import java.time.LocalDate;

/**
 * Formation figurant sur un CV (valeur de domaine immuable).
 *
 * <p>Tous les champs sont facultatifs pour permettre l'edition partielle.
 *
 * @param id            identifiant technique, {@code null} tant que non persiste
 * @param etablissement nom de l'etablissement, ou {@code null}
 * @param diplome       intitule du diplome, ou {@code null}
 * @param domaine       domaine d'etude, ou {@code null}
 * @param dateDebut     debut de la periode, ou {@code null}
 * @param dateFin       fin de la periode, ou {@code null}
 * @param description   details, ou {@code null}
 */
public record Education(
        Long id,
        String etablissement,
        String diplome,
        String domaine,
        LocalDate dateDebut,
        LocalDate dateFin,
        String description) {

    /**
     * Construit une formation en normalisant les champs texte.
     */
    public static Education of(
            Long id,
            String etablissement,
            String diplome,
            String domaine,
            LocalDate dateDebut,
            LocalDate dateFin,
            String description) {
        return new Education(
                id,
                DomainText.normalize(etablissement),
                DomainText.normalize(diplome),
                DomainText.normalize(domaine),
                dateDebut,
                dateFin,
                DomainText.normalize(description));
    }

    /**
     * Derive une copie avec une nouvelle description (adaptation IA des
     * variantes), sans muter l'original.
     */
    public Education withDescription(String newDescription) {
        return new Education(
                id, etablissement, diplome, domaine, dateDebut, dateFin,
                DomainText.normalize(newDescription));
    }
}
