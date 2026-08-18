package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.dto.FidelityNote;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import com.cvmobile.model.PersonalInfo;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class FactualFidelityGuardTest {

    private final FactualFidelityGuard guard = new FactualFidelityGuard();

    @Test
    void refuseUnChiffreAbsentDuCvSource() {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder()
                        .resumeProfessionnel("Developpeur Java en equipe Agile.")
                        .build())
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();
        EnhanceCvResponse adapted = EnhanceCvResponse.builder()
                .resumeProfessionnel("Developpeur Java, 40% de gains de performance.")
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();

        EnhanceCvResponse safe = guard.sanitize(cv, adapted);

        assertThat(safe.getResumeProfessionnel()).isEqualTo("Developpeur Java en equipe Agile.");
        assertThat(safe.getFidelity())
                .anyMatch(note -> FidelityNote.REFUSED.equals(note.getStatus())
                        && note.getReason().contains("40%"));
        assertThat(guard.refusedReasons(safe)).isNotEmpty();
    }

    @Test
    void conserveUneReformulationSansNouveauChiffre() {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder()
                        .resumeProfessionnel("Developpeur Java, 5 applications livrees.")
                        .build())
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();
        EnhanceCvResponse adapted = EnhanceCvResponse.builder()
                .resumeProfessionnel("Ingenieur Java ayant livre 5 applications.")
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();

        EnhanceCvResponse safe = guard.sanitize(cv, adapted);

        assertThat(safe.getResumeProfessionnel()).isEqualTo("Ingenieur Java ayant livre 5 applications.");
        assertThat(safe.getFidelity())
                .anyMatch(note -> FidelityNote.REFORMULATED.equals(note.getStatus()));
    }

    @Test
    void refuseDeRemplirUnChampSourceVide() {
        Cv cv = Cv.builder()
                .experiences(List.of(Experience.builder().poste("Dev").description("").build()))
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();
        EnhanceCvResponse adapted = EnhanceCvResponse.builder()
                .experiences(List.of(EnhanceCvResponse.ExperienceEnhancement.builder()
                        .description("Pilote de 12 sprints Scrum.")
                        .build()))
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();

        EnhanceCvResponse safe = guard.sanitize(cv, adapted);

        assertThat(safe.getExperiences().get(0).getDescription()).isBlank();
        assertThat(safe.getFidelity())
                .anyMatch(note -> note.getField().equals("experience-1")
                        && FidelityNote.REFUSED.equals(note.getStatus()));
    }

    @Test
    void refuseUnChiffreQuiNEstQuUnJourDeDate() {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder()
                        .resumeProfessionnel("Developpeur Java.")
                        .build())
                .experiences(List.of(Experience.builder()
                        .poste("Dev")
                        .description("APIs REST")
                        .dateDebut(LocalDate.of(2023, 1, 15))
                        .build()))
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();
        EnhanceCvResponse adapted = EnhanceCvResponse.builder()
                .resumeProfessionnel("Developpeur Java, +15% de performance.")
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();

        EnhanceCvResponse safe = guard.sanitize(cv, adapted);

        assertThat(safe.getResumeProfessionnel()).isEqualTo("Developpeur Java.");
        assertThat(safe.getFidelity())
                .anyMatch(note -> FidelityNote.REFUSED.equals(note.getStatus())
                        && note.getReason().contains("15%"));
    }

    @Test
    void secondSanitizeConserveLesNotesRefusees() {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder()
                        .resumeProfessionnel("Developpeur Java en equipe.")
                        .build())
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();
        EnhanceCvResponse adapted = EnhanceCvResponse.builder()
                .resumeProfessionnel("Developpeur Java, +45% de performance.")
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of())
                .projects(List.of())
                .build();

        EnhanceCvResponse first = guard.sanitize(cv, adapted);
        EnhanceCvResponse second = guard.sanitize(cv, first);

        assertThat(second.getResumeProfessionnel()).isEqualTo("Developpeur Java en equipe.");
        assertThat(guard.refusedReasons(second)).anyMatch(reason -> reason.contains("45%"));
    }
}
