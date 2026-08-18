package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.dto.FidelityNote;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Skill;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class FidelitySkillFilterTest {

    private final FactualFidelityGuard guard = new FactualFidelityGuard();

    @Test
    void refuseLesCompetencesInventeesEtGardeLesConnues() {
        EnhanceCvResponse safe = guard.sanitize(cvWith("Java", "Spring Boot"), adapted(
                skill("Java", 5), skill("Kubernetes", 3)));

        assertThat(safe.getSkills())
                .extracting(EnhanceCvResponse.SkillEnhancement::getNom)
                .containsExactly("Java");
        assertThat(safe.getWarnings()).anyMatch(warning -> warning.contains("Kubernetes"));
    }

    @Test
    void refuseUneCompetenceConnueEnrichieDeTermesInventes() {
        EnhanceCvResponse safe = guard.sanitize(cvWith("Java"), adapted(skill("Java Kubernetes AWS", 5)));

        assertThat(safe.getSkills())
                .extracting(EnhanceCvResponse.SkillEnhancement::getNom)
                .containsExactly("Java");
        assertThat(safe.getFidelity())
                .anyMatch(note -> FidelityNote.REFUSED.equals(note.getStatus())
                        && note.getReason().contains("Kubernetes"));
    }

    @Test
    void refuseTouteCompetenceSiLeCvSourceEstVide() {
        EnhanceCvResponse safe = guard.sanitize(cvWith(), adapted(skill("Kubernetes", 3)));

        assertThat(safe.getSkills()).isEmpty();
        assertThat(safe.getFidelity())
                .anyMatch(note -> note.getReason().contains("CV source sans competence"));
    }

    @Test
    void restaureLesCompetencesSourcesSiLIaNEnProposeAucune() {
        EnhanceCvResponse safe = guard.sanitize(cvWith("Java"), EnhanceCvResponse.builder()
                .experiences(List.of()).educations(List.of()).skills(List.of()).projects(List.of()).build());

        assertThat(safe.getSkills())
                .extracting(EnhanceCvResponse.SkillEnhancement::getNom)
                .containsExactly("Java");
    }

    @Test
    void marqueLesCompetencesIdentiquesCommeInchangees() {
        EnhanceCvResponse safe = guard.sanitize(cvWith("Java"), adapted(skill("Java", 5)));

        assertThat(safe.getFidelity())
                .anyMatch(note -> "competences".equals(note.getField())
                        && FidelityNote.UNCHANGED.equals(note.getStatus()));
    }

    @Test
    void ignoreNomVideOuBlancDansLesCompetences() {
        Cv cv = Cv.builder()
                .experiences(List.of()).educations(List.of())
                .skills(List.of(Skill.builder().nom("").niveau(1).build(),
                        Skill.builder().nom("Python").niveau(3).build()))
                .projects(List.of()).build();
        EnhanceCvResponse safe = guard.sanitize(cv, adapted(skill("  ", 1), skill("Python", 3)));

        assertThat(safe.getSkills())
                .extracting(EnhanceCvResponse.SkillEnhancement::getNom)
                .containsExactly("Python");
    }

    private static Cv cvWith(String... names) {
        return Cv.builder()
                .experiences(List.of()).educations(List.of())
                .skills(java.util.Arrays.stream(names)
                        .map(name -> Skill.builder().nom(name).niveau(4).build())
                        .toList())
                .projects(List.of()).build();
    }

    private static EnhanceCvResponse.SkillEnhancement skill(String nom, int niveau) {
        return EnhanceCvResponse.SkillEnhancement.builder().nom(nom).niveau(niveau).build();
    }

    private static EnhanceCvResponse adapted(EnhanceCvResponse.SkillEnhancement... skills) {
        return EnhanceCvResponse.builder()
                .experiences(List.of()).educations(List.of())
                .skills(List.of(skills)).projects(List.of()).build();
    }
}
