package com.cvmobile.cv.adapter.out.persistence;

import com.cvmobile.cv.domain.model.Certification;
import com.cvmobile.cv.domain.model.Education;
import com.cvmobile.cv.domain.model.Experience;
import com.cvmobile.cv.domain.model.Language;
import com.cvmobile.cv.domain.model.LanguageLevel;
import com.cvmobile.cv.domain.model.Project;
import com.cvmobile.cv.domain.model.Skill;

/**
 * Conversion des sections (experiences, formations, competences, langues,
 * certifications, projets) entre entites JPA enfants et value objects de
 * domaine. La back-reference {@code cv} des entites est posee par l'agregat
 * {@code model.Cv} lors de l'ajout, pas ici.
 */
final class CvSectionPersistenceMapper {

    private CvSectionPersistenceMapper() {
    }

    // ── Experience ───────────────────────────────────────────────────

    static Experience toDomain(com.cvmobile.model.Experience e) {
        return Experience.of(e.getId(), e.getEntreprise(), e.getPoste(), e.getLieu(),
                e.getDateDebut(), e.getDateFin(), e.getDescription(), e.getActuel());
    }

    static com.cvmobile.model.Experience toEntity(Experience e) {
        return com.cvmobile.model.Experience.builder()
                .id(e.id()).entreprise(e.entreprise()).poste(e.poste()).lieu(e.lieu())
                .dateDebut(e.dateDebut()).dateFin(e.dateFin())
                .description(e.description()).actuel(e.actuel())
                .build();
    }

    // ── Education ────────────────────────────────────────────────────

    static Education toDomain(com.cvmobile.model.Education e) {
        return Education.of(e.getId(), e.getEtablissement(), e.getDiplome(),
                e.getDomaine(), e.getDateDebut(), e.getDateFin(), e.getDescription());
    }

    static com.cvmobile.model.Education toEntity(Education e) {
        return com.cvmobile.model.Education.builder()
                .id(e.id()).etablissement(e.etablissement()).diplome(e.diplome())
                .domaine(e.domaine()).dateDebut(e.dateDebut()).dateFin(e.dateFin())
                .description(e.description())
                .build();
    }

    // ── Skill ────────────────────────────────────────────────────────

    static Skill toDomain(com.cvmobile.model.Skill s) {
        return Skill.of(s.getId(), s.getNom(), s.getNiveau(), s.getCategorie());
    }

    static com.cvmobile.model.Skill toEntity(Skill s) {
        return com.cvmobile.model.Skill.builder()
                .id(s.id()).nom(s.nom()).niveau(s.niveau()).categorie(s.categorie())
                .build();
    }

    // ── Language ─────────────────────────────────────────────────────

    static Language toDomain(com.cvmobile.model.Language l) {
        return Language.of(l.getId(), l.getLangue(), toDomainLevel(l.getNiveau()));
    }

    static com.cvmobile.model.Language toEntity(Language l) {
        return com.cvmobile.model.Language.builder()
                .id(l.id()).langue(l.langue()).niveau(toEntityLevel(l.niveau()))
                .build();
    }

    private static LanguageLevel toDomainLevel(com.cvmobile.model.Language.NiveauLangue n) {
        return n == null ? null : LanguageLevel.valueOf(n.name());
    }

    private static com.cvmobile.model.Language.NiveauLangue toEntityLevel(LanguageLevel n) {
        return n == null ? null : com.cvmobile.model.Language.NiveauLangue.valueOf(n.name());
    }

    // ── Certification ────────────────────────────────────────────────

    static Certification toDomain(com.cvmobile.model.Certification c) {
        return Certification.of(c.getId(), c.getNom(), c.getOrganisme(),
                c.getDateObtention(), c.getDateExpiration(), c.getCredentialUrl());
    }

    static com.cvmobile.model.Certification toEntity(Certification c) {
        return com.cvmobile.model.Certification.builder()
                .id(c.id()).nom(c.nom()).organisme(c.organisme())
                .dateObtention(c.dateObtention()).dateExpiration(c.dateExpiration())
                .credentialUrl(c.credentialUrl())
                .build();
    }

    // ── Project ──────────────────────────────────────────────────────

    static Project toDomain(com.cvmobile.model.Project p) {
        return Project.of(p.getId(), p.getNom(), p.getDescription(),
                p.getTechnologies(), p.getLien(), p.getDateDebut(), p.getDateFin());
    }

    static com.cvmobile.model.Project toEntity(Project p) {
        return com.cvmobile.model.Project.builder()
                .id(p.id()).nom(p.nom()).description(p.description())
                .technologies(p.technologies()).lien(p.lien())
                .dateDebut(p.dateDebut()).dateFin(p.dateFin())
                .build();
    }
}
