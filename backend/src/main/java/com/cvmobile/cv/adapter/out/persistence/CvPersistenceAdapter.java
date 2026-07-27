package com.cvmobile.cv.adapter.out.persistence;

import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.UserRepository;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Adaptateur de sortie implementant {@link CvRepositoryPort} au-dessus de Spring
 * Data JPA (issue #255, ADR 003).
 *
 * <p>Traduit les agregats de domaine vers l'entite de persistance
 * {@code model.Cv} et inversement via {@link CvPersistenceMapper}. A la mise a
 * jour, l'entite existante est rechargee <em>en verifiant l'appartenance</em>,
 * puis les champs modelises lui sont appliques : l'etat de partage public
 * (jetons, drapeaux) est ainsi preserve. A la creation, le proprietaire est
 * reference par un proxy paresseux ({@code getReferenceById}) sans requete
 * supplementaire.
 */
@Component
public class CvPersistenceAdapter implements CvRepositoryPort {

    private final CvRepository cvRepository;
    private final UserRepository userRepository;
    private final CvPersistenceMapper mapper;

    public CvPersistenceAdapter(CvRepository cvRepository,
                                UserRepository userRepository,
                                CvPersistenceMapper mapper) {
        this.cvRepository = cvRepository;
        this.userRepository = userRepository;
        this.mapper = mapper;
    }

    @Override
    public Cv save(Cv cv) {
        com.cvmobile.model.Cv entity = resolveTarget(cv);
        mapper.applyToEntity(cv, entity);
        com.cvmobile.model.Cv saved = cvRepository.save(entity);
        return mapper.toDomain(saved);
    }

    private com.cvmobile.model.Cv resolveTarget(Cv cv) {
        if (cv.getId() == null) {
            com.cvmobile.model.Cv entity = new com.cvmobile.model.Cv();
            entity.setUser(userRepository.getReferenceById(cv.getOwnerId()));
            if (cv.getParentId() != null) {
                entity.setParent(cvRepository.getReferenceById(cv.getParentId()));
            }
            return entity;
        }
        return cvRepository.findByIdAndUserId(cv.getId(), cv.getOwnerId())
                .orElseThrow(() -> new IllegalStateException(
                        "CV " + cv.getId() + " introuvable pour le proprietaire "
                                + cv.getOwnerId() + " lors de la sauvegarde."));
    }

    @Override
    public Optional<Cv> findByIdAndOwnerId(long cvId, long ownerId) {
        return cvRepository.findByIdAndUserId(cvId, ownerId).map(mapper::toDomain);
    }

    @Override
    public List<Cv> findAllByOwnerId(long ownerId) {
        return cvRepository.findByUserIdWithDetails(ownerId).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public List<Cv> findVariantsByParentIdAndOwnerId(long parentId, long ownerId) {
        return cvRepository.findByParentIdAndUserId(parentId, ownerId).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public boolean existsByIdAndOwnerId(long cvId, long ownerId) {
        return cvRepository.existsByIdAndUserId(cvId, ownerId);
    }

    @Override
    public boolean deleteByIdAndOwnerId(long cvId, long ownerId) {
        if (!cvRepository.existsByIdAndUserId(cvId, ownerId)) {
            return false;
        }
        cvRepository.deleteById(cvId);
        return true;
    }
}
