package com.cvmobile.service.ai;

import com.cvmobile.config.AiEnhancementProperties;
import com.cvmobile.config.CvQualityProperties;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.quality.ICvQualityService;
import com.cvmobile.service.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
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
    private final NotificationService notificationService;
    private final AiEnhancementProperties enhancementProperties;
    private final CvQualityProperties qualityProperties;
    @Override
    public EnhanceCvResponse enhanceCv(Long cvId, String level) {
        Cv cv = cvRepository.findById(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouvé"));
        // Les exceptions AiServiceException propagent jusqu'au GlobalExceptionHandler
        // (plus de catch silencieux qui masque les erreurs config/quota/timeout).
        EnhanceCvResponse response = callAiEnhance(cv, level);
        notificationService.notifyAiTips(cv, response.getCorrectionCount());
        return response;
    }
    @Override
    public EnhanceCvResponse adaptCvToJob(Long cvId, String jobDescription) {
        Cv cv = cvRepository.findById(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouvé"));
        String prompt = buildAdaptPrompt(cv, jobDescription);
        String rawContent = aiClient.complete(prompt, enhancementProperties.completionTokens());
        boolean fallback = aiClient.isFallbackResult();
        log.info("AI adapt response summary: {}", AiLogSanitizer.summarize(rawContent));
        return parseEnhanceResponse(rawContent, cv, "MAX", fallback);
    }
    // ── Appel IA et parsing ─────────────────────────────────────────

    private EnhanceCvResponse callAiEnhance(Cv cv, String level) {
        String prompt = buildEnhancePrompt(cv, level);
        String rawContent = aiClient.complete(prompt, enhancementProperties.completionTokens());
        boolean fallback = aiClient.isFallbackResult();
        log.info("AI enhance response summary: {}", AiLogSanitizer.summarize(rawContent));
        return parseEnhanceResponse(rawContent, cv, level, fallback);
    }

    private EnhanceCvResponse parseEnhanceResponse(String rawContent, Cv cv, String level,
                                                    boolean fallback) {
        List<String> allMarkers = buildMarkerList(cv);

        // Parse titre de l'offre (pour le label de la variante)
        String titreOffre = AiResponseParser.extractBetweenMarkers(rawContent, "TITRE_OFFRE:", allMarkers);

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
                    .poste(qualityService.cleanProfessionalTerm(exp.getPoste()))
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
                    .etablissement(qualityService.clean(edu.getEtablissement()))
                    .diplome(qualityService.cleanProfessionalTerm(edu.getDiplome()))
                    .domaine(qualityService.cleanProfessionalTerm(edu.getDomaine()))
                    .description(enhanced)
                    .build());
        }

        // Parse competences
        String competencesRaw = AiResponseParser.extractBetweenMarkers(rawContent, "COMPETENCES:", allMarkers);
        List<String> parsedSkillNames = parseSkillNames(competencesRaw);
        List<EnhanceCvResponse.SkillEnhancement> skillEnhancements =
                buildSkillEnhancements(cv.getSkills(), parsedSkillNames, level);

        // Parse projets
        List<EnhanceCvResponse.ProjectEnhancement> projEnhancements = new ArrayList<>();
        for (Project proj : cv.getProjects()) {
            String marker = "PROJ_" + proj.getId() + ":";
            String enhanced = AiResponseParser.extractBetweenMarkers(rawContent, marker, allMarkers);
            if (enhanced.isBlank()) enhanced = proj.getDescription() != null ? proj.getDescription() : "";
            projEnhancements.add(EnhanceCvResponse.ProjectEnhancement.builder()
                    .id(proj.getId())
                    .nom(qualityService.cleanProfessionalTerm(proj.getNom()))
                    .description(enhanced)
                    .technologies(qualityService.cleanProfessionalTerm(proj.getTechnologies()))
                    .build());
        }

        List<EnhanceCvResponse.LanguageEnhancement> languageEnhancements = cv.getLanguages().stream()
                .map(language -> EnhanceCvResponse.LanguageEnhancement.builder()
                        .id(language.getId())
                        .langue(qualityService.cleanProfessionalTerm(language.getLangue()))
                        .build())
                .collect(Collectors.toList());

        List<EnhanceCvResponse.CertificationEnhancement> certificationEnhancements =
                cv.getCertifications().stream()
                        .map(certification -> EnhanceCvResponse.CertificationEnhancement.builder()
                                .id(certification.getId())
                                .nom(qualityService.cleanProfessionalTerm(certification.getNom()))
                                .organisme(qualityService.clean(certification.getOrganisme()))
                                .build())
                        .collect(Collectors.toList());

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
        projEnhancements.forEach(p -> p.setDescription(qualityService.clean(p.getDescription())));

        EnhanceCvResponse response = EnhanceCvResponse.builder()
                .titrePoste(cleanedTitre)
                .resumeProfessionnel(cleanedResume)
                .titreOffre(titreOffre.isBlank() ? null : titreOffre)
                .experiences(expEnhancements)
                .educations(eduEnhancements)
                .skills(skillEnhancements.stream()
                        .limit(qualityProperties.maxSkillsDisplayed())
                        .collect(Collectors.toList()))
                .languages(languageEnhancements)
                .certifications(certificationEnhancements)
                .projects(projEnhancements)
                .warnings(qualityService.findReviewWarnings(cv))
                .aiGenerated(!fallback)
                .fallback(fallback)
                .level(level)
                .build();
        response.setCorrectionCount(countCorrections(cv, response));
        return response;
    }

    // ── Construction des prompts ────────────────────────────────────

    private String buildEnhancePrompt(Cv cv, String level) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en redaction de CV professionnels, specialise en optimisation ATS ");
        sb.append("(Applicant Tracking System). Tu connais les attentes des recruteurs en 2026. ");

        sb.append(GRAMMAR_RULE);
        sb.append(TITLE_RULE);
        sb.append(FRANCOPHONE_MARKET_RULE);

        switch (level.toUpperCase()) {
            case "LITE" -> sb.append(
                    "Corrige uniquement l'orthographe, la grammaire et les accents. "
                    + "Garde exactement le même sens et les mêmes mots. "
                    + "Ne reformule PAS, ne change PAS la structure. "
                    + "Ajoute les accents manquants (Developpeur → Développeur). "
                    + PROOFREADING_SKILL_RULE);
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

        appendResponseFormat(sb, cv, false);
        appendCurrentCvData(sb, cv);

        return sb.toString();
    }

    private String buildAdaptPrompt(Cv cv, String jobDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en redaction de CV professionnels. ");
        sb.append("Adapte ce CV pour correspondre au maximum a cette offre d'emploi. ");
        sb.append("Extrait aussi un titre court de l'offre (ex: 'Developpeur Backend Java — Sopra Steria'). ");
        sb.append("OFFRE D'EMPLOI:\n").append(jobDescription).append("\n\n");

        sb.append(GRAMMAR_RULE);
        sb.append(TITLE_RULE);
        sb.append(ANTI_CLICHES_RULE);
        sb.append(STYLE_RULE);
        sb.append(FRANCOPHONE_MARKET_RULE);
        sb.append(QUANTIFICATION_RULE);
        sb.append(SKILL_CATEGORY_RULE);

        appendResponseFormat(sb, cv, true);
        appendCurrentCvData(sb, cv);

        return sb.toString();
    }

    private void appendResponseFormat(StringBuilder sb, Cv cv, boolean includeJobTitle) {
        sb.append("\nReponds en francais uniquement. ");
        sb.append("IMPORTANT: Utilise EXACTEMENT ce format avec les marqueurs :\n\n");
        if (includeJobTitle) {
            sb.append("TITRE_OFFRE:\n(titre court de l'offre, max 60 caracteres, ex: 'Developpeur Backend Java — Sopra Steria')\n\n");
        }
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
        markers.add("TITRE_OFFRE:");
        markers.add("TITRE_POSTE:");
        markers.add("RESUME:");
        for (Experience exp : cv.getExperiences()) markers.add("EXP_" + exp.getId() + ":");
        for (Education edu : cv.getEducations()) markers.add("EDU_" + edu.getId() + ":");
        markers.add("COMPETENCES:");
        for (Project proj : cv.getProjects()) markers.add("PROJ_" + proj.getId() + ":");
        return markers;
    }

    private List<String> parseSkillNames(String competencesRaw) {
        if (competencesRaw == null || competencesRaw.isBlank()) return List.of();
        List<String> names = new ArrayList<>();
        for (String part : competencesRaw.split("[,\\n]")) {
            String skillName = part.replaceAll("^[\\-\\*•]+\\s*", "").strip();
            if (!skillName.isBlank()) names.add(skillName);
        }
        return names;
    }

    private List<EnhanceCvResponse.SkillEnhancement> buildSkillEnhancements(
            List<Skill> originalSkills, List<String> parsedNames, String level) {
        List<EnhanceCvResponse.SkillEnhancement> enhancements = new ArrayList<>();
        boolean correctionOnly = "LITE".equals(level.toUpperCase(Locale.ROOT));

        if (correctionOnly || parsedNames.isEmpty()) {
            for (int i = 0; i < originalSkills.size(); i++) {
                Skill original = originalSkills.get(i);
                String name = i < parsedNames.size() ? parsedNames.get(i) : original.getNom();
                if (!SkillTermPreserver.preserves(original.getNom(), name)) {
                    name = original.getNom();
                }
                enhancements.add(EnhanceCvResponse.SkillEnhancement.builder()
                        .nom(qualityService.cleanProfessionalTerm(name))
                        .niveau(original.getNiveau())
                        .build());
            }
            return enhancements;
        }

        for (int i = 0; i < parsedNames.size(); i++) {
            Integer levelValue = i < originalSkills.size()
                    ? originalSkills.get(i).getNiveau() : 3;
            enhancements.add(EnhanceCvResponse.SkillEnhancement.builder()
                    .nom(qualityService.cleanProfessionalTerm(parsedNames.get(i)))
                    .niveau(levelValue)
                    .build());
        }
        return enhancements;
    }

    private int countCorrections(Cv cv, EnhanceCvResponse response) {
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
