package com.cvmobile.cv.adapter.in.web;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.repository.CvRepository;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Assemble la reponse web {@link CvResponse} a partir de l'entite de persistance
 * (issue #255, ADR 003).
 *
 * <p>Le domaine CV migre ne modelise volontairement pas certains attributs
 * exposes par l'API (jetons de partage public et drapeaux associes, horodatages,
 * nombre de variantes). Pour preserver le contrat sans regression, la reponse
 * est donc construite depuis l'entite JPA rechargee via le mapper existant, et
 * non depuis l'agregat de domaine.
 *
 * <p>Dette tracee (#255) : cette relecture disparaitra lorsque la sortie web
 * sera entierement pilotee par le module CV (255-E et suivants).
 */
@Component
public class CvResponseAssembler {

    private final CvRepository cvRepository;
    private final CvMapper cvMapper;

    public CvResponseAssembler(CvRepository cvRepository, CvMapper cvMapper) {
        this.cvRepository = cvRepository;
        this.cvMapper = cvMapper;
    }

    /**
     * Construit la reponse complete d'un CV possede, a partir de son entite.
     *
     * @throws CvNotFoundException si aucun CV possede ne correspond (par ex.
     *                             suppression concurrente) : l'API repond alors
     *                             404, jamais 500.
     */
    @Transactional(readOnly = true)
    public CvResponse assemble(long cvId, long ownerId) {
        return cvRepository.findByIdAndUserId(cvId, ownerId)
                .map(cvMapper::toResponse)
                .orElseThrow(() -> new CvNotFoundException(cvId));
    }

    /**
     * Construit la liste des reponses d'un proprietaire, enrichie du nombre de
     * variantes de chaque CV parent (comme l'exposait le service historique).
     */
    @Transactional(readOnly = true)
    public List<CvResponse> assembleAll(long ownerId) {
        var entities = cvRepository.findByUserIdWithDetails(ownerId);
        List<CvResponse> responses = entities.stream()
                .map(cvMapper::toResponse)
                .collect(Collectors.toList());

        List<Long> parentIds = entities.stream()
                .filter(cv -> cv.getVarianteLabel() == null)
                .map(cv -> cv.getId())
                .collect(Collectors.toList());

        if (!parentIds.isEmpty()) {
            Map<Long, Long> counts = cvRepository.countVariantsByParentIds(parentIds).stream()
                    .collect(Collectors.toMap(row -> (Long) row[0], row -> (Long) row[1]));
            responses.forEach(r -> {
                Long count = counts.get(r.getId());
                if (count != null) {
                    r.setVariantCount(count.intValue());
                }
            });
        }
        return responses;
    }
}
