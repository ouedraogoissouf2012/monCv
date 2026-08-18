package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.dto.FidelityNote;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Skill;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

final class FidelitySkillFilter {

    private FidelitySkillFilter() {
    }

    static void apply(Cv original, EnhanceCvResponse adapted, List<FidelityNote> notes) {
        List<Skill> source = original.getSkills() == null ? List.of() : original.getSkills();
        List<EnhanceCvResponse.SkillEnhancement> proposed =
                adapted.getSkills() == null ? List.of() : adapted.getSkills();
        if (source.isEmpty()) {
            if (!proposed.isEmpty()) {
                notes.add(note("Competences inventees refusees (CV source sans competence)."));
                adapted.setSkills(List.of());
            }
            return;
        }
        List<EnhanceCvResponse.SkillEnhancement> kept = new ArrayList<>();
        List<String> refused = new ArrayList<>();
        for (EnhanceCvResponse.SkillEnhancement skill : proposed) {
            if (isKnownSkill(skill.getNom(), source)) {
                kept.add(skill);
            } else if (skill.getNom() != null && !skill.getNom().isBlank()) {
                refused.add(skill.getNom().strip());
            }
        }
        if (!refused.isEmpty()) {
            notes.add(note("Competences inventees refusees : " + String.join(", ", refused) + "."));
        } else if (!proposed.isEmpty()) {
            boolean same = proposed.size() == source.size()
                    && proposed.stream().allMatch(skill ->
                    source.stream().anyMatch(orig ->
                            normalize(orig.getNom()).equals(normalize(skill.getNom()))));
            notes.add(FidelityNote.builder()
                    .field("competences")
                    .status(same ? FidelityNote.UNCHANGED : FidelityNote.REFORMULATED)
                    .reason(same ? "Competences inchangees." : "Competences reformulees sans ajout.")
                    .build());
        }
        if (kept.isEmpty()) {
            adapted.setSkills(source.stream()
                    .map(orig -> EnhanceCvResponse.SkillEnhancement.builder()
                            .nom(orig.getNom())
                            .niveau(orig.getNiveau())
                            .build())
                    .toList());
        } else {
            adapted.setSkills(kept);
        }
    }

    private static boolean isKnownSkill(String candidate, List<Skill> original) {
        if (candidate == null || candidate.isBlank()) {
            return false;
        }
        for (Skill skill : original) {
            if (skill.getNom() == null || skill.getNom().isBlank()) {
                continue;
            }
            if (normalize(skill.getNom()).equals(normalize(candidate))) {
                return true;
            }
            if (SkillTermPreserver.isReformulationOf(skill.getNom(), candidate)) {
                return true;
            }
        }
        return false;
    }

    private static FidelityNote note(String reason) {
        return FidelityNote.builder()
                .field("competences")
                .status(FidelityNote.REFUSED)
                .reason(reason)
                .build();
    }

    private static String normalize(String value) {
        return value == null ? "" : value.strip().toLowerCase(Locale.ROOT);
    }
}
