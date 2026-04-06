package com.cvmobile.service;

import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Service de controle qualite du contenu genere par l'IA.
 * Applique des regles grammaticales, detecte les traces IA,
 * et nettoie le contenu avant affichage/export.
 */
@Slf4j
@Service
public class CvQualityService {

    // Mots cliches a detecter
    private static final Set<String> CLICHES = Set.of(
            "motivé", "motive", "dynamique", "passionné", "passionne",
            "rigoureux", "autonome", "polyvalent", "force de proposition",
            "esprit d'équipe", "esprit d'equipe", "proactif", "réactif", "reactif",
            "approche orientée résultats", "expérience avérée", "cycles optimisés",
            "forte capacité", "sens du détail", "grande aisance"
    );

    // Participes qui doivent etre au singulier
    private static final Pattern PLURAL_PARTICIPLE = Pattern.compile(
            "\\b(Conçus|Développés|Implémentés|Optimisés|Résolus|Déployés|Livrés|Créés|Rédigés|Supervisés|Automatisés|Gérés|Améliorés)\\b"
    );

    // Markdown a nettoyer
    private static final Pattern MARKDOWN_BOLD = Pattern.compile("\\*\\*([^*]+)\\*\\*");
    private static final Pattern MARKDOWN_ITALIC = Pattern.compile("\\*([^*]+)\\*");
    private static final Pattern MARKDOWN_HEADING = Pattern.compile("^#{1,3}\\s+", Pattern.MULTILINE);

    // Mots courants sans accents
    private static final java.util.Map<String, String> ACCENT_FIXES = java.util.Map.ofEntries(
            java.util.Map.entry("Developpeur", "Développeur"),
            java.util.Map.entry("developpeur", "développeur"),
            java.util.Map.entry("Ingenieur", "Ingénieur"),
            java.util.Map.entry("ingenieur", "ingénieur"),
            java.util.Map.entry("experience", "expérience"),
            java.util.Map.entry("Experience", "Expérience"),
            java.util.Map.entry("Universite", "Université"),
            java.util.Map.entry("universite", "université"),
            java.util.Map.entry("Francais", "Français"),
            java.util.Map.entry("francais", "français"),
            java.util.Map.entry("Intermediaire", "Intermédiaire"),
            java.util.Map.entry("intermediaire", "intermédiaire"),
            java.util.Map.entry("Lycee", "Lycée"),
            java.util.Map.entry("lycee", "lycée"),
            java.util.Map.entry("specialite", "spécialité"),
            java.util.Map.entry("Specialite", "Spécialité"),
            java.util.Map.entry("securite", "sécurité"),
            java.util.Map.entry("Securite", "Sécurité"),
            java.util.Map.entry("reponse", "réponse"),
            java.util.Map.entry("deploiement", "déploiement"),
            java.util.Map.entry("ameliore", "amélioré"),
            java.util.Map.entry("Ameliore", "Amélioré"),
            java.util.Map.entry("reduit", "réduit"),
            java.util.Map.entry("Reduit", "Réduit"),
            java.util.Map.entry("cree", "créé"),
            java.util.Map.entry("Cree", "Créé"),
            java.util.Map.entry("implemente", "implémenté"),
            java.util.Map.entry("Implemente", "Implémenté"),
            java.util.Map.entry("deploye", "déployé"),
            java.util.Map.entry("Deploye", "Déployé"),
            java.util.Map.entry("Cote d Ivoire", "Côte d'Ivoire"),
            java.util.Map.entry("Cote d'Ivoire", "Côte d'Ivoire")
    );

    /**
     * Nettoie le contenu genere par l'IA :
     * - Supprime le markdown
     * - Corrige les participes pluriels
     * - Ajoute les accents manquants
     */
    public String clean(String text) {
        if (text == null || text.isBlank()) return text;
        String result = text;

        // 1. Nettoyer le markdown
        result = cleanMarkdown(result);

        // 2. Corriger les participes pluriels → singulier
        result = fixPluralParticiples(result);

        // 3. Ajouter les accents manquants
        result = fixAccents(result);

        return result.trim();
    }

    /**
     * Analyse la qualite du CV et retourne un score + avertissements.
     */
    public QualityReport analyze(String profile, List<String> experienceDescriptions) {
        List<String> warnings = new ArrayList<>();
        List<String> errors = new ArrayList<>();
        int score = 100;

        // 1. Verifier le profil
        if (profile == null || profile.isBlank()) {
            errors.add("Pas de résumé professionnel");
            score -= 20;
        } else if (profile.length() < 100) {
            warnings.add("Résumé professionnel trop court (min 100 caractères)");
            score -= 10;
        }

        // 2. Detecter les cliches
        if (profile != null) {
            for (String cliche : CLICHES) {
                if (profile.toLowerCase().contains(cliche)) {
                    warnings.add("Mot cliché détecté : \"" + cliche + "\"");
                    score -= 5;
                }
            }
        }

        // 3. Verifier les experiences
        if (experienceDescriptions != null) {
            for (int i = 0; i < experienceDescriptions.size(); i++) {
                String desc = experienceDescriptions.get(i);
                if (desc == null || desc.isBlank()) {
                    errors.add("Expérience " + (i + 1) + " sans description");
                    score -= 10;
                }
            }

            // 4. Detecter la repetition mecanique
            if (experienceDescriptions.size() >= 2) {
                boolean allSameStructure = true;
                for (String desc : experienceDescriptions) {
                    if (desc != null && !desc.trim().startsWith("-") && !desc.contains("\n-")) {
                        allSameStructure = false;
                        break;
                    }
                }
                // Ce n'est pas un probleme si les structures varient
            }
        }

        // 5. Detecter les traces IA
        if (profile != null) {
            Matcher m = PLURAL_PARTICIPLE.matcher(profile);
            while (m.find()) {
                errors.add("Participe pluriel détecté : \"" + m.group() + "\" → utiliser le singulier");
                score -= 5;
            }
        }

        return QualityReport.builder()
                .score(Math.max(0, score))
                .warnings(warnings)
                .errors(errors)
                .build();
    }

    // ── Nettoyage ────────────────────────────────────────────────

    /**
     * Supprime la premiere ligne de la description si elle repete le poste/entreprise.
     * Ex: "Développeur Full Stack - DIGIT AFRICAN\n- Conçu..." → "- Conçu..."
     */
    public String removeRepeatedTitle(String description, String poste, String entreprise) {
        if (description == null || description.isBlank()) return description;
        String[] lines = description.split("\n", 2);
        if (lines.length < 2) return description;

        String firstLine = lines[0].trim().toLowerCase();
        boolean repeats = false;
        if (poste != null && firstLine.contains(poste.toLowerCase())) repeats = true;
        if (entreprise != null && firstLine.contains(entreprise.toLowerCase())) repeats = true;
        // Detecter aussi les patterns "Titre | Entreprise" ou "Titre - Entreprise"
        if (firstLine.contains("|") || (firstLine.contains("-") && !firstLine.startsWith("-"))) {
            if (!firstLine.startsWith("-")) repeats = true;
        }

        return repeats ? lines[1].trim() : description;
    }

    String cleanMarkdown(String text) {
        String result = MARKDOWN_BOLD.matcher(text).replaceAll("$1");
        result = MARKDOWN_ITALIC.matcher(result).replaceAll("$1");
        result = MARKDOWN_HEADING.matcher(result).replaceAll("");
        return result;
    }

    String fixPluralParticiples(String text) {
        return PLURAL_PARTICIPLE.matcher(text).replaceAll(m -> {
            String word = m.group();
            // Retirer le 's' final pour passer au singulier
            if (word.endsWith("és")) return word.substring(0, word.length() - 1);
            if (word.endsWith("us")) return word.substring(0, word.length() - 1);
            return word;
        });
    }

    String fixAccents(String text) {
        String result = text;
        for (var entry : ACCENT_FIXES.entrySet()) {
            result = result.replace(entry.getKey(), entry.getValue());
        }
        return result;
    }

    @Data
    @Builder
    public static class QualityReport {
        private int score;
        private List<String> warnings;
        private List<String> errors;
    }
}
