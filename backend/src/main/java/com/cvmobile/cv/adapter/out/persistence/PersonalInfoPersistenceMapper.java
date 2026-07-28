package com.cvmobile.cv.adapter.out.persistence;

import com.cvmobile.cv.domain.model.PersonalInfo;

/**
 * Conversion des informations personnelles entre le type embarque JPA
 * {@code model.PersonalInfo} et le value object de domaine {@link PersonalInfo}.
 */
final class PersonalInfoPersistenceMapper {

    private PersonalInfoPersistenceMapper() {
    }

    /** JPA -> domaine. Retourne {@code null} si la source est absente. */
    static PersonalInfo toDomain(com.cvmobile.model.PersonalInfo entity) {
        if (entity == null) {
            return null;
        }
        return PersonalInfo.builder()
                .nom(entity.getNom())
                .prenom(entity.getPrenom())
                .email(entity.getEmail())
                .telephone(entity.getTelephone())
                .adresse(entity.getAdresse())
                .ville(entity.getVille())
                .codePostal(entity.getCodePostal())
                .pays(entity.getPays())
                .photoUrl(entity.getPhotoUrl())
                .linkedIn(entity.getLinkedIn())
                .portfolio(entity.getPortfolio())
                .titrePoste(entity.getTitrePoste())
                .resumeProfessionnel(entity.getResumeProfessionnel())
                .build();
    }

    /** Domaine -> JPA. Retourne {@code null} si la source est absente. */
    static com.cvmobile.model.PersonalInfo toEntity(PersonalInfo domain) {
        if (domain == null) {
            return null;
        }
        return com.cvmobile.model.PersonalInfo.builder()
                .nom(domain.nom())
                .prenom(domain.prenom())
                .email(domain.email())
                .telephone(domain.telephone())
                .adresse(domain.adresse())
                .ville(domain.ville())
                .codePostal(domain.codePostal())
                .pays(domain.pays())
                .photoUrl(domain.photoUrl())
                .linkedIn(domain.linkedIn())
                .portfolio(domain.portfolio())
                .titrePoste(domain.titrePoste())
                .resumeProfessionnel(domain.resumeProfessionnel())
                .build();
    }
}
