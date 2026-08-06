package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.model.Cv;
import com.cvmobile.model.PersonalInfo;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CorrectionCounterTest {

    private final CorrectionCounter counter = new CorrectionCounter();

    private Cv cvWith(String titre, String resume) {
        return Cv.builder()
                .personalInfo(PersonalInfo.builder().titrePoste(titre).resumeProfessionnel(resume).build())
                .experiences(List.of()).educations(List.of()).skills(List.of())
                .languages(List.of()).certifications(List.of()).projects(List.of())
                .build();
    }

    private EnhanceCvResponse responseWith(String titre, String resume) {
        return EnhanceCvResponse.builder()
                .titrePoste(titre).resumeProfessionnel(resume)
                .experiences(List.of()).educations(List.of()).skills(List.of())
                .languages(List.of()).certifications(List.of()).projects(List.of())
                .build();
    }

    @Test
    void aucunChangement_retourneZero() {
        Cv cv = cvWith("Developpeur", "Un resume");

        int count = counter.countCorrections(cv, responseWith("Developpeur", "Un resume"));

        assertThat(count).isZero();
    }

    @Test
    void titreEtResumeModifies_comptesSeparement() {
        Cv cv = cvWith("Developpeur", "Un resume");

        int count = counter.countCorrections(cv, responseWith("Développeur", "Un résumé"));

        assertThat(count).isEqualTo(2);
    }

    @Test
    void nullEtChaineVide_consideresIdentiques() {
        Cv cv = cvWith(null, "R");

        int count = counter.countCorrections(cv, responseWith("", "R"));

        assertThat(count).isZero();
    }
}
