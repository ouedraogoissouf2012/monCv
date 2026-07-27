package com.cvmobile.cv.domain.model;

import java.time.LocalDate;

/**
 * Projet figurant sur un CV (valeur de domaine immuable).
 *
 * <p>Tous les champs hormis l'identifiant sont facultatifs.
 *
 * @param id           identifiant technique, {@code null} tant que non persiste
 * @param nom          intitule du projet, ou {@code null}
 * @param description  description du projet, ou {@code null}
 * @param technologies technologies employees, ou {@code null}
 * @param lien         lien vers le projet, ou {@code null}
 * @param dateDebut    debut du projet, ou {@code null}
 * @param dateFin      fin du projet, ou {@code null}
 */
public record Project(
        Long id,
        String nom,
        String description,
        String technologies,
        String lien,
        LocalDate dateDebut,
        LocalDate dateFin) {

    /**
     * Construit un projet en normalisant les champs texte.
     */
    public static Project of(
            Long id,
            String nom,
            String description,
            String technologies,
            String lien,
            LocalDate dateDebut,
            LocalDate dateFin) {
        return new Project(
                id,
                DomainText.normalize(nom),
                DomainText.normalize(description),
                DomainText.normalize(technologies),
                DomainText.normalize(lien),
                dateDebut,
                dateFin);
    }

    /**
     * Derive une copie avec une nouvelle description (adaptation IA des
     * variantes), sans muter l'original.
     */
    public Project withDescription(String newDescription) {
        return new Project(
                id, nom, DomainText.normalize(newDescription), technologies, lien,
                dateDebut, dateFin);
    }
}
