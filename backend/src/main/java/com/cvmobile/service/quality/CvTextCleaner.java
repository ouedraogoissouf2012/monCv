package com.cvmobile.service.quality;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Nettoyage du contenu textuel genere par l'IA (issue #253).
 *
 * Extrait de {@code CvQualityService} : suppression du markdown, passage des
 * participes pluriels au singulier, correction des accents manquants et
 * normalisation des termes professionnels. Aucune dependance metier.
 */
@Component
public class CvTextCleaner {

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
     * Nettoie le contenu genere par l'IA : supprime le markdown, corrige les
     * participes pluriels et ajoute les accents manquants.
     */
    public String clean(String text) {
        if (text == null || text.isBlank()) return text;
        String result = text;
        result = cleanMarkdown(result);
        result = fixPluralParticiples(result);
        result = fixAccents(result);
        return result.trim();
    }

    /**
     * Comme {@link #clean(String)}, puis normalise les noms d'outils et de
     * competences (Word, Excel, Community Management, IA...).
     */
    public String cleanProfessionalTerm(String text) {
        String result = clean(text);
        if (result == null || result.isBlank()) return result;
        return applyKnownFixes(result, PROFESSIONAL_TERM_FIXES).trim();
    }

    /**
     * Supprime la premiere ligne de la description si elle repete le
     * poste/entreprise. Ex: "Développeur Full Stack - Studio Digital\n- Conçu..."
     * devient "- Conçu...".
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

    private String cleanMarkdown(String text) {
        String result = MARKDOWN_BOLD.matcher(text).replaceAll("$1");
        result = MARKDOWN_ITALIC.matcher(result).replaceAll("$1");
        result = MARKDOWN_HEADING.matcher(result).replaceAll("");
        return result;
    }

    private String fixPluralParticiples(String text) {
        return PLURAL_PARTICIPLE.matcher(text).replaceAll(m -> {
            String word = m.group();
            // Retirer le 's' final pour passer au singulier
            if (word.endsWith("és")) return word.substring(0, word.length() - 1);
            if (word.endsWith("us")) return word.substring(0, word.length() - 1);
            return word;
        });
    }

    private String fixAccents(String text) {
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
}
