package com.cvmobile.cv.domain.model;

/**
 * Competence figurant sur un CV (valeur de domaine immuable).
 *
 * <p>Invariants : le nom est obligatoire; le niveau, s'il est renseigne, est
 * borne entre {@value #MIN_LEVEL} et {@value #MAX_LEVEL} (echelle metier). Ces
 * invariants sont ceux historiquement portes par les contraintes de validation
 * de la persistance, desormais garantis par le domaine lui-meme.
 *
 * @param id        identifiant technique, {@code null} tant que non persiste
 * @param nom       intitule de la competence (obligatoire)
 * @param niveau    maitrise sur [1,5], ou {@code null} si non renseignee
 * @param categorie regroupement libre (ex. "Backend"), ou {@code null}
 */
public record Skill(Long id, String nom, Integer niveau, String categorie) {

    private static final int MIN_LEVEL = 1;
    private static final int MAX_LEVEL = 5;

    /**
     * Construit une competence en normalisant les textes et en validant les
     * invariants metier.
     *
     * @throws IllegalArgumentException si le nom est vide, ou si le niveau est
     *                                  hors de l'intervalle [1,5]
     */
    public static Skill of(Long id, String nom, Integer niveau, String categorie) {
        String safeNom = DomainText.requireText(nom, "nom");
        if (niveau != null && (niveau < MIN_LEVEL || niveau > MAX_LEVEL)) {
            throw new IllegalArgumentException(
                    "Le champ 'niveau' doit etre compris entre " + MIN_LEVEL
                            + " et " + MAX_LEVEL + " (recu : " + niveau + ").");
        }
        return new Skill(id, safeNom, niveau, DomainText.normalize(categorie));
    }
}
