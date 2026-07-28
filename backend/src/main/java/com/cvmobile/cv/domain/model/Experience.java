package com.cvmobile.cv.domain.model;

import java.time.LocalDate;

/**
 * Experience professionnelle figurant sur un CV (valeur de domaine immuable).
 *
 * <p>Tous les champs sont facultatifs : un CV peut etre edite partiellement.
 * Le drapeau {@code actuel} vaut {@code false} par defaut lorsqu'il n'est pas
 * fourni, evitant un booleen null ambigu dans le reste du domaine.
 *
 * @param id          identifiant technique, {@code null} tant que non persiste
 * @param entreprise  employeur, ou {@code null}
 * @param poste       intitule du poste, ou {@code null}
 * @param lieu        localisation, ou {@code null}
 * @param dateDebut   debut de la periode, ou {@code null}
 * @param dateFin     fin de la periode, ou {@code null} si en cours
 * @param description missions et realisations, ou {@code null}
 * @param actuel      poste occupe actuellement (jamais {@code null})
 */
public record Experience(
        Long id,
        String entreprise,
        String poste,
        String lieu,
        LocalDate dateDebut,
        LocalDate dateFin,
        String description,
        boolean actuel) {

    /**
     * Construit une experience en normalisant les champs texte. {@code actuel}
     * est ramene a {@code false} lorsqu'il est {@code null}.
     */
    public static Experience of(
            Long id,
            String entreprise,
            String poste,
            String lieu,
            LocalDate dateDebut,
            LocalDate dateFin,
            String description,
            Boolean actuel) {
        return new Experience(
                id,
                DomainText.normalize(entreprise),
                DomainText.normalize(poste),
                DomainText.normalize(lieu),
                dateDebut,
                dateFin,
                DomainText.normalize(description),
                actuel != null && actuel);
    }

    /**
     * Derive une copie de cette experience avec une nouvelle description
     * (utilise par l'adaptation IA des variantes, sans muter l'original).
     */
    public Experience withDescription(String newDescription) {
        return new Experience(
                id, entreprise, poste, lieu, dateDebut, dateFin,
                DomainText.normalize(newDescription), actuel);
    }
}
