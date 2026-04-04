package com.cvmobile.service;

import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.dto.SuggestResponse;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Slf4j
public class AiService {

    @Value("${ai.deepseek.api-key:}")
    private String apiKey;

    @Value("${ai.deepseek.model:deepseek-chat}")
    private String model;

    @Value("${ai.deepseek.base-url:https://api.deepseek.com/v1}")
    private String baseUrl;

    private final RestTemplate restTemplate;
    private final CvRepository cvRepository;

    public AiService(RestTemplateBuilder builder, CvRepository cvRepository) {
        this.restTemplate = builder.build();
        this.cvRepository = cvRepository;
    }

    // ── Suggestions bullet points ───────────────────────────────────────────

    public SuggestResponse generateSuggestions(String poste, String entreprise) {
        if (apiKey != null && !apiKey.isBlank()) {
            try {
                List<String> suggestions = callDeepSeek(buildSuggestPrompt(poste, entreprise), 600);
                return SuggestResponse.builder()
                        .suggestions(suggestions)
                        .aiGenerated(true)
                        .build();
            } catch (Exception e) {
                log.warn("DeepSeek call failed, falling back to mock suggestions: {}", e.getMessage());
            }
        }
        return SuggestResponse.builder()
                .suggestions(generateMockSuggestions(poste, entreprise))
                .aiGenerated(false)
                .build();
    }

    // ── Analyse offre d'emploi + score ATS ─────────────────────────────────

    public JobMatchResponse matchJob(Long cvId, String jobDescription) {
        Cv cv = cvRepository.findById(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouve"));

        if (apiKey == null || apiKey.isBlank()) {
            return buildFallbackMatch(cv, jobDescription);
        }

        try {
            return callDeepSeekMatch(cv, jobDescription);
        } catch (Exception e) {
            log.warn("DeepSeek match failed: {}", e.getMessage());
            return buildFallbackMatch(cv, jobDescription);
        }
    }

    private JobMatchResponse callDeepSeekMatch(Cv cv, String jobDescription) {
        String prompt = buildMatchPrompt(cv, jobDescription);
        String rawContent = callDeepSeekRaw(prompt, 1500);
        log.info("DeepSeek match response:\n{}", rawContent);

        // Parse score
        int score = 50;
        java.util.regex.Matcher scoreMatcher = java.util.regex.Pattern.compile("SCORE:\\s*(\\d+)").matcher(rawContent);
        if (scoreMatcher.find()) {
            score = Math.min(100, Integer.parseInt(scoreMatcher.group(1)));
        }

        // Parse matched keywords
        List<String> matched = extractListSection(rawContent, "MOTS_CLES_PRESENTS:");
        List<String> missing = extractListSection(rawContent, "MOTS_CLES_MANQUANTS:");
        List<String> suggestions = extractListSection(rawContent, "SUGGESTIONS:");
        String optimizedResume = extractBetweenMarkers(rawContent, "RESUME_OPTIMISE:",
                List.of("MOTS_CLES_PRESENTS:", "MOTS_CLES_MANQUANTS:", "SUGGESTIONS:", "SCORE:", "---"));

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

    private List<String> extractListSection(String content, String marker) {
        String section = extractBetweenMarkers(content, marker,
                List.of("MOTS_CLES_PRESENTS:", "MOTS_CLES_MANQUANTS:", "SUGGESTIONS:", "RESUME_OPTIMISE:", "SCORE:", "---"));
        if (section.isBlank()) return List.of();
        return Arrays.stream(section.split("\n"))
                .map(String::trim)
                .filter(l -> !l.isBlank())
                .map(l -> l.replaceAll("^[\\-\\*•]+\\s*", ""))
                .filter(l -> !l.isBlank())
                .collect(Collectors.toList());
    }

    private JobMatchResponse buildFallbackMatch(Cv cv, String jobDescription) {
        // Analyse basique sans IA : chercher les mots de l'offre dans le CV
        String cvText = buildCvText(cv).toLowerCase();
        String[] jobWords = jobDescription.toLowerCase().split("\\W+");
        List<String> matched = new java.util.ArrayList<>();
        List<String> missing = new java.util.ArrayList<>();
        java.util.Set<String> seen = new java.util.HashSet<>();
        java.util.Set<String> stopWords = java.util.Set.of(
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
        cv.getExperiences().forEach(e -> {
            sb.append(e.getPoste()).append(" ").append(e.getDescription()).append(" ");
        });
        cv.getSkills().forEach(s -> sb.append(s.getNom()).append(" "));
        cv.getEducations().forEach(e -> sb.append(e.getDiplome()).append(" ").append(e.getDescription()).append(" "));
        return sb.toString();
    }

    // ── Amélioration CV (Lite / Medium / Max) ──────────────────────────────

    public EnhanceCvResponse enhanceCv(Long cvId, String level) {
        Cv cv = cvRepository.findById(cvId)
                .orElseThrow(() -> new IllegalArgumentException("CV non trouvé"));

        if (apiKey == null || apiKey.isBlank()) {
            return buildFallbackEnhancement(cv, level);
        }

        try {
            return callDeepSeekEnhance(cv, level);
        } catch (Exception e) {
            log.warn("DeepSeek enhance failed: {}", e.getMessage());
            return buildFallbackEnhancement(cv, level);
        }
    }

    private EnhanceCvResponse callDeepSeekEnhance(Cv cv, String level) {
        String prompt = buildEnhancePrompt(cv, level);
        String rawContent = callDeepSeekRaw(prompt, 3000);
        log.info("DeepSeek raw response:\n{}", rawContent);

        // Markers utilises dans le prompt/reponse
        List<String> allMarkers = new java.util.ArrayList<>();
        allMarkers.add("TITRE_POSTE:");
        allMarkers.add("RESUME:");
        for (Experience exp : cv.getExperiences()) allMarkers.add("EXP_" + exp.getId() + ":");
        for (Education edu : cv.getEducations()) allMarkers.add("EDU_" + edu.getId() + ":");
        allMarkers.add("COMPETENCES:");
        for (Project proj : cv.getProjects()) allMarkers.add("PROJ_" + proj.getId() + ":");

        // Parse titre poste
        String titrePoste = extractBetweenMarkers(rawContent, "TITRE_POSTE:", allMarkers);
        if (titrePoste.isBlank() && cv.getPersonalInfo() != null) {
            titrePoste = cv.getPersonalInfo().getTitrePoste();
        }

        // Parse resume
        String resume = extractBetweenMarkers(rawContent, "RESUME:", allMarkers);
        if (resume.isBlank() && cv.getPersonalInfo() != null) {
            resume = cv.getPersonalInfo().getResumeProfessionnel();
        }

        // Parse experiences
        List<EnhanceCvResponse.ExperienceEnhancement> expEnhancements = new java.util.ArrayList<>();
        for (Experience exp : cv.getExperiences()) {
            String marker = "EXP_" + exp.getId() + ":";
            String enhanced = extractBetweenMarkers(rawContent, marker, allMarkers);
            if (enhanced.isBlank()) enhanced = exp.getDescription() != null ? exp.getDescription() : "";
            expEnhancements.add(EnhanceCvResponse.ExperienceEnhancement.builder()
                    .id(exp.getId())
                    .poste(exp.getPoste())
                    .description(enhanced)
                    .build());
        }

        // Parse educations
        List<EnhanceCvResponse.EducationEnhancement> eduEnhancements = new java.util.ArrayList<>();
        for (Education edu : cv.getEducations()) {
            String marker = "EDU_" + edu.getId() + ":";
            String enhanced = extractBetweenMarkers(rawContent, marker, allMarkers);
            if (enhanced.isBlank()) enhanced = edu.getDescription() != null ? edu.getDescription() : "";
            eduEnhancements.add(EnhanceCvResponse.EducationEnhancement.builder()
                    .id(edu.getId())
                    .description(enhanced)
                    .build());
        }

        // Parse competences: liste de competences separees
        String competencesRaw = extractBetweenMarkers(rawContent, "COMPETENCES:", allMarkers);
        List<EnhanceCvResponse.SkillEnhancement> skillEnhancements = new java.util.ArrayList<>();
        if (!competencesRaw.isBlank()) {
            // Chaque ligne ou virgule = une competence
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
        List<EnhanceCvResponse.ProjectEnhancement> projEnhancements = new java.util.ArrayList<>();
        for (Project proj : cv.getProjects()) {
            String marker = "PROJ_" + proj.getId() + ":";
            String enhanced = extractBetweenMarkers(rawContent, marker, allMarkers);
            if (enhanced.isBlank()) enhanced = proj.getDescription() != null ? proj.getDescription() : "";
            projEnhancements.add(EnhanceCvResponse.ProjectEnhancement.builder()
                    .id(proj.getId())
                    .description(enhanced)
                    .build());
        }

        return EnhanceCvResponse.builder()
                .titrePoste(titrePoste)
                .resumeProfessionnel(resume)
                .experiences(expEnhancements)
                .educations(eduEnhancements)
                .skills(skillEnhancements)
                .projects(projEnhancements)
                .aiGenerated(true)
                .level(level)
                .build();
    }

    /** Extrait le contenu entre un marker et le prochain marker connu */
    private String extractBetweenMarkers(String content, String marker, List<String> allMarkers) {
        int start = content.indexOf(marker);
        if (start == -1) return "";
        int contentStart = start + marker.length();

        // Trouver le prochain marker apres contentStart
        int nextMarker = content.length();
        for (String m : allMarkers) {
            if (m.equals(marker)) continue;
            int pos = content.indexOf(m, contentStart);
            if (pos != -1 && pos < nextMarker) nextMarker = pos;
        }
        // Aussi chercher "---" comme separateur
        int sep = content.indexOf("---", contentStart);
        if (sep != -1 && sep < nextMarker) nextMarker = sep;

        return content.substring(contentStart, nextMarker).strip();
    }

    // Mots cliches a remplacer par des formulations concretes
    private static final String ANTI_CLICHES_RULE =
            "REGLE ANTI-CLICHES: Ne JAMAIS utiliser ces mots : motive, determine, dynamique, passionne, "
            + "polyvalent, rigoureux, autonome, force de proposition, esprit d'equipe. "
            + "Remplace-les par des RESULTATS CONCRETS et des VERBES D'ACTION au passe compose: "
            + "Concu, Developpe, Optimise, Reduit, Augmente, Deploye, Automatise, Implemente, Dirige, Livre. ";

    private static final String QUANTIFICATION_RULE =
            "REGLE CHIFFRES: Chaque bullet point DOIT contenir au moins UN chiffre mesurable. "
            + "Exemples: 'Reduit le temps de chargement de 40%', 'Gere une equipe de 5 personnes', "
            + "'Livre 12 fonctionnalites en 3 sprints', 'Augmente la couverture de tests de 20% a 85%'. "
            + "Si le candidat n'a pas fourni de chiffres, invente des chiffres REALISTES et CREDIBLES "
            + "bases sur le contexte du poste. ";

    private String buildEnhancePrompt(Cv cv, String level) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en redaction de CV professionnels, specialise en optimisation ATS ");
        sb.append("(Applicant Tracking System). Tu connais les attentes des recruteurs en 2026. ");

        switch (level.toUpperCase()) {
            case "LITE" -> sb.append(
                    "Corrige uniquement l'orthographe et la grammaire. "
                    + "Garde exactement le meme sens et les memes mots. "
                    + "Ne reformule PAS, ne change PAS la structure. ");
            case "MEDIUM" -> {
                sb.append(
                    "Corrige l'orthographe, reformule pour plus d'impact professionnel. "
                    + "Ameliore la structure des phrases. Utilise des verbes d'action. ");
                sb.append(ANTI_CLICHES_RULE);
            }
            default -> { // MAX
                sb.append(
                    "Optimise completement ce CV pour un maximum d'impact ATS et recruteur. ");
                sb.append(ANTI_CLICHES_RULE);
                sb.append(QUANTIFICATION_RULE);
                sb.append("Pour les competences, separe-les individuellement si elles sont en bloc ");
                sb.append("et ajoute des competences pertinentes liees au poste. ");
                sb.append("Pour le resume, ecris 3-4 phrases percutantes avec des chiffres cles. ");
            }
        }

        sb.append("\nReponds en francais uniquement. ");
        sb.append("IMPORTANT: Utilise EXACTEMENT ce format avec les marqueurs :\n\n");

        // Format attendu
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

        // Donnees actuelles
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

        return sb.toString();
    }

    private EnhanceCvResponse buildFallbackEnhancement(Cv cv, String level) {
        String resume = cv.getPersonalInfo() != null
                ? cv.getPersonalInfo().getResumeProfessionnel()
                : null;
        String titrePoste = cv.getPersonalInfo() != null
                ? cv.getPersonalInfo().getTitrePoste()
                : null;

        List<EnhanceCvResponse.ExperienceEnhancement> exps = cv.getExperiences().stream()
                .map(e -> EnhanceCvResponse.ExperienceEnhancement.builder()
                        .id(e.getId())
                        .poste(e.getPoste())
                        .description(e.getDescription())
                        .build())
                .collect(Collectors.toList());

        List<EnhanceCvResponse.EducationEnhancement> edus = cv.getEducations().stream()
                .map(e -> EnhanceCvResponse.EducationEnhancement.builder()
                        .id(e.getId())
                        .description(e.getDescription())
                        .build())
                .collect(Collectors.toList());

        List<EnhanceCvResponse.SkillEnhancement> skills = cv.getSkills().stream()
                .map(s -> EnhanceCvResponse.SkillEnhancement.builder()
                        .nom(s.getNom())
                        .niveau(s.getNiveau())
                        .build())
                .collect(Collectors.toList());

        List<EnhanceCvResponse.ProjectEnhancement> projs = cv.getProjects().stream()
                .map(p -> EnhanceCvResponse.ProjectEnhancement.builder()
                        .id(p.getId())
                        .description(p.getDescription())
                        .build())
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

    // ── Appels DeepSeek ────────────────────────────────────────────────────

    private List<String> callDeepSeek(String prompt, int maxTokens) {
        String content = callDeepSeekRaw(prompt, maxTokens);
        return parseSuggestions(content);
    }

    private String callDeepSeekRaw(String prompt, int maxTokens) {
        Map<String, Object> requestBody = Map.of(
                "model", model,
                "messages", List.of(Map.of("role", "user", "content", prompt)),
                "max_tokens", maxTokens,
                "temperature", 0.7
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                baseUrl + "/chat/completions",
                HttpMethod.POST,
                entity,
                new org.springframework.core.ParameterizedTypeReference<>() {});

        Map<String, Object> body = response.getBody();
        if (body == null) throw new IllegalStateException("Empty response from DeepSeek");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> choices = (List<Map<String, Object>>) body.get("choices");
        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
        return (String) message.get("content");
    }

    private String buildSuggestPrompt(String poste, String entreprise) {
        String context = entreprise != null && !entreprise.isBlank()
                ? " chez " + entreprise
                : "";
        return "Génère exactement 5 bullet points professionnels en français pour un CV. "
                + "Poste : " + poste + context + ". "
                + "Chaque bullet doit commencer par un verbe d'action au passé composé "
                + "et inclure un résultat mesurable. "
                + "Réponds uniquement avec les 5 points, un par ligne, sans numérotation ni tiret.";
    }

    private List<String> parseSuggestions(String content) {
        return Arrays.stream(content.split("\n"))
                .map(String::trim)
                .filter(line -> !line.isBlank())
                .map(line -> line.replaceAll("^[\\d•\\-–—*]+[.)]?\\s*", ""))
                .filter(line -> !line.isBlank())
                .limit(5)
                .collect(Collectors.toList());
    }

    // ── Mock suggestions ───────────────────────────────────────────────────

    private List<String> generateMockSuggestions(String poste, String entreprise) {
        String lc = poste == null ? "" : poste.toLowerCase();

        if (containsAny(lc, "développeur", "developer", "ingénieur", "engineer", "software", "tech")) {
            return List.of(
                    "Développé et livré des fonctionnalités clés réduisant le temps de réponse de 30%",
                    "Collaboré au sein d'une équipe agile pour tenir les délais de sprint à 95%",
                    "Amélioré la couverture de tests de 20%, réduisant les régressions en production",
                    "Conçu et documenté des APIs RESTful consommées par 3 applications métier",
                    "Résolu des bugs critiques en production dans un délai moyen de 2 heures"
            );
        }
        if (containsAny(lc, "manager", "chef", "lead", "directeur", "responsable")) {
            return List.of(
                    "Dirigé une équipe pluridisciplinaire avec un taux de satisfaction de 95%",
                    "Piloté la livraison de 5 projets stratégiques dans le respect des budgets",
                    "Mis en place une méthodologie agile réduisant les délais de livraison de 25%",
                    "Accompagné 3 collaborateurs vers une promotion interne en 12 mois",
                    "Contribué à la croissance du chiffre d'affaires de 18% sur l'exercice"
            );
        }
        return List.of(
                "Contribué activement à l'atteinte des objectifs d'équipe en dépassant les KPIs fixés",
                "Amélioré les processus internes en réduisant les délais de traitement de 20%",
                "Collaboré avec des parties prenantes internes et externes pour garantir la satisfaction client",
                "Géré plusieurs projets en parallèle dans le respect des délais et des budgets",
                "Proposé et implémenté des solutions innovantes ayant réduit les coûts opérationnels"
        );
    }

    private boolean containsAny(String text, String... keywords) {
        for (String kw : keywords) {
            if (text.contains(kw)) return true;
        }
        return false;
    }
}
