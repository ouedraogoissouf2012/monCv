package com.cvmobile.service.ai;

import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.client.IAiClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
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
        log.info("AI match response:\n{}", rawContent);

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
                .aiGenerated(true)
                .build();
    }

    private String buildMatchPrompt(Cv cv, String jobDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en recrutement et en optimisation de CV pour les ATS. ");
        sb.append("Analyse ce CV par rapport a cette offre d'emploi et donne un score de correspondance.\n\n");
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

    private JobMatchResponse buildFallbackMatch(Cv cv, String jobDescription) {
        String cvText = buildCvText(cv).toLowerCase();
        String[] jobWords = jobDescription.toLowerCase().split("\\W+");
        java.util.List<String> matched = new java.util.ArrayList<>();
        java.util.List<String> missing = new java.util.ArrayList<>();
        Set<String> seen = new java.util.HashSet<>();
        Set<String> stopWords = Set.of(
                "le", "la", "les", "de", "du", "des", "un", "une", "et", "ou", "en",
                "pour", "avec", "dans", "sur", "par", "au", "aux", "est", "sont",
                "nous", "vous", "il", "elle", "ce", "cette", "son", "sa", "ses",
                "qui", "que", "dont", "ou", "plus", "moins", "tres", "bien", "etre",
                "avoir", "faire", "entre", "votre", "notre", "leur");

        for (String word : jobWords) {
            if (word.length() < 4 || stopWords.contains(word) || seen.contains(word)) continue;
            seen.add(word);
            if (cvText.contains(word)) {
                matched.add(word);
            } else {
                missing.add(word);
            }
        }

        int score = matched.isEmpty() && missing.isEmpty() ? 0
                : (int) ((matched.size() * 100.0) / (matched.size() + missing.size()));

        return JobMatchResponse.builder()
                .score(score)
                .matchedKeywords(matched.stream().limit(15).collect(Collectors.toList()))
                .missingKeywords(missing.stream().limit(10).collect(Collectors.toList()))
                .suggestions(List.of(
                        "Ajoutez les mots-cles manquants dans votre resume professionnel",
                        "Adaptez vos descriptions d'experience au vocabulaire de l'offre",
                        "Mentionnez les technologies specifiques demandees"))
                .aiGenerated(false)
                .build();
    }

    private String buildCvText(Cv cv) {
        StringBuilder sb = new StringBuilder();
        if (cv.getPersonalInfo() != null) {
            sb.append(cv.getPersonalInfo().getTitrePoste()).append(" ");
            sb.append(cv.getPersonalInfo().getResumeProfessionnel()).append(" ");
        }
        cv.getExperiences().forEach(e ->
                sb.append(e.getPoste()).append(" ").append(e.getDescription()).append(" "));
        cv.getSkills().forEach(s -> sb.append(s.getNom()).append(" "));
        cv.getEducations().forEach(e ->
                sb.append(e.getDiplome()).append(" ").append(e.getDescription()).append(" "));
        return sb.toString();
    }
}
