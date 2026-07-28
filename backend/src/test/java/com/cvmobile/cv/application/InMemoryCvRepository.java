package com.cvmobile.cv.application;

import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Double en memoire de {@link CvRepositoryPort} pour les tests de use cases
 * (substituabilite LSP : remplace l'adaptateur JPA sans base ni Spring).
 *
 * <p>Reproduit fidelement le contrat : {@code save} d'un CV neuf lui attribue un
 * identifiant genere; toutes les lectures et suppressions sont restreintes au
 * proprietaire. Un CV n'est jamais visible d'un autre proprietaire.
 */
public final class InMemoryCvRepository implements CvRepositoryPort {

    private final Map<Long, Cv> store = new ConcurrentHashMap<>();
    private final AtomicLong sequence = new AtomicLong();

    @Override
    public Cv save(Cv cv) {
        if (cv.getId() == null) {
            cv.assignId(sequence.incrementAndGet());
        }
        store.put(cv.getId(), cv);
        return cv;
    }

    @Override
    public Optional<Cv> findByIdAndOwnerId(long cvId, long ownerId) {
        return Optional.ofNullable(store.get(cvId))
                .filter(cv -> cv.getOwnerId() == ownerId);
    }

    @Override
    public List<Cv> findAllByOwnerId(long ownerId) {
        List<Cv> result = new ArrayList<>();
        for (Cv cv : store.values()) {
            if (cv.getOwnerId() == ownerId) {
                result.add(cv);
            }
        }
        return result;
    }

    @Override
    public List<Cv> findVariantsByParentIdAndOwnerId(long parentId, long ownerId) {
        List<Cv> result = new ArrayList<>();
        for (Cv cv : store.values()) {
            if (cv.getOwnerId() == ownerId
                    && cv.getParentId() != null
                    && cv.getParentId() == parentId) {
                result.add(cv);
            }
        }
        return result;
    }

    @Override
    public boolean existsByIdAndOwnerId(long cvId, long ownerId) {
        return findByIdAndOwnerId(cvId, ownerId).isPresent();
    }

    @Override
    public boolean deleteByIdAndOwnerId(long cvId, long ownerId) {
        if (!existsByIdAndOwnerId(cvId, ownerId)) {
            return false;
        }
        store.remove(cvId);
        return true;
    }

    /** Nombre de CV actuellement stockes (commodite de test). */
    public int count() {
        return store.size();
    }
}
