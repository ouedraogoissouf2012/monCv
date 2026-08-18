package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.dto.FidelityNote;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Project;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Garde "zero invention" pour l'adaptation d'un CV a une offre.
 *
 * L'IA peut reformuler et reordonner. Elle ne peut pas inventer un chiffre,
 * une competence, un diplome, une mission (champ vide rempli) ou un fait
 * quantifie absent du CV source. Les champs refuses sont retablis a l'original.
 */
@Component
public class FactualFidelityGuard {

    public EnhanceCvResponse sanitize(Cv original, EnhanceCvResponse adapted) {
        if (adapted == null) {
            return EnhanceCvResponse.builder().fidelity(List.of()).build();
        }
        List<FidelityNote> priorRefused = priorRefused(adapted);
        List<FidelityNote> notes = new ArrayList<>();
        Set<String> allowedNumbers = FidelitySourceFacts.allowedNumbers(original);

        String originalResume = original.getPersonalInfo() == null
                ? null : original.getPersonalInfo().getResumeProfessionnel();
        adapted.setResumeProfessionnel(sanitizeText(
                "resume", originalResume, adapted.getResumeProfessionnel(),
                allowedNumbers, notes));

        sanitizeExperiences(original, adapted, allowedNumbers, notes);
        sanitizeEducations(original, adapted, allowedNumbers, notes);
        sanitizeProjects(original, adapted, allowedNumbers, notes);
        FidelitySkillFilter.apply(original, adapted, notes);

        adapted.setFidelity(List.copyOf(mergePriorRefused(notes, priorRefused)));
        adapted.setWarnings(mergeWarnings(adapted.getWarnings(), adapted.getFidelity()));
        return adapted;
    }

    public List<String> refusedReasons(EnhanceCvResponse adapted) {
        if (adapted == null || adapted.getFidelity() == null) {
            return List.of();
        }
        return adapted.getFidelity().stream()
                .filter(note -> FidelityNote.REFUSED.equals(note.getStatus()))
                .map(FidelityNote::getReason)
                .toList();
    }

    private void sanitizeExperiences(
            Cv original, EnhanceCvResponse adapted,
            Set<String> allowedNumbers, List<FidelityNote> notes) {
        List<Experience> source = original.getExperiences();
        List<EnhanceCvResponse.ExperienceEnhancement> target = adapted.getExperiences();
        if (target == null) {
            return;
        }
        for (int i = 0; i < target.size() && i < source.size(); i++) {
            Experience orig = source.get(i);
            target.get(i).setDescription(sanitizeText(
                    "experience-" + (i + 1),
                    orig.getDescription(),
                    target.get(i).getDescription(),
                    allowedNumbers,
                    notes));
        }
    }

    private void sanitizeEducations(
            Cv original, EnhanceCvResponse adapted,
            Set<String> allowedNumbers, List<FidelityNote> notes) {
        List<Education> source = original.getEducations();
        List<EnhanceCvResponse.EducationEnhancement> target = adapted.getEducations();
        if (target == null) {
            return;
        }
        for (int i = 0; i < target.size() && i < source.size(); i++) {
            Education orig = source.get(i);
            target.get(i).setDescription(sanitizeText(
                    "formation-" + (i + 1),
                    orig.getDescription(),
                    target.get(i).getDescription(),
                    allowedNumbers,
                    notes));
        }
    }

    private void sanitizeProjects(
            Cv original, EnhanceCvResponse adapted,
            Set<String> allowedNumbers, List<FidelityNote> notes) {
        List<Project> source = original.getProjects();
        List<EnhanceCvResponse.ProjectEnhancement> target = adapted.getProjects();
        if (target == null) {
            return;
        }
        for (int i = 0; i < target.size() && i < source.size(); i++) {
            Project orig = source.get(i);
            target.get(i).setDescription(sanitizeText(
                    "projet-" + (i + 1),
                    orig.getDescription(),
                    target.get(i).getDescription(),
                    allowedNumbers,
                    notes));
        }
    }

    private String sanitizeText(
            String field,
            String original,
            String adapted,
            Set<String> allowedNumbers,
            List<FidelityNote> notes) {
        String before = original == null ? "" : original.strip();
        String after = adapted == null ? "" : adapted.strip();
        if (after.isEmpty() || after.equals(before)) {
            if (!before.isEmpty()) {
                notes.add(note(field, FidelityNote.UNCHANGED, "Aucun changement sur " + field + "."));
            }
            return before.isEmpty() ? adapted : original;
        }
        if (before.isEmpty()) {
            notes.add(note(field, FidelityNote.REFUSED,
                    "Invention refusee sur " + field + " (champ source vide)."));
            return original;
        }
        Set<String> invented = new LinkedHashSet<>(FidelitySourceFacts.extractNumbers(after));
        invented.removeAll(allowedNumbers);
        if (!invented.isEmpty()) {
            notes.add(note(field, FidelityNote.REFUSED,
                    "Chiffres inventes refuses sur " + field + " : "
                            + String.join(", ", invented) + "."));
            return original;
        }
        notes.add(note(field, FidelityNote.REFORMULATED,
                "Reformulation conservee sur " + field + "."));
        return adapted;
    }

    private List<FidelityNote> priorRefused(EnhanceCvResponse adapted) {
        if (adapted.getFidelity() == null) {
            return List.of();
        }
        return adapted.getFidelity().stream()
                .filter(note -> FidelityNote.REFUSED.equals(note.getStatus()))
                .toList();
    }

    private List<FidelityNote> mergePriorRefused(
            List<FidelityNote> notes, List<FidelityNote> priorRefused) {
        LinkedHashSet<String> refusedFields = new LinkedHashSet<>();
        notes.stream()
                .filter(note -> FidelityNote.REFUSED.equals(note.getStatus()))
                .map(FidelityNote::getField)
                .forEach(refusedFields::add);
        for (FidelityNote prior : priorRefused) {
            if (refusedFields.add(prior.getField())) {
                notes.removeIf(note -> prior.getField().equals(note.getField())
                        && FidelityNote.UNCHANGED.equals(note.getStatus()));
                notes.add(prior);
            }
        }
        return notes;
    }

    private List<String> mergeWarnings(List<String> existing, List<FidelityNote> notes) {
        LinkedHashSet<String> merged = new LinkedHashSet<>();
        if (existing != null) {
            merged.addAll(existing);
        }
        notes.stream()
                .filter(note -> FidelityNote.REFUSED.equals(note.getStatus()))
                .map(FidelityNote::getReason)
                .forEach(merged::add);
        return List.copyOf(merged);
    }

    private FidelityNote note(String field, String status, String reason) {
        return FidelityNote.builder().field(field).status(status).reason(reason).build();
    }
}
