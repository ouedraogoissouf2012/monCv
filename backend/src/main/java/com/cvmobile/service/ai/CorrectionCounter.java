package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Project;
import org.springframework.stereotype.Component;

import java.util.Objects;

/**
 * Compte le nombre de champs modifies entre un CV d'origine et la reponse IA
 * amelioree (issue #256). Extrait de {@code EnhancementServiceImpl}.
 *
 * Deux valeurs sont considerees identiques apres normalisation du {@code null}
 * en chaine vide.
 */
@Component
public class CorrectionCounter {

    public int countCorrections(Cv cv, EnhanceCvResponse response) {
        int count = 0;
        if (cv.getPersonalInfo() != null) {
            count += changed(cv.getPersonalInfo().getTitrePoste(), response.getTitrePoste());
            count += changed(cv.getPersonalInfo().getResumeProfessionnel(), response.getResumeProfessionnel());
        }

        for (int i = 0; i < Math.min(cv.getExperiences().size(), response.getExperiences().size()); i++) {
            Experience original = cv.getExperiences().get(i);
            var corrected = response.getExperiences().get(i);
            count += changed(original.getPoste(), corrected.getPoste());
            count += changed(original.getDescription(), corrected.getDescription());
        }
        for (int i = 0; i < Math.min(cv.getEducations().size(), response.getEducations().size()); i++) {
            Education original = cv.getEducations().get(i);
            var corrected = response.getEducations().get(i);
            count += changed(original.getEtablissement(), corrected.getEtablissement());
            count += changed(original.getDiplome(), corrected.getDiplome());
            count += changed(original.getDomaine(), corrected.getDomaine());
            count += changed(original.getDescription(), corrected.getDescription());
        }
        for (int i = 0; i < Math.min(cv.getSkills().size(), response.getSkills().size()); i++) {
            count += changed(cv.getSkills().get(i).getNom(), response.getSkills().get(i).getNom());
        }
        for (int i = 0; i < Math.min(cv.getLanguages().size(), response.getLanguages().size()); i++) {
            count += changed(cv.getLanguages().get(i).getLangue(), response.getLanguages().get(i).getLangue());
        }
        for (int i = 0; i < Math.min(cv.getCertifications().size(), response.getCertifications().size()); i++) {
            Certification original = cv.getCertifications().get(i);
            var corrected = response.getCertifications().get(i);
            count += changed(original.getNom(), corrected.getNom());
            count += changed(original.getOrganisme(), corrected.getOrganisme());
        }
        for (int i = 0; i < Math.min(cv.getProjects().size(), response.getProjects().size()); i++) {
            Project original = cv.getProjects().get(i);
            var corrected = response.getProjects().get(i);
            count += changed(original.getNom(), corrected.getNom());
            count += changed(original.getDescription(), corrected.getDescription());
            count += changed(original.getTechnologies(), corrected.getTechnologies());
        }
        return count;
    }

    private int changed(String original, String corrected) {
        return Objects.equals(normalizeEmpty(original), normalizeEmpty(corrected)) ? 0 : 1;
    }

    private String normalizeEmpty(String value) {
        return value == null ? "" : value;
    }
}
