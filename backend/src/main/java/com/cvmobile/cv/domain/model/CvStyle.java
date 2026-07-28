package com.cvmobile.cv.domain.model;

import java.util.Objects;

/**
 * Style de rendu d'un CV : modele, couleur primaire et police (valeur de
 * domaine immuable).
 *
 * <p>Les valeurs par defaut ({@link #defaults()}) reproduisent celles
 * historiquement portees par l'entite de persistance, afin de preserver le
 * comportement observable pendant la migration.
 *
 * @param templateId   identifiant du modele de mise en page (obligatoire)
 * @param primaryColor couleur primaire encodee en ARGB 32 bits (obligatoire)
 * @param fontFamily   famille de police (obligatoire)
 */
public record CvStyle(String templateId, Long primaryColor, String fontFamily) {

    private static final String DEFAULT_TEMPLATE_ID = "moderne";
    private static final long DEFAULT_PRIMARY_COLOR = 4280648683L;
    private static final String DEFAULT_FONT_FAMILY = "Roboto";

    /**
     * Style par defaut applique a tout nouveau CV.
     */
    public static CvStyle defaults() {
        return new CvStyle(DEFAULT_TEMPLATE_ID, DEFAULT_PRIMARY_COLOR, DEFAULT_FONT_FAMILY);
    }

    /**
     * Construit un style personnalise en validant que chaque champ est
     * renseigne.
     *
     * @throws IllegalArgumentException si un champ obligatoire est absent
     */
    public static CvStyle of(String templateId, Long primaryColor, String fontFamily) {
        String safeTemplate = DomainText.requireText(templateId, "templateId");
        String safeFont = DomainText.requireText(fontFamily, "fontFamily");
        if (primaryColor == null) {
            throw new IllegalArgumentException(
                    "Le champ 'primaryColor' est obligatoire.");
        }
        return new CvStyle(safeTemplate, primaryColor, safeFont);
    }

    /** Derive une copie avec un nouveau modele. */
    public CvStyle withTemplateId(String newTemplateId) {
        return of(newTemplateId, primaryColor, fontFamily);
    }

    /** Derive une copie avec une nouvelle couleur primaire. */
    public CvStyle withPrimaryColor(Long newPrimaryColor) {
        return of(templateId, newPrimaryColor, fontFamily);
    }

    /** Derive une copie avec une nouvelle police. */
    public CvStyle withFontFamily(String newFontFamily) {
        return of(templateId, primaryColor, newFontFamily);
    }

    /**
     * Compact constructor : verrouille les invariants meme lorsqu'une instance
     * est construite directement (deserialisation, mapper).
     */
    public CvStyle {
        Objects.requireNonNull(templateId, "templateId");
        Objects.requireNonNull(primaryColor, "primaryColor");
        Objects.requireNonNull(fontFamily, "fontFamily");
    }
}
