package com.cvmobile.cv.application.port.out;

import com.cvmobile.cv.domain.model.Cv;
import java.util.List;
import java.util.Optional;

/**
 * Port de sortie pour la persistance des CV (issue #255, ADR 003).
 *
 * <p>Defini dans la couche application et exprime uniquement en <em>types de
 * domaine</em> ({@link Cv}) : la logique metier depend de cette abstraction, pas
 * de Spring Data. Un adaptateur de sortie l'implemente (JPA aujourd'hui), et un
 * double en memoire peut le substituer dans les tests (LSP).
 *
 * <p>Toutes les operations de lecture par proprietaire prennent l'identifiant
 * du proprietaire : l'appartenance est verifiee en base, jamais supposee a
 * partir d'une valeur fournie par le client.
 */
public interface CvRepositoryPort {

    /**
     * Persiste un CV (creation ou mise a jour) et retourne l'agregat
     * reconstitue tel qu'enregistre (identifiants generes compris).
     */
    Cv save(Cv cv);

    /**
     * Recupere un CV par identifiant en restreignant au proprietaire donne.
     *
     * @return le CV s'il existe et appartient au proprietaire, sinon vide
     */
    Optional<Cv> findByIdAndOwnerId(long cvId, long ownerId);

    /**
     * Liste les CV d'un proprietaire, du plus recemment modifie au plus ancien.
     */
    List<Cv> findAllByOwnerId(long ownerId);

    /**
     * Liste les variantes d'un CV parent appartenant au proprietaire donne.
     */
    List<Cv> findVariantsByParentIdAndOwnerId(long parentId, long ownerId);

    /**
     * Indique si un CV existe pour cet identifiant et ce proprietaire.
     */
    boolean existsByIdAndOwnerId(long cvId, long ownerId);

    /**
     * Supprime un CV appartenant au proprietaire donne.
     *
     * @return {@code true} si un CV a ete supprime, {@code false} s'il
     *         n'existait pas pour ce proprietaire
     */
    boolean deleteByIdAndOwnerId(long cvId, long ownerId);

    List<Cv> findDeletedByOwnerId(long ownerId);

    boolean restoreByIdAndOwnerId(long cvId, long ownerId);

    boolean purgeByIdAndOwnerId(long cvId, long ownerId);
}
