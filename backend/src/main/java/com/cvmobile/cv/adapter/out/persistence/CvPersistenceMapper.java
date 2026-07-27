package com.cvmobile.cv.adapter.out.persistence;

import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.CvStyle;
import org.springframework.stereotype.Component;

/**
 * Mapper bidirectionnel entre l'entite JPA {@code model.Cv} (adapter de
 * persistance) et l'agregat de domaine {@link Cv} (issue #255, ADR 003).
 *
 * <p>Sens {@code toDomain} : conversion totale de ce que le domaine modelise.
 * Sens {@code applyToEntity} : applique les champs modelises sur une entite
 * (neuve ou existante) <strong>sans toucher</strong> aux champs non modelises
 * par le domaine (jetons de partage public et drapeaux associes), afin qu'une
 * mise a jour de CV ne detruise pas l'etat de partage gere ailleurs. Les
 * collections sont remplacees via les methodes de l'agregat JPA, preservant la
 * gestion des orphelins (orphanRemoval) et posant la back-reference.
 */
@Component
public class CvPersistenceMapper {

    /** JPA -> domaine : reconstitue l'agregat tel qu'enregistre. */
    public Cv toDomain(com.cvmobile.model.Cv entity) {
        CvStyle style = CvStyle.of(
                entity.getStyleTemplateId(),
                entity.getStylePrimaryColor(),
                entity.getStyleFontFamily());

        Cv cv = Cv.rehydrate(
                entity.getId(),
                entity.getTitre(),
                ownerIdOf(entity),
                style,
                parentIdOf(entity),
                entity.getVarianteLabel(),
                entity.getViewCount(),
                entity.getDownloadCount(),
                entity.getShareCount());

        cv.changePersonalInfo(PersonalInfoPersistenceMapper.toDomain(entity.getPersonalInfo()));

        entity.getExperiences().forEach(e ->
                cv.addExperience(CvSectionPersistenceMapper.toDomain(e)));
        entity.getEducations().forEach(e ->
                cv.addEducation(CvSectionPersistenceMapper.toDomain(e)));
        entity.getSkills().forEach(s ->
                cv.addSkill(CvSectionPersistenceMapper.toDomain(s)));
        entity.getLanguages().forEach(l ->
                cv.addLanguage(CvSectionPersistenceMapper.toDomain(l)));
        entity.getCertifications().forEach(c ->
                cv.addCertification(CvSectionPersistenceMapper.toDomain(c)));
        entity.getProjects().forEach(p ->
                cv.addProject(CvSectionPersistenceMapper.toDomain(p)));

        return cv;
    }

    /**
     * Domaine -> JPA : applique les champs modelises du domaine sur l'entite
     * cible. Ne modifie ni {@code publicToken}, ni {@code publicTokenHash}, ni
     * les drapeaux de partage : ces champs sont geres hors du module CV.
     */
    public void applyToEntity(Cv domain, com.cvmobile.model.Cv target) {
        target.setTitre(domain.getTitre());
        target.setViewCount(domain.getViewCount());
        target.setDownloadCount(domain.getDownloadCount());
        target.setShareCount(domain.getShareCount());
        target.setVarianteLabel(domain.getVarianteLabel());

        CvStyle style = domain.getStyle();
        target.setStyleTemplateId(style.templateId());
        target.setStylePrimaryColor(style.primaryColor());
        target.setStyleFontFamily(style.fontFamily());

        target.setPersonalInfo(PersonalInfoPersistenceMapper.toEntity(domain.getPersonalInfo()));

        applyCollections(domain, target);
    }

    private void applyCollections(Cv domain, com.cvmobile.model.Cv target) {
        target.getExperiences().clear();
        domain.getExperiences().forEach(e ->
                target.addExperience(CvSectionPersistenceMapper.toEntity(e)));

        target.getEducations().clear();
        domain.getEducations().forEach(e ->
                target.addEducation(CvSectionPersistenceMapper.toEntity(e)));

        target.getSkills().clear();
        domain.getSkills().forEach(s ->
                target.addSkill(CvSectionPersistenceMapper.toEntity(s)));

        target.getLanguages().clear();
        domain.getLanguages().forEach(l ->
                target.addLanguage(CvSectionPersistenceMapper.toEntity(l)));

        target.getCertifications().clear();
        domain.getCertifications().forEach(c ->
                target.addCertification(CvSectionPersistenceMapper.toEntity(c)));

        target.getProjects().clear();
        domain.getProjects().forEach(p ->
                target.addProject(CvSectionPersistenceMapper.toEntity(p)));
    }

    private static long ownerIdOf(com.cvmobile.model.Cv entity) {
        if (entity.getUser() == null || entity.getUser().getId() == null) {
            throw new IllegalStateException(
                    "CV " + entity.getId() + " sans proprietaire : etat persistant invalide.");
        }
        return entity.getUser().getId();
    }

    private static Long parentIdOf(com.cvmobile.model.Cv entity) {
        return entity.getParent() == null ? null : entity.getParent().getId();
    }
}
