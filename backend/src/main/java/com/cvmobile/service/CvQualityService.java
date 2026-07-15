package com.cvmobile.service;

import com.cvmobile.config.CvQualityProperties;
import com.cvmobile.model.Cv;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
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
@RequiredArgsConstructor
public class CvQualityService implements com.cvmobile.service.quality.ICvQualityService {

    private final CvQualityProperties properties;

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
    private static final Map<String, String> COMMON_FIXES = Map.ofEntries(
            Map.entry("Developpeur", "Développeur"),
            Map.entry("developpeur", "développeur"),
            Map.entry("Ingenieur", "Ingénieur"),
            Map.entry("ingenieur", "ingénieur"),
            Map.entry("experience", "expérience"),
            Map.entry("Experience", "Expérience"),
            Map.entry("Universite", "Université"),
            Map.entry("universite", "université"),
            Map.entry("Francais", "Français"),
            Map.entry("francais", "français"),
            Map.entry("Intermediaire", "Intermédiaire"),
            Map.entry("intermediaire", "intermédiaire"),
            Map.entry("Baccalaureat", "Baccalauréat"),
            Map.entry("baccalaureat", "baccalauréat"),
            Map.entry("Diplome", "Diplôme"),
            Map.entry("diplome", "diplôme"),
            Map.entry("Lycee", "Lycée"),
            Map.entry("lycee", "lycée"),
            Map.entry("Lyce", "Lycée"),
            Map.entry("lyce", "lycée"),
            Map.entry("specialite", "spécialité"),
            Map.entry("Specialite", "Spécialité"),
            Map.entry("securite", "sécurité"),
            Map.entry("Securite", "Sécurité"),
            Map.entry("Competence", "Compétence"),
            Map.entry("competence", "compétence"),
            Map.entry("Competences", "Compétences"),
            Map.entry("competences", "compétences"),
            Map.entry("Developpement", "Développement"),
            Map.entry("developpement", "développement"),
            Map.entry("Integration", "Intégration"),
            Map.entry("integration", "intégration"),
            Map.entry("Creation", "Création"),
            Map.entry("creation", "création"),
            Map.entry("Equipe", "Équipe"),
            Map.entry("equipe", "équipe"),
            Map.entry("Reseau", "Réseau"),
            Map.entry("reseau", "réseau"),
            Map.entry("Reseaux", "Réseaux"),
            Map.entry("reseaux", "réseaux"),
            Map.entry("Systeme", "Système"),
            Map.entry("systeme", "système"),
            Map.entry("Systemes", "Systèmes"),
            Map.entry("systemes", "systèmes"),
            Map.entry("Parallele", "Parallèle"),
            Map.entry("parallele", "parallèle"),
            Map.entry("Resultat", "Résultat"),
            Map.entry("resultat", "résultat"),
            Map.entry("Resultats", "Résultats"),
            Map.entry("resultats", "résultats"),
            Map.entry("Etude", "Étude"),
            Map.entry("etude", "étude"),
            Map.entry("Etudes", "Études"),
            Map.entry("etudes", "études"),
            Map.entry("reponse", "réponse"),
            Map.entry("deploiement", "déploiement"),
            Map.entry("ameliore", "amélioré"),
            Map.entry("Ameliore", "Amélioré"),
            Map.entry("reduit", "réduit"),
            Map.entry("Reduit", "Réduit"),
            Map.entry("cree", "créé"),
            Map.entry("Cree", "Créé"),
            Map.entry("implemente", "implémenté"),
            Map.entry("Implemente", "Implémenté"),
            Map.entry("deploye", "déployé"),
            Map.entry("Deploye", "Déployé"),
            Map.entry("Comminoty", "Community"),
            Map.entry("comminoty", "community"),
            Map.entry("Comunity", "Community"),
            Map.entry("comunity", "community"),
            Map.entry("Managment", "Management"),
            Map.entry("managment", "management"),
            Map.entry("Cote d Ivoire", "Côte d'Ivoire"),
            Map.entry("Cote d'Ivoire", "Côte d'Ivoire")
    );

    private static final Map<String, String> PROFESSIONAL_TERM_FIXES = Map.ofEntries(
            Map.entry("world", "Word"),
            Map.entry("World", "Word"),
            Map.entry("excel", "Excel"),
            Map.entry("powerpoint", "PowerPoint"),
            Map.entry("canva", "Canva"),
            Map.entry("community management", "Community Management"),
            Map.entry("ia", "IA")
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

    @Override
    public String cleanProfessionalTerm(String text) {
        String result = clean(text);
        if (result == null || result.isBlank()) return result;
        return applyKnownFixes(result, PROFESSIONAL_TERM_FIXES).trim();
    }

    @Override
    public List<String> findReviewWarnings(Cv cv) {
        Set<String> warnings = new LinkedHashSet<>();
        String allText = collectCvText(cv);
        String normalized = allText.toLowerCase();

        if (Pattern.compile("(?iu)(?<![\\p{L}\\p{N}])prr(?![\\p{L}\\p{N}])")
                .matcher(allText).find()) {
            warnings.add("Développez le sigle « PRR » au moins une fois pour le recruteur et l'ATS.");
        }
        if (normalized.contains("géré plusieurs projets en parallèle")
                || normalized.contains("gere plusieurs projets en parallele")) {
            warnings.add("Précisez le nombre de projets, les outils utilisés et un résultat concret.");
        }
        if (normalized.contains("dirigé une équipe pluridisciplinaire")
                || normalized.contains("dirige une equipe pluridisciplinaire")) {
            warnings.add("Précisez la taille de l'équipe, votre rôle et la méthode de mesure des résultats.");
        }

        for (int i = 0; i < cv.getExperiences().size(); i++) {
            String description = cv.getExperiences().get(i).getDescription();
            if (description == null || description.isBlank()) {
                warnings.add("Ajoutez une description à l'expérience " + (i + 1) + ".");
            } else if (description.strip().length() < properties.minimumExperienceDescriptionLength()) {
                warnings.add("Détaillez davantage l'expérience " + (i + 1)
                        + " avec missions, outils et résultats vérifiables.");
            }
        }

        return List.copyOf(warnings);
    }

    /**
     * Analyse la qualite du CV et retourne un score + avertissements.
     */
    public QualityReport analyze(String profile, List<String> experienceDescriptions) {
        List<String> warnings = new ArrayList<>();
        List<String> errors = new ArrayList<>();
        int score = properties.initialScore();

        // 1. Verifier le profil
        if (profile == null || profile.isBlank()) {
            errors.add("Pas de résumé professionnel");
            score -= properties.penaltyMissingProfile();
        } else if (profile.length() < properties.minimumProfileLength()) {
            warnings.add("Résumé professionnel trop court (min "
                    + properties.minimumProfileLength() + " caractères)");
            score -= properties.penaltyShortDescription();
        }

        // 2. Detecter les cliches
        if (profile != null) {
            for (String cliche : CLICHES) {
                if (profile.toLowerCase().contains(cliche)) {
                    warnings.add("Mot cliché détecté : \"" + cliche + "\"");
                    score -= properties.penaltyCliche();
                }
            }
        }

        // 3. Verifier les experiences
        if (experienceDescriptions != null) {
            for (int i = 0; i < experienceDescriptions.size(); i++) {
                String desc = experienceDescriptions.get(i);
                if (desc == null || desc.isBlank()) {
                    errors.add("Expérience " + (i + 1) + " sans description");
                    score -= properties.penaltyShortDescription();
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
                score -= properties.penaltyAiTrace();
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
        return applyKnownFixes(text, COMMON_FIXES);
    }

    private String applyKnownFixes(String text, Map<String, String> fixes) {
        String result = text;
        for (var entry : fixes.entrySet()) {
            Pattern wholeTerm = Pattern.compile(
                    "(?<![\\p{L}\\p{N}])" + Pattern.quote(entry.getKey())
                            + "(?![\\p{L}\\p{N}])");
            result = wholeTerm.matcher(result)
                    .replaceAll(Matcher.quoteReplacement(entry.getValue()));
        }
        return result;
    }

    private String collectCvText(Cv cv) {
        StringBuilder text = new StringBuilder();
        if (cv.getPersonalInfo() != null) {
            text.append(cv.getPersonalInfo().getTitrePoste()).append(' ')
                    .append(cv.getPersonalInfo().getResumeProfessionnel()).append(' ');
        }
        cv.getExperiences().forEach(e -> text.append(e.getPoste()).append(' ')
                .append(e.getDescription()).append(' '));
        cv.getEducations().forEach(e -> text.append(e.getDiplome()).append(' ')
                .append(e.getDomaine()).append(' ').append(e.getDescription()).append(' '));
        cv.getSkills().forEach(s -> text.append(s.getNom()).append(' '));
        cv.getProjects().forEach(p -> text.append(p.getNom()).append(' ')
                .append(p.getTechnologies()).append(' ').append(p.getDescription()).append(' '));
        return text.toString();
    }

    @Data
    @Builder
    public static class QualityReport {
        private int score;
        private List<String> warnings;
        private List<String> errors;
    }
}
