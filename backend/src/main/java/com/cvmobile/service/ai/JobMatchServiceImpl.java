package com.cvmobile.service.ai;

import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.client.IAiClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Analyse de correspondance CV / offre d'emploi.
 * Calcule un score ATS et identifie les mots-cles presents/manquants.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class JobMatchServiceImpl implements IJobMatchService {

    private final IAiClient aiClient;
    private final CvRepository cvRepository;

    @Override
    public JobMatchResponse matchJob(Long cvId, String jobDescription) {
        Cv cv = cvRepository.findById(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouve"));

        // Exceptions IA propagees au GlobalExceptionHandler
        return callAiMatch(cv, jobDescription);
    }

    private JobMatchResponse callAiMatch(Cv cv, String jobDescription) {
        String prompt = buildMatchPrompt(cv, jobDescription);
        String rawContent = aiClient.complete(prompt, 1500);
        boolean fallback = aiClient.isFallbackResult();
        log.debug("AI match response received ({} chars)", rawContent.length());

        List<String> allMarkers = List.of(
                "SCORE:", "MOTS_CLES_PRESENTS:", "MOTS_CLES_MANQUANTS:",
                "SUGGESTIONS:", "RESUME_OPTIMISE:");

        int score = 50;
        Matcher scoreMatcher = Pattern.compile("SCORE:\\s*(\\d+)").matcher(rawContent);
        if (scoreMatcher.find()) {
            score = Math.min(100, Integer.parseInt(scoreMatcher.group(1)));
        }

        List<String> matched = AiResponseParser.extractListSection(rawContent, "MOTS_CLES_PRESENTS:", allMarkers);
        List<String> missing = AiResponseParser.extractListSection(rawContent, "MOTS_CLES_MANQUANTS:", allMarkers);
        List<String> suggestions = AiResponseParser.extractListSection(rawContent, "SUGGESTIONS:", allMarkers);
        String optimizedResume = AiResponseParser.extractBetweenMarkers(rawContent, "RESUME_OPTIMISE:", allMarkers);

        return JobMatchResponse.builder()
                .score(score)
                .matchedKeywords(matched)
                .missingKeywords(missing)
                .suggestions(suggestions)
                .optimizedResume(optimizedResume.isBlank() ? null : optimizedResume)
                .aiGenerated(!fallback)
                .fallback(fallback)
                .build();
    }

    private String buildMatchPrompt(Cv cv, String jobDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en recrutement et en optimisation de CV pour les ATS. ");
        sb.append("Analyse ce CV par rapport a cette offre d'emploi et donne un score de correspondance.\n\n");
        sb.append(AiPromptRules.FRANCOPHONE_MARKET_RULE);
        sb.append(AiPromptRules.ANTI_CLICHES_RULE);
        sb.append("Reponds EXACTEMENT dans ce format :\n\n");
        sb.append("SCORE: (nombre de 0 a 100)\n\n");
        sb.append("MOTS_CLES_PRESENTS:\n- mot1\n- mot2\n\n");
        sb.append("MOTS_CLES_MANQUANTS:\n- mot1\n- mot2\n\n");
        sb.append("SUGGESTIONS:\n- suggestion1\n- suggestion2\n- suggestion3\n\n");
        sb.append("RESUME_OPTIMISE:\n(resume professionnel reecrit pour correspondre a cette offre)\n\n");

        sb.append("---\nOFFRE D'EMPLOI :\n").append(jobDescription).append("\n\n");

        sb.append("---\nCV DU CANDIDAT :\n");
        if (cv.getPersonalInfo() != null) {
            sb.append("Poste : ").append(cv.getPersonalInfo().getTitrePoste()).append("\n");
            sb.append("Resume : ").append(cv.getPersonalInfo().getResumeProfessionnel()).append("\n\n");
        }
        sb.append("Competences : ");
        sb.append(cv.getSkills().stream().map(Skill::getNom).collect(Collectors.joining(", ")));
        sb.append("\n\nExperiences :\n");
        for (Experience exp : cv.getExperiences()) {
            sb.append("- ").append(exp.getPoste()).append(" chez ").append(exp.getEntreprise());
            sb.append(" : ").append(exp.getDescription() != null ? exp.getDescription() : "(vide)").append("\n");
        }

        return sb.toString();
    }

}
