package com.cvmobile.cv.domain.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Agregat de domaine representant un CV et ses sections.
 *
 * <p><em>Modele de domaine pur</em> : aucune dependance a Spring, JPA, Lombok
 * ou a un type web. Il protege ses invariants (titre et proprietaire
 * obligatoires, variante liee a un parent), n'expose ses collections que par
 * des vues non modifiables, et reference son proprietaire par le seul
 * {@code ownerId} — frontiere nette avec le module compte non encore migre.
 */
public final class Cv {

    private Long id;
    private String titre;
    private final long ownerId;
    private PersonalInfo personalInfo;
    private CvStyle style;

    private final List<Experience> experiences = new ArrayList<>();
    private final List<Education> educations = new ArrayList<>();
    private final List<Skill> skills = new ArrayList<>();
    private final List<Language> languages = new ArrayList<>();
    private final List<Certification> certifications = new ArrayList<>();
    private final List<Project> projects = new ArrayList<>();

    private final Long parentId;
    private final String varianteLabel;

    private int viewCount;
    private int downloadCount;
    private int shareCount;

    private Cv(Long id, String titre, long ownerId, CvStyle style,
               Long parentId, String varianteLabel) {
        this.id = id;
        this.titre = requireTitle(titre);
        this.ownerId = requirePositiveOwner(ownerId);
        this.style = requireStyle(style);
        this.parentId = parentId;
        this.varianteLabel = varianteLabel;
    }

    /**
     * Cree un CV original vierge avec le style par defaut.
     *
     * @throws IllegalArgumentException si le titre est vide ou le proprietaire
     *                                  invalide
     */
    public static Cv create(String titre, long ownerId) {
        return new Cv(null, titre, ownerId, CvStyle.defaults(), null, null);
    }

    /**
     * Cree une variante liee a un CV parent et etiquetee par une offre.
     *
     * @throws IllegalArgumentException si le parent est absent ou le label vide
     */
    public static Cv createVariant(String titre, long ownerId,
                                   Long parentId, String label) {
        if (parentId == null) {
            throw new IllegalArgumentException(
                    "Une variante doit referencer un CV parent (parentId).");
        }
        String safeLabel = DomainText.requireText(label, "label");
        return new Cv(null, titre, ownerId, CvStyle.defaults(), parentId, safeLabel);
    }

    /**
     * Reconstitue un agregat existant (utilise par la couche de persistance).
     * Reserve aux adaptateurs : ne pas appeler depuis la logique metier, qui
     * doit passer par {@link #create} ou {@link #createVariant}.
     */
    public static Cv rehydrate(Long id, String titre, long ownerId, CvStyle style,
                               Long parentId, String varianteLabel,
                               int viewCount, int downloadCount, int shareCount) {
        Cv cv = new Cv(id, titre, ownerId, style, parentId, varianteLabel);
        cv.viewCount = requireNonNegative(viewCount, "viewCount");
        cv.downloadCount = requireNonNegative(downloadCount, "downloadCount");
        cv.shareCount = requireNonNegative(shareCount, "shareCount");
        return cv;
    }

    // ── Identite et proprietes scalaires ─────────────────────────────

    public Long getId() { return id; }

    public String getTitre() { return titre; }

    public long getOwnerId() { return ownerId; }

    public PersonalInfo getPersonalInfo() { return personalInfo; }

    public CvStyle getStyle() { return style; }

    public Long getParentId() { return parentId; }

    public String getVarianteLabel() { return varianteLabel; }

    public int getViewCount() { return viewCount; }

    public int getDownloadCount() { return downloadCount; }

    public int getShareCount() { return shareCount; }

    /**
     * Affecte l'identifiant technique une fois le CV persiste. Reserve a la
     * couche de persistance; refuse toute reaffectation.
     */
    public void assignId(Long persistedId) {
        if (this.id != null) {
            throw new IllegalStateException(
                    "L'identifiant du CV est deja affecte et immuable.");
        }
        if (persistedId == null) {
            throw new IllegalArgumentException("persistedId ne peut etre null.");
        }
        this.id = persistedId;
    }

    /** Un CV est une variante des lors qu'il porte un label de variante. */
    public boolean isVariante() {
        return varianteLabel != null;
    }

    // ── Comportements metier ─────────────────────────────────────────

    /** Renomme le CV en normalisant et validant le titre. */
    public void rename(String newTitre) {
        this.titre = requireTitle(newTitre);
    }

    /** Remplace le style; refuse un style absent. */
    public void changeStyle(CvStyle newStyle) {
        this.style = requireStyle(newStyle);
    }

    /** Met a jour les informations personnelles (peut etre nul si effacees). */
    public void changePersonalInfo(PersonalInfo newPersonalInfo) {
        this.personalInfo = newPersonalInfo;
    }

    /** Enregistre une consultation (compteur calcule cote serveur). */
    public void registerView() {
        this.viewCount++;
    }

    /** Enregistre un telechargement (compteur calcule cote serveur). */
    public void registerDownload() {
        this.downloadCount++;
    }

    /** Enregistre un partage (compteur calcule cote serveur). */
    public void registerShare() {
        this.shareCount++;
    }

    // ── Collections : vues non modifiables + mutations controlees ─────

    public List<Experience> getExperiences() {
        return Collections.unmodifiableList(experiences);
    }

    public List<Education> getEducations() {
        return Collections.unmodifiableList(educations);
    }

    public List<Skill> getSkills() {
        return Collections.unmodifiableList(skills);
    }

    public List<Language> getLanguages() {
        return Collections.unmodifiableList(languages);
    }

    public List<Certification> getCertifications() {
        return Collections.unmodifiableList(certifications);
    }

    public List<Project> getProjects() {
        return Collections.unmodifiableList(projects);
    }

    public void addExperience(Experience e) {
        experiences.add(require(e, "experience"));
    }

    public void addEducation(Education e) {
        educations.add(require(e, "education"));
    }

    public void addSkill(Skill s) {
        skills.add(require(s, "skill"));
    }

    public void addLanguage(Language l) {
        languages.add(require(l, "language"));
    }

    public void addCertification(Certification c) {
        certifications.add(require(c, "certification"));
    }

    public void addProject(Project p) {
        projects.add(require(p, "project"));
    }

    public void replaceExperiences(List<Experience> items) {
        replace(experiences, items, "experience");
    }

    public void replaceEducations(List<Education> items) {
        replace(educations, items, "education");
    }

    public void replaceSkills(List<Skill> items) {
        replace(skills, items, "skill");
    }

    public void replaceLanguages(List<Language> items) {
        replace(languages, items, "language");
    }

    public void replaceCertifications(List<Certification> items) {
        replace(certifications, items, "certification");
    }

    public void replaceProjects(List<Project> items) {
        replace(projects, items, "project");
    }

    // ── Helpers prives ───────────────────────────────────────────────

    private static <T> void replace(List<T> target, List<T> items, String label) {
        target.clear();
        if (items == null) {
            return;
        }
        for (T item : items) {
            target.add(require(item, label));
        }
    }

    private static <T> T require(T value, String label) {
        if (value == null) {
            throw new IllegalArgumentException(
                    "Un element '" + label + "' ne peut etre null.");
        }
        return value;
    }

    private static String requireTitle(String titre) {
        return DomainText.requireText(titre, "titre");
    }

    private static CvStyle requireStyle(CvStyle style) {
        if (style == null) {
            throw new IllegalArgumentException("Le champ 'style' est obligatoire.");
        }
        return style;
    }

    private static long requirePositiveOwner(long ownerId) {
        if (ownerId <= 0) {
            throw new IllegalArgumentException(
                    "Le champ 'ownerId' doit etre strictement positif (recu : "
                            + ownerId + ").");
        }
        return ownerId;
    }

    private static int requireNonNegative(int value, String field) {
        if (value < 0) {
            throw new IllegalArgumentException(
                    "Le champ '" + field + "' ne peut etre negatif (recu : "
                            + value + ").");
        }
        return value;
    }
}
