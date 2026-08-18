package com.cvmobile.cv.adapter.in.web;

import com.cvmobile.cv.domain.model.Certification;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.CvStyle;
import com.cvmobile.cv.domain.model.Education;
import com.cvmobile.cv.domain.model.Experience;
import com.cvmobile.cv.domain.model.Language;
import com.cvmobile.cv.domain.model.LanguageLevel;
import com.cvmobile.cv.domain.model.PersonalInfo;
import com.cvmobile.cv.domain.model.Project;
import com.cvmobile.cv.domain.model.Skill;
import com.cvmobile.dto.CvRequest;
import org.springframework.stereotype.Component;

/**
 * Convertit une requete web {@link CvRequest} en agregat de domaine {@link Cv}
 * (issue #255, ADR 003). Adaptateur entrant : traduit le format transport vers
 * le modele metier, sans que le domaine connaisse le DTO.
 *
 * <p>Le style partiel est complete par les valeurs par defaut, reproduisant le
 * comportement anterieur. Les identifiants de sections fournis sont preserves,
 * afin que la persistance distingue mises a jour et insertions.
 */
@Component
public class CvWebMapper {

    /** Construit un agregat de domaine a partir de la requete et du proprietaire. */
    public Cv toDomain(CvRequest request, long ownerId) {
        Cv cv = Cv.create(request.getTitre(), ownerId);
        cv.changeStyle(toStyle(request.getStyle()));
        cv.changePersonalInfo(toPersonalInfo(request.getPersonalInfo()));
        addSections(cv, request);
        return cv;
    }

    private void addSections(Cv cv, CvRequest request) {
        if (request.getExperiences() != null) {
            request.getExperiences().forEach(d -> cv.addExperience(toExperience(d)));
        }
        if (request.getEducations() != null) {
            request.getEducations().forEach(d -> cv.addEducation(toEducation(d)));
        }
        if (request.getSkills() != null) {
            request.getSkills().forEach(d -> cv.addSkill(toSkill(d)));
        }
        if (request.getLanguages() != null) {
            request.getLanguages().forEach(d -> cv.addLanguage(toLanguage(d)));
        }
        if (request.getCertifications() != null) {
            request.getCertifications().forEach(d -> cv.addCertification(toCertification(d)));
        }
        if (request.getProjects() != null) {
            request.getProjects().forEach(d -> cv.addProject(toProject(d)));
        }
    }

    private CvStyle toStyle(CvRequest.StyleDto dto) {
        if (dto == null) {
            return CvStyle.defaults();
        }
        CvStyle base = CvStyle.defaults();
        return CvStyle.of(
                dto.getTemplateId() != null ? dto.getTemplateId() : base.templateId(),
                dto.getPrimaryColor() != null ? dto.getPrimaryColor() : base.primaryColor(),
                dto.getFontFamily() != null ? dto.getFontFamily() : base.fontFamily());
    }

    private PersonalInfo toPersonalInfo(CvRequest.PersonalInfoDto d) {
        if (d == null) {
            return null;
        }
        return PersonalInfo.builder()
                .nom(d.getNom()).prenom(d.getPrenom()).email(d.getEmail())
                .telephone(d.getTelephone()).adresse(d.getAdresse()).ville(d.getVille())
                .codePostal(d.getCodePostal()).pays(d.getPays()).photoUrl(d.getPhotoUrl())
                .linkedIn(d.getLinkedIn()).portfolio(d.getPortfolio())
                .titrePoste(d.getTitrePoste()).resumeProfessionnel(d.getResumeProfessionnel())
                .anneeNaissance(d.getAnneeNaissance())
                .situationMatrimoniale(d.getSituationMatrimoniale())
                .sexe(d.getSexe())
                .afficherInfosSensibles(d.getAfficherInfosSensibles())
                .build();
    }

    private Experience toExperience(CvRequest.ExperienceDto d) {
        return Experience.of(d.getId(), d.getEntreprise(), d.getPoste(), d.getLieu(),
                d.getDateDebut(), d.getDateFin(), d.getDescription(), d.getActuel());
    }

    private Education toEducation(CvRequest.EducationDto d) {
        return Education.of(d.getId(), d.getEtablissement(), d.getDiplome(),
                d.getDomaine(), d.getDateDebut(), d.getDateFin(), d.getDescription());
    }

    private Skill toSkill(CvRequest.SkillDto d) {
        return Skill.of(d.getId(), d.getNom(), d.getNiveau(), d.getCategorie());
    }

    private Language toLanguage(CvRequest.LanguageDto d) {
        LanguageLevel level = d.getNiveau() == null
                ? null : LanguageLevel.valueOf(d.getNiveau().name());
        return Language.of(d.getId(), d.getLangue(), level);
    }

    private Certification toCertification(CvRequest.CertificationDto d) {
        return Certification.of(d.getId(), d.getNom(), d.getOrganisme(),
                d.getDateObtention(), d.getDateExpiration(), d.getCredentialUrl());
    }

    private Project toProject(CvRequest.ProjectDto d) {
        return Project.of(d.getId(), d.getNom(), d.getDescription(),
                d.getTechnologies(), d.getLien(), d.getDateDebut(), d.getDateFin());
    }
}
