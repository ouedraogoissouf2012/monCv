package com.cvmobile.service.quality;

import com.cvmobile.config.CvQualityProperties;
import com.cvmobile.model.Cv;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Detecte les avertissements de revue d'un CV (issue #253) : sigles a
 * developper, phrases generiques a preciser, descriptions d'experience
 * manquantes ou trop courtes.
 *
 * Extrait de {@code CvQualityService}. La longueur minimale de description est
 * pilotee par {@link CvQualityProperties}.
 */
@Component
@RequiredArgsConstructor
public class CvReviewAnalyzer {

    // Sigle "PRR" isole (insensible casse/accents), a developper au moins une fois.
    private static final Pattern PRR_ACRONYM =
            Pattern.compile("(?iu)(?<![\\p{L}\\p{N}])prr(?![\\p{L}\\p{N}])");

    private final CvQualityProperties properties;

    /**
     * Retourne les avertissements de revue, sans doublon et dans l'ordre de
     * detection.
     */
    public List<String> findReviewWarnings(Cv cv) {
        Set<String> warnings = new LinkedHashSet<>();
        String allText = collectCvText(cv);
        String normalized = allText.toLowerCase();

        if (PRR_ACRONYM.matcher(allText).find()) {
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
}
