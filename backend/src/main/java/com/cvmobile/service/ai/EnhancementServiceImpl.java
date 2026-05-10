package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.quality.ICvQualityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import static com.cvmobile.service.ai.AiPromptRules.*;

/**
 * Amelioration de CV par IA (LITE / MEDIUM / MAX).
 * LITE  : orthographe + accents uniquement.
 * MEDIUM: reformulation + anti-cliches.
 * MAX   : optimisation ATS complete (chiffres, competences, projets).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EnhancementServiceImpl implements IEnhancementService {

    private final IAiClient aiClient;
    private final CvRepository cvRepository;
    private final ICvQualityService qualityService;

    @Override
    public EnhanceCvResponse enhanceCv(Long cvId, String level) {
        Cv cv = cvRepository.findById(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouvé"));
        // Les exceptions AiServiceException propagent jusqu'au GlobalExceptionHandler
        // (plus de catch silencieux qui masque les erreurs config/quota/timeout).
        return callAiEnhance(cv, level);
    }

    @Override
    public EnhanceCvResponse adaptCvToJob(Long cvId, String jobDescription) {
        Cv cv = cvRepository.findById(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouvé"));
        String prompt = buildAdaptPrompt(cv, jobDescription);
        String rawContent = aiClient.complete(prompt, 3000);
        log.info("AI adapt response:\n{}", rawContent);
        return parseEnhanceResponse(rawContent, cv, "MAX");
    }

    // ── Appel IA et parsing ─────────────────────────────────────────

    private EnhanceCvResponse callAiEnhance(Cv cv, String level) {
        String prompt = buildEnhancePrompt(cv, level);
        String rawContent = aiClient.complete(prompt, 3000);
        log.info("AI enhance response:\n{}", rawContent);
        return parseEnhanceResponse(rawContent, cv, level);
    }

    private EnhanceCvResponse parseEnhanceResponse(String rawContent, Cv cv, String level) {
        List<String> allMarkers = buildMarkerList(cv);

        // Parse titre poste
        String titrePoste = AiResponseParser.extractBetweenMarkers(rawContent, "TITRE_POSTE:", allMarkers);
        if (titrePoste.isBlank() && cv.getPersonalInfo() != null) {
            titrePoste = cv.getPersonalInfo().getTitrePoste();
        }

        // Parse resume
        String resume = AiResponseParser.extractBetweenMarkers(rawContent, "RESUME:", allMarkers);
        if (resume.isBlank() && cv.getPersonalInfo() != null) {
            resume = cv.getPersonalInfo().getResumeProfessionnel();
        }

        // Parse experiences
        List<EnhanceCvResponse.ExperienceEnhancement> expEnhancements = new ArrayList<>();
        for (Experience exp : cv.getExperiences()) {
            String marker = "EXP_" + exp.getId() + ":";
            String enhanced = AiResponseParser.extractBetweenMarkers(rawContent, marker, allMarkers);
            if (enhanced.isBlank()) enhanced = exp.getDescription() != null ? exp.getDescription() : "";
            expEnhancements.add(EnhanceCvResponse.ExperienceEnhancement.builder()
                    .id(exp.getId())
                    .poste(exp.getPoste())
                    .description(enhanced)
                    .build());
        }

        // Parse educations
        List<EnhanceCvResponse.EducationEnhancement> eduEnhancements = new ArrayList<>();
        for (Education edu : cv.getEducations()) {
            String marker = "EDU_" + edu.getId() + ":";
            String enhanced = AiResponseParser.extractBetweenMarkers(rawContent, marker, allMarkers);
            if (enhanced.isBlank()) enhanced = edu.getDescription() != null ? edu.getDescription() : "";
            eduEnhancements.add(EnhanceCvResponse.EducationEnhancement.builder()
                    .id(edu.getId())
                    .description(enhanced)
                    .build());
        }

        // Parse competences
        String competencesRaw = AiResponseParser.extractBetweenMarkers(rawContent, "COMPETENCES:", allMarkers);
        List<EnhanceCvResponse.SkillEnhancement> skillEnhancements = new ArrayList<>();
        if (!competencesRaw.isBlank()) {
            String[] parts = competencesRaw.split("[,\\n]");
            for (String part : parts) {
                String skillName = part.replaceAll("^[\\-\\*•]+\\s*", "").strip();
                if (!skillName.isBlank()) {
                    skillEnhancements.add(EnhanceCvResponse.SkillEnhancement.builder()
                            .nom(skillName)
                            .niveau(3)
                            .build());
                }
            }
        }

        // Parse projets
        List<EnhanceCvResponse.ProjectEnhancement> projEnhancements = new ArrayList<>();
        for (Project proj : cv.getProjects()) {
            String marker = "PROJ_" + proj.getId() + ":";
            String enhanced = AiResponseParser.extractBetweenMarkers(rawContent, marker, allMarkers);
            if (enhanced.isBlank()) enhanced = proj.getDescription() != null ? proj.getDescription() : "";
            projEnhancements.add(EnhanceCvResponse.ProjectEnhancement.builder()
                    .id(proj.getId())
                    .description(enhanced)
                    .build());
        }

        // Nettoyage qualite
        String cleanedTitre = qualityService.clean(titrePoste);
        String cleanedResume = qualityService.clean(resume);

        List<Experience> originalExps = cv.getExperiences();
        for (int i = 0; i < expEnhancements.size() && i < originalExps.size(); i++) {
            var enh = expEnhancements.get(i);
            var orig = originalExps.get(i);
            String cleaned = qualityService.clean(enh.getDescription());
            cleaned = qualityService.removeRepeatedTitle(cleaned, orig.getPoste(), orig.getEntreprise());
            enh.setDescription(cleaned);
        }
        eduEnhancements.forEach(e -> e.setDescription(qualityService.clean(e.getDescription())));

        return EnhanceCvResponse.builder()
                .titrePoste(cleanedTitre)
                .resumeProfessionnel(cleanedResume)
                .experiences(expEnhancements)
                .educations(eduEnhancements)
                .skills(skillEnhancements.stream().limit(10).collect(Collectors.toList()))
                .projects(projEnhancements)
                .aiGenerated(true)
                .level(level)
                .build();
    }

    // ── Construction des prompts ────────────────────────────────────

    private String buildEnhancePrompt(Cv cv, String level) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en redaction de CV professionnels, specialise en optimisation ATS ");
        sb.append("(Applicant Tracking System). Tu connais les attentes des recruteurs en 2026. ");

        sb.append(GRAMMAR_RULE);
        sb.append(TITLE_RULE);

        switch (level.toUpperCase()) {
            case "LITE" -> sb.append(
                    "Corrige uniquement l'orthographe, la grammaire et les accents. "
                    + "Garde exactement le même sens et les mêmes mots. "
                    + "Ne reformule PAS, ne change PAS la structure. "
                    + "Ajoute les accents manquants (Developpeur → Développeur). ");
            case "MEDIUM" -> {
                sb.append(
                    "Corrige l'orthographe et les accents. "
                    + "Reformule pour plus d'impact professionnel. ");
                sb.append(ANTI_CLICHES_RULE);
                sb.append(STYLE_RULE);
            }
            default -> { // MAX
                sb.append(
                    "Optimise complètement ce CV pour un maximum d'impact ATS et recruteur. ");
                sb.append(ANTI_CLICHES_RULE);
                sb.append(STYLE_RULE);
                sb.append(QUANTIFICATION_RULE);
                sb.append(SKILL_CATEGORY_RULE);
                sb.append(PROJECT_RULE);
                sb.append("Pour le résumé, écris 3-4 phrases percutantes. ");
            }
        }

        appendResponseFormat(sb, cv);
        appendCurrentCvData(sb, cv);

        return sb.toString();
    }

    private String buildAdaptPrompt(Cv cv, String jobDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en redaction de CV professionnels. ");
        sb.append("Adapte ce CV pour correspondre au maximum a cette offre d'emploi. ");
        sb.append("OFFRE D'EMPLOI:\n").append(jobDescription).append("\n\n");

        sb.append(GRAMMAR_RULE);
        sb.append(TITLE_RULE);
        sb.append(ANTI_CLICHES_RULE);
        sb.append(STYLE_RULE);
        sb.append(QUANTIFICATION_RULE);
        sb.append(SKILL_CATEGORY_RULE);

        appendResponseFormat(sb, cv);
        appendCurrentCvData(sb, cv);

        return sb.toString();
    }

    private void appendResponseFormat(StringBuilder sb, Cv cv) {
        sb.append("\nReponds en francais uniquement. ");
        sb.append("IMPORTANT: Utilise EXACTEMENT ce format avec les marqueurs :\n\n");
        sb.append("TITRE_POSTE:\n(titre de poste ameliore)\n\n");
        sb.append("RESUME:\n(resume professionnel ameliore)\n\n");

        for (Experience exp : cv.getExperiences()) {
            sb.append("EXP_").append(exp.getId()).append(":\n");
            sb.append("(description amelioree avec tirets - pour chaque point)\n\n");
        }
        for (Education edu : cv.getEducations()) {
            sb.append("EDU_").append(edu.getId()).append(":\n");
            sb.append("(description amelioree de la formation)\n\n");
        }
        sb.append("COMPETENCES:\n(liste de competences separees par des virgules, une par une)\n\n");
        for (Project proj : cv.getProjects()) {
            sb.append("PROJ_").append(proj.getId()).append(":\n");
            sb.append("(description amelioree du projet)\n\n");
        }
    }

    private void appendCurrentCvData(StringBuilder sb, Cv cv) {
        sb.append("---\nDONNEES ACTUELLES DU CV :\n\n");

        if (cv.getPersonalInfo() != null) {
            sb.append("Titre de poste : ").append(
                    cv.getPersonalInfo().getTitrePoste() != null ? cv.getPersonalInfo().getTitrePoste() : "(vide)").append("\n");
            sb.append("Resume : ").append(
                    cv.getPersonalInfo().getResumeProfessionnel() != null ? cv.getPersonalInfo().getResumeProfessionnel() : "(vide)").append("\n\n");
        }

        for (Experience exp : cv.getExperiences()) {
            sb.append("EXP_").append(exp.getId()).append(" : ").append(exp.getPoste());
            sb.append(" chez ").append(exp.getEntreprise());
            sb.append(" | Description : ").append(exp.getDescription() != null ? exp.getDescription() : "(vide)").append("\n");
        }
        sb.append("\n");

        for (Education edu : cv.getEducations()) {
            sb.append("EDU_").append(edu.getId()).append(" : ").append(edu.getDiplome());
            sb.append(" a ").append(edu.getEtablissement());
            sb.append(" | Description : ").append(edu.getDescription() != null ? edu.getDescription() : "(vide)").append("\n");
        }
        sb.append("\n");

        sb.append("Competences actuelles : ");
        sb.append(cv.getSkills().stream().map(Skill::getNom).collect(Collectors.joining(", ")));
        sb.append("\n\n");

        for (Project proj : cv.getProjects()) {
            sb.append("PROJ_").append(proj.getId()).append(" : ").append(proj.getNom());
            sb.append(" | Technologies : ").append(proj.getTechnologies() != null ? proj.getTechnologies() : "");
            sb.append(" | Description : ").append(proj.getDescription() != null ? proj.getDescription() : "(vide)").append("\n");
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private List<String> buildMarkerList(Cv cv) {
        List<String> markers = new ArrayList<>();
        markers.add("TITRE_POSTE:");
        markers.add("RESUME:");
        for (Experience exp : cv.getExperiences()) markers.add("EXP_" + exp.getId() + ":");
        for (Education edu : cv.getEducations()) markers.add("EDU_" + edu.getId() + ":");
        markers.add("COMPETENCES:");
        for (Project proj : cv.getProjects()) markers.add("PROJ_" + proj.getId() + ":");
        return markers;
    }

    private EnhanceCvResponse buildFallbackEnhancement(Cv cv, String level) {
        String resume = cv.getPersonalInfo() != null
                ? cv.getPersonalInfo().getResumeProfessionnel() : null;
        String titrePoste = cv.getPersonalInfo() != null
                ? cv.getPersonalInfo().getTitrePoste() : null;

        List<EnhanceCvResponse.ExperienceEnhancement> exps = cv.getExperiences().stream()
                .map(e -> EnhanceCvResponse.ExperienceEnhancement.builder()
                        .id(e.getId()).poste(e.getPoste()).description(e.getDescription()).build())
                .collect(Collectors.toList());

        List<EnhanceCvResponse.EducationEnhancement> edus = cv.getEducations().stream()
                .map(e -> EnhanceCvResponse.EducationEnhancement.builder()
                        .id(e.getId()).description(e.getDescription()).build())
                .collect(Collectors.toList());

        List<EnhanceCvResponse.SkillEnhancement> skills = cv.getSkills().stream()
                .map(s -> EnhanceCvResponse.SkillEnhancement.builder()
                        .nom(s.getNom()).niveau(s.getNiveau()).build())
                .collect(Collectors.toList());

        List<EnhanceCvResponse.ProjectEnhancement> projs = cv.getProjects().stream()
                .map(p -> EnhanceCvResponse.ProjectEnhancement.builder()
                        .id(p.getId()).description(p.getDescription()).build())
                .collect(Collectors.toList());

        return EnhanceCvResponse.builder()
                .titrePoste(titrePoste)
                .resumeProfessionnel(resume)
                .experiences(exps)
                .educations(edus)
                .skills(skills)
                .projects(projs)
                .aiGenerated(false)
                .level(level)
                .build();
    }
}
