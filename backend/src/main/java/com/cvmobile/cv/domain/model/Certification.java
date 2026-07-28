package com.cvmobile.cv.domain.model;

import java.time.LocalDate;

/**
 * Certification figurant sur un CV (valeur de domaine immuable).
 *
 * <p>Tous les champs hormis l'identifiant sont facultatifs.
 *
 * @param id             identifiant technique, {@code null} tant que non persiste
 * @param nom            intitule de la certification, ou {@code null}
 * @param organisme      organisme emetteur, ou {@code null}
 * @param dateObtention  date d'obtention, ou {@code null}
 * @param dateExpiration date d'expiration, ou {@code null}
 * @param credentialUrl  lien de verification, ou {@code null}
 */
public record Certification(
        Long id,
        String nom,
        String organisme,
        LocalDate dateObtention,
        LocalDate dateExpiration,
        String credentialUrl) {

    /**
     * Construit une certification en normalisant les champs texte.
     */
    public static Certification of(
            Long id,
            String nom,
            String organisme,
            LocalDate dateObtention,
            LocalDate dateExpiration,
            String credentialUrl) {
        return new Certification(
                id,
                DomainText.normalize(nom),
                DomainText.normalize(organisme),
                dateObtention,
                dateExpiration,
                DomainText.normalize(credentialUrl));
    }
}
