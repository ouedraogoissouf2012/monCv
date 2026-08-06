package com.cvmobile.service.ai;

import com.cvmobile.model.Cv;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Boite a outils d'analyse textuelle pour le matching CV / offre (issue #257).
 *
 * Regroupe la normalisation, la tokenisation, l'extraction de mots-cles et les
 * classifications (technique / soft skill) ainsi que les dictionnaires partages.
 * Extrait de {@code JobMatchServiceImpl} ; sans effet de bord.
 */
@Component
public class JobMatchTextAnalyzer {

    private static final Pattern WORD_PATTERN = Pattern.compile("[\\p{L}\\p{N}][\\p{L}\\p{N}+.#/-]{2,}");

    private static final Set<String> STOP_WORDS = Set.of(
            "avec", "sans", "dans", "pour", "vous", "votre", "notre", "leurs", "elles", "nous",
            "mais", "donc", "etre", "avoir", "faire", "tres", "plus", "moins", "ainsi", "afin",
            "chez", "cette", "poste", "profil", "entreprise", "mission", "missions", "offre",
            "emploi", "candidat", "candidate", "projet", "projets", "travail", "entre",
            "toute", "tous", "tout", "from", "that", "this", "with", "will", "able", "must",
            "need", "needs", "required", "preferred", "experience", "experiences", "years", "year"
    );

    private static final Set<String> SOFT_SKILL_TERMS = Set.of(
            "communication", "leadership", "autonomie", "autonome", "rigueur", "rigoureux",
            "collaboration", "organisation", "empathie", "adaptabilite", "adaptability",
            "teamwork", "stakeholder", "presentation", "negociation", "negotiation",
            "mentoring", "coaching", "facilitation", "gestion", "coordination"
    );

    private static final Set<String> TECH_HINTS = Set.of(
            "java", "spring", "flutter", "dart", "kotlin", "android", "ios", "swift", "python",
            "sql", "nosql", "docker", "kubernetes", "aws", "azure", "gcp", "react", "angular",
            "node", "nodejs", "typescript", "javascript", "figma", "photoshop", "excel",
            "powerbi", "tableau", "scrum", "jira", "sap", "seo", "sem", "crm", "api", "rest",
            "graphql", "git", "github", "gitlab", "firebase", "linux", "mongodb", "postgresql"
    );

    public LinkedHashSet<String> extractKeywords(String jobDescription) {
        LinkedHashSet<String> keywords = new LinkedHashSet<>();
        Matcher matcher = WORD_PATTERN.matcher(normalize(jobDescription));
        while (matcher.find()) {
            String token = matcher.group();
            if (token.length() < 4 || STOP_WORDS.contains(token)) {
                continue;
            }
            keywords.add(token);
        }
        return keywords;
    }

    public boolean isTechnicalKeyword(String keyword) {
        return TECH_HINTS.contains(keyword)
                || keyword.matches(".*\\d.*")
                || keyword.contains("+")
                || keyword.contains("#")
                || keyword.contains("sql");
    }

    public boolean isSoftSkillKeyword(String keyword) {
        return SOFT_SKILL_TERMS.contains(keyword);
    }

    public String extractJobTitle(String jobDescription) {
        String[] lines = jobDescription.split("\\R");
        for (String line : lines) {
            String trimmed = safe(line);
            if (trimmed.length() >= 5 && trimmed.length() <= 80) {
                return normalize(trimmed);
            }
        }
        return "";
    }

    public String collectCvText(Cv cv) {
        StringBuilder text = new StringBuilder();
        text.append(cv.getTitre()).append(' ');
        if (cv.getPersonalInfo() != null) {
            text.append(safe(cv.getPersonalInfo().getTitrePoste())).append(' ')
                    .append(safe(cv.getPersonalInfo().getResumeProfessionnel())).append(' ')
                    .append(safe(cv.getPersonalInfo().getVille())).append(' ')
                    .append(safe(cv.getPersonalInfo().getLinkedIn())).append(' ')
                    .append(safe(cv.getPersonalInfo().getPortfolio())).append(' ');
        }
        cv.getSkills().forEach(skill -> text.append(safe(skill.getNom())).append(' ')
                .append(safe(skill.getCategorie())).append(' '));
        cv.getExperiences().forEach(exp -> text.append(safe(exp.getPoste())).append(' ')
                .append(safe(exp.getEntreprise())).append(' ')
                .append(safe(exp.getDescription())).append(' '));
        cv.getEducations().forEach(education -> text.append(safe(education.getDiplome())).append(' ')
                .append(safe(education.getDomaine())).append(' ')
                .append(safe(education.getDescription())).append(' '));
        cv.getProjects().forEach(project -> text.append(safe(project.getNom())).append(' ')
                .append(safe(project.getTechnologies())).append(' ')
                .append(safe(project.getDescription())).append(' '));
        cv.getCertifications().forEach(certification -> text.append(safe(certification.getNom())).append(' ')
                .append(safe(certification.getOrganisme())).append(' '));
        cv.getLanguages().forEach(language -> text.append(safe(language.getLangue())).append(' ')
                .append(safe(language.getNiveau() != null ? language.getNiveau().name() : null)).append(' '));
        return text.toString();
    }

    public boolean containsTerm(String normalizedText, String keyword) {
        return Pattern.compile("(?<![\\p{L}\\p{N}])" + Pattern.quote(normalize(keyword)) + "(?![\\p{L}\\p{N}])")
                .matcher(normalizedText)
                .find();
    }

    public Set<String> tokenize(String normalizedText) {
        Matcher matcher = WORD_PATTERN.matcher(normalizedText);
        LinkedHashSet<String> tokens = new LinkedHashSet<>();
        while (matcher.find()) {
            String token = matcher.group();
            if (token.length() >= 3 && !STOP_WORDS.contains(token)) {
                tokens.add(token);
            }
        }
        return tokens;
    }

    public String normalize(String text) {
        if (text == null) {
            return "";
        }
        String normalized = Normalizer.normalize(text, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT);
        return normalized.replaceAll("[^\\p{L}\\p{N}+.#/\\-\\s]", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    public List<String> firstItems(List<String> values, int limit) {
        return values.stream()
                .map(this::safe)
                .filter(value -> !value.isBlank())
                .distinct()
                .limit(limit)
                .toList();
    }

    public String restoreSpacing(String normalized) {
        return normalized == null ? "" : normalized.trim().replaceAll("\\s+", " ");
    }

    public String safe(String value) {
        return value == null ? "" : value.trim();
    }

    public String cleanKeyword(String value) {
        return safe(value).replaceAll("^[\\p{Punct}\\s]+|[\\p{Punct}\\s]+$", "");
    }

    public boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
