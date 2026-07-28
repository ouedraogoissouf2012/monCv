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

    /**
     * Remplace les sections de l'entite en n'honorant un identifiant fourni que
     * s'il correspond deja a un enfant du <em>meme</em> CV. Un identifiant
     * inconnu (etranger ou absent) est traite comme une insertion : ceci empeche
     * un utilisateur de reparentaliser ou d'ecraser la ligne d'un autre CV en
     * injectant son identifiant (protection contre l'IDOR au niveau section).
     */
    private void applyCollections(Cv domain, com.cvmobile.model.Cv target) {
        replaceSection(target.getExperiences(), domain.getExperiences(),
                com.cvmobile.model.Experience::getId,
                CvSectionPersistenceMapper::toEntity, target::addExperience);
        replaceSection(target.getEducations(), domain.getEducations(),
                com.cvmobile.model.Education::getId,
                CvSectionPersistenceMapper::toEntity, target::addEducation);
        replaceSection(target.getSkills(), domain.getSkills(),
                com.cvmobile.model.Skill::getId,
                CvSectionPersistenceMapper::toEntity, target::addSkill);
        replaceSection(target.getLanguages(), domain.getLanguages(),
                com.cvmobile.model.Language::getId,
                CvSectionPersistenceMapper::toEntity, target::addLanguage);
        replaceSection(target.getCertifications(), domain.getCertifications(),
                com.cvmobile.model.Certification::getId,
                CvSectionPersistenceMapper::toEntity, target::addCertification);
        replaceSection(target.getProjects(), domain.getProjects(),
                com.cvmobile.model.Project::getId,
                CvSectionPersistenceMapper::toEntity, target::addProject);
    }

    /**
     * Reconstruit une collection de sections : collecte d'abord les identifiants
     * reellement possedes par le CV, vide la collection (orphanRemoval supprime
     * les absents), puis re-ajoute chaque valeur du domaine — en conservant son
     * identifiant seulement s'il etait possede, sinon en l'inserant (id neuf).
     *
     * @param existing    collection d'entites enfants actuellement rattachees
     * @param domainItems valeurs de domaine cibles
     * @param entityId    extrait l'identifiant d'une entite enfant
     * @param toEntity    convertit une valeur de domaine en entite enfant
     * @param attach      rattache l'entite au CV (pose la back-reference)
     */
    private static <D, E> void replaceSection(
            java.util.List<E> existing,
            java.util.List<D> domainItems,
            java.util.function.Function<E, Long> entityId,
            java.util.function.Function<D, E> toEntity,
            java.util.function.Consumer<E> attach) {
        java.util.Set<Long> ownedIds = existing.stream()
                .map(entityId)
                .filter(java.util.Objects::nonNull)
                .collect(java.util.stream.Collectors.toSet());

        existing.clear();
        for (D item : domainItems) {
            E entity = toEntity.apply(item);
            if (entityId.apply(entity) != null && !ownedIds.contains(entityId.apply(entity))) {
                // Identifiant non possede : forcer une insertion, jamais un
                // update par cle primaire sur la ligne d'autrui.
                CvSectionPersistenceMapper.stripId(entity);
            }
            attach.accept(entity);
        }
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
