package com.cvmobile.service.ai;

import com.cvmobile.dto.ApplicationMessagesResponse;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.client.IAiClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ApplicationMessageServiceImpl implements IApplicationMessageService {

    private static final String COVER_LETTER = "LETTRE_MOTIVATION:";
    private static final String EMAIL = "EMAIL_CANDIDATURE:";
    private static final String LINKEDIN = "MESSAGE_LINKEDIN:";
    private static final String WHATSAPP = "MESSAGE_WHATSAPP:";
    private static final List<String> MARKERS = List.of(COVER_LETTER, EMAIL, LINKEDIN, WHATSAPP);

    private final IAiClient aiClient;
    private final CvRepository cvRepository;

    @Override
    @Transactional(readOnly = true)
    public ApplicationMessagesResponse generate(Long cvId, String jobDescription, String tone) {
        Cv cv = cvRepository.findByIdWithDetails(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouve"));

        String resolvedTone = normalizeTone(tone);
        String rawContent = aiClient.complete(buildPrompt(cv, jobDescription, resolvedTone), 2400);
        boolean fallback = aiClient.isFallbackResult();
        log.debug("AI application messages received ({} chars)", rawContent.length());

        String coverLetter = extractAndClean(rawContent, COVER_LETTER);
        String email = extractAndClean(rawContent, EMAIL);
        String linkedIn = extractAndClean(rawContent, LINKEDIN);
        String whatsApp = extractAndClean(rawContent, WHATSAPP);

        if (coverLetter.isBlank() || email.isBlank() || linkedIn.isBlank() || whatsApp.isBlank()) {
            throw new AiParseException("ai", "un ou plusieurs messages de candidature sont absents", null);
        }

        return ApplicationMessagesResponse.builder()
                .coverLetter(coverLetter)
                .email(email)
                .linkedIn(linkedIn)
                .whatsApp(whatsApp)
                .tone(resolvedTone)
                .aiGenerated(!fallback)
                .fallback(fallback)
                .build();
    }

    private String extractAndClean(String rawContent, String marker) {
        String value = AiResponseParser.extractBetweenMarkers(rawContent, marker, MARKERS);
        return value
                .replace("```text", "")
                .replace("```", "")
                .replace("**", "")
                .replace("__", "")
                .replaceAll("(?m)^#{1,6}\\s*", "")
                .replaceAll("(?m)^[\\-*]\\s+(?=\\S)", "")
                .strip();
    }

    private String normalizeTone(String tone) {
        if (tone == null || tone.isBlank()) return "PROFESSIONAL";
        return tone.trim().toUpperCase(Locale.ROOT);
    }

    private String buildPrompt(Cv cv, String jobDescription, String tone) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("Tu es un conseiller en recrutement. Genere quatre textes de candidature en francais, ")
                .append("strictement bases sur les informations reelles du CV et de l'offre. ")
                .append("N'invente aucun diplome, resultat, outil, entreprise, contact ou nombre.\n")
                .append(AiPromptRules.FRANCOPHONE_MARKET_RULE).append('\n')
                .append(AiPromptRules.ANTI_CLICHES_RULE).append('\n')
                .append("Ne produis aucun markdown, aucune note et aucun texte hors des quatre sections. ")
                .append("Utilise le ton ").append(toneInstruction(tone)).append(".\n")
                .append("La lettre doit faire 220 a 320 mots et comporter des paragraphes courts. ")
                .append("L'email doit faire 80 a 130 mots avec un objet sur la premiere ligne. ")
                .append("Le message LinkedIn doit rester sous 500 caracteres. ")
                .append("Le message WhatsApp doit rester sous 450 caracteres et rester professionnel.\n\n")
                .append("Reponds EXACTEMENT avec ces marqueurs :\n")
                .append(COVER_LETTER).append("\n(texte)\n\n")
                .append(EMAIL).append("\n(texte)\n\n")
                .append(LINKEDIN).append("\n(texte)\n\n")
                .append(WHATSAPP).append("\n(texte)\n\n")
                .append("---\nOFFRE D'EMPLOI :\n").append(jobDescription.strip()).append("\n\n")
                .append("---\nDONNEES REELLES DU CV :\n")
                .append(cvFacts(cv));
        return prompt.toString();
    }

    private String toneInstruction(String tone) {
        return switch (tone) {
            case "SIMPLE" -> "simple, naturel et facile a lire";
            case "DIRECT" -> "direct, concis et centre sur la valeur apportee";
            case "JUNIOR" -> "junior, humble et axe sur les acquis et la progression";
            case "SENIOR" -> "senior, assure et axe sur l'impact et les responsabilites";
            default -> "professionnel, courtois et factuel";
        };
    }

    private String cvFacts(Cv cv) {
        StringBuilder facts = new StringBuilder();
        PersonalInfo info = cv.getPersonalInfo();
        if (info != null) {
            facts.append("Nom : ").append(safe(info.getPrenom())).append(' ')
                    .append(safe(info.getNom())).append('\n');
            facts.append("Poste : ").append(safe(info.getTitrePoste())).append('\n');
            facts.append("Resume : ").append(safe(info.getResumeProfessionnel())).append('\n');
            facts.append("Ville/Pays : ").append(safe(info.getVille())).append(" / ")
                    .append(safe(info.getPays())).append('\n');
        }
        facts.append("Competences : ").append(cv.getSkills().stream()
                .map(Skill::getNom).filter(this::notBlank).collect(Collectors.joining(", "))).append('\n');
        facts.append("Experiences :\n");
        for (Experience experience : cv.getExperiences()) {
            facts.append("- ").append(safe(experience.getPoste())).append(" | ")
                    .append(safe(experience.getEntreprise())).append(" | ")
                    .append(safe(experience.getDescription())).append('\n');
        }
        facts.append("Formations :\n");
        for (Education education : cv.getEducations()) {
            facts.append("- ").append(safe(education.getDiplome())).append(" | ")
                    .append(safe(education.getDomaine())).append(" | ")
                    .append(safe(education.getEtablissement())).append('\n');
        }
        facts.append("Projets :\n");
        for (Project project : cv.getProjects()) {
            facts.append("- ").append(safe(project.getNom())).append(" | ")
                    .append(safe(project.getDescription())).append(" | ")
                    .append(safe(project.getTechnologies())).append('\n');
        }
        return facts.toString();
    }

    private boolean notBlank(String value) {
        return value != null && !value.isBlank();
    }

    private String safe(String value) {
        return value == null ? "" : value.strip();
    }
}
