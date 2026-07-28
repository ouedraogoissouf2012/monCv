package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Met a jour un CV existant a partir des valeurs fournies (issue #255).
 *
 * <p>Le CV cible est charge <em>en verifiant l'appartenance</em>, puis ses
 * champs modifiables (titre, style, informations personnelles, sections) sont
 * remplaces. Son identite, son proprietaire, son lien de variante et ses
 * compteurs (calcules cote serveur) sont preserves : ils ne proviennent jamais
 * des donnees fournies.
 *
 * <p>Les sections portees par {@code changes} incluent leur identifiant pour
 * celles conservees et aucun identifiant pour les nouvelles; la couche de
 * persistance en deduit les mises a jour, insertions et suppressions.
 */
@Service
public class UpdateCvUseCase {

    private final CvRepositoryPort repository;

    public UpdateCvUseCase(CvRepositoryPort repository) {
        this.repository = repository;
    }

    /**
     * @throws CvNotFoundException si aucun CV possede ne correspond
     */
    @Transactional
    public Cv update(long cvId, long ownerId, Cv changes) {
        Cv current = repository.findByIdAndOwnerId(cvId, ownerId)
                .orElseThrow(() -> new CvNotFoundException(cvId));

        current.rename(changes.getTitre());
        current.changeStyle(changes.getStyle());
        current.changePersonalInfo(changes.getPersonalInfo());

        current.replaceExperiences(changes.getExperiences());
        current.replaceEducations(changes.getEducations());
        current.replaceSkills(changes.getSkills());
        current.replaceLanguages(changes.getLanguages());
        current.replaceCertifications(changes.getCertifications());
        current.replaceProjects(changes.getProjects());

        return repository.save(current);
    }
}
