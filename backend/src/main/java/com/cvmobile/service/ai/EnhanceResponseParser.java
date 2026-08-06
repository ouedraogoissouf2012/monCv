package com.cvmobile.service.ai;

import com.cvmobile.config.CvQualityProperties;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.service.quality.ICvQualityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

/**
 * Transforme la reponse brute de l'IA en {@link EnhanceCvResponse} (issue #256).
 * Extrait de {@code EnhancementServiceImpl}.
 *
 * Extrait chaque section via ses marqueurs, retombe sur les valeurs d'origine
 * quand l'IA n'a rien fourni, applique le nettoyage qualite et compte les
 * corrections via {@link CorrectionCounter}.
 */
@Component
@RequiredArgsConstructor
public class EnhanceResponseParser {

    private static final int DEFAULT_SKILL_LEVEL = 3;

    private final ICvQualityService qualityService;
    private final CvQualityProperties qualityProperties;
    private final CorrectionCounter correctionCounter;

    public EnhanceCvResponse parse(String rawContent, Cv cv, String level,
                                   boolean fallback, boolean allowTitleChange) {
        List<String> allMarkers = buildMarkerList(cv);

        // Parse titre de l'offre (pour le label de la variante)
        String titreOffre = AiResponseParser.extractBetweenMarkers(rawContent, "TITRE_OFFRE:", allMarkers);

        // Parse titre poste
        String titrePoste = AiResponseParser.extractBetweenMarkers(rawContent, "TITRE_POSTE:", allMarkers);
        if (titrePoste.isBlank() && cv.getPersonalInfo() != null) {
            titrePoste = cv.getPersonalInfo().getTitrePoste();
        }
        String originalTitle = cv.getPersonalInfo() == null ? null : cv.getPersonalInfo().getTitrePoste();
        if (!allowTitleChange && originalTitle != null && !SkillTermPreserver.preserves(originalTitle, titrePoste)) titrePoste = originalTitle;

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
        response.setCorrectionCount(correctionCounter.countCorrections(cv, response));
        return response;
    }

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
                    ? originalSkills.get(i).getNiveau() : DEFAULT_SKILL_LEVEL;
            enhancements.add(EnhanceCvResponse.SkillEnhancement.builder()
                    .nom(qualityService.cleanProfessionalTerm(parsedNames.get(i)))
                    .niveau(levelValue)
                    .build());
        }
        return enhancements;
    }
}
