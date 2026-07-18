package com.cvmobile.mapper;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicCvResponse;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.security.PublicContentSanitizer;
import com.cvmobile.security.PublicUrlPolicy;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;

import static com.cvmobile.dto.CvValidationLimits.*;

@Component
@RequiredArgsConstructor
public final class PublicCvMapper {
    private static final Set<String> TEMPLATES = Set.of(
            "moderne", "classique", "minimaliste", "creatif", "executive", "ats");
    private static final Set<String> FONTS = Set.of(
            "Roboto", "Open Sans", "Lato", "Montserrat", "Raleway",
            "Source Sans Pro", "Nunito", "Merriweather", "Poppins");

    private final CvMapper cvMapper;
    private final PublicUrlPolicy urlPolicy;
    private final PublicContentSanitizer contentSanitizer;

    public PublicCvResponse toResponse(Cv cv) {
        return toResponse(cv, null);
    }

    public PublicCvResponse toResponse(Cv cv, String publicPhotoUrl) {
        CvResponse source = cvMapper.toResponse(cv);
        return new PublicCvResponse(
                text(source.getTitre(), MAX_MEDIUM_TEXT_LENGTH),
                personalInfo(source.getPersonalInfo(), cv.isPublicContactEnabled(), publicPhotoUrl),
                map(source.getEducations(), MAX_SECTION_ITEMS, this::education),
                map(source.getExperiences(), MAX_SECTION_ITEMS, this::experience),
                map(source.getSkills(), MAX_SKILLS, this::skill),
                map(source.getLanguages(), MAX_SECTION_ITEMS, this::language),
                map(source.getCertifications(), MAX_SECTION_ITEMS, this::certification),
                map(source.getProjects(), MAX_SECTION_ITEMS, this::project),
                style(source.getStyle()),
                cv.isPublicDownloadsEnabled(),
                cv.isPublicContactEnabled());
    }

    public CvResponse toDocumentResponse(Cv cv) {
        PublicCvResponse source = toResponse(cv);
        return CvResponse.builder()
                .titre(source.titre())
                .personalInfo(documentPersonalInfo(source.personalInfo()))
                .educations(map(source.educations(), this::documentEducation))
                .experiences(map(source.experiences(), this::documentExperience))
                .skills(map(source.skills(), this::documentSkill))
                .languages(map(source.languages(), this::documentLanguage))
                .certifications(map(source.certifications(), this::documentCertification))
                .projects(map(source.projects(), this::documentProject))
                .style(documentStyle(source.style()))
                .publicDownloadsEnabled(source.publicDownloadsEnabled())
                .publicContactEnabled(source.publicContactEnabled())
                .build();
    }

    public Cv toDocumentModel(Cv cv) {
        PublicCvResponse source = toResponse(cv);
        return Cv.builder()
                .id(cv.getId()).titre(source.titre())
                .personalInfo(modelPersonalInfo(source.personalInfo()))
                .educations(map(source.educations(), this::modelEducation))
                .experiences(map(source.experiences(), this::modelExperience))
                .skills(map(source.skills(), this::modelSkill))
                .languages(map(source.languages(), this::modelLanguage))
                .certifications(map(source.certifications(), this::modelCertification))
                .projects(map(source.projects(), this::modelProject))
                .styleTemplateId(source.style().templateId())
                .stylePrimaryColor(source.style().primaryColor())
                .styleFontFamily(source.style().fontFamily())
                .build();
    }

    private PublicCvResponse.PersonalInfo personalInfo(
            CvResponse.PersonalInfoDto value, boolean contactEnabled, String publicPhotoUrl) {
        if (value == null) return null;
        String approvedPhoto = urlPolicy.sanitizeMediaUrl(value.getPhotoUrl());
        return new PublicCvResponse.PersonalInfo(
                text(value.getNom(), MAX_SHORT_TEXT_LENGTH),
                text(value.getPrenom(), MAX_SHORT_TEXT_LENGTH),
                contactEnabled ? text(value.getEmail(), MAX_EMAIL_LENGTH) : null,
                contactEnabled ? text(value.getTelephone(), MAX_PHONE_LENGTH) : null,
                text(value.getVille(), MAX_SHORT_TEXT_LENGTH),
                text(value.getPays(), MAX_SHORT_TEXT_LENGTH),
                approvedPhoto == null ? null
                        : publicPhotoUrl == null ? approvedPhoto : publicPhotoUrl,
                urlPolicy.sanitizeExternalUrl(value.getLinkedIn()),
                urlPolicy.sanitizeExternalUrl(value.getPortfolio()),
                text(value.getTitrePoste(), MAX_MEDIUM_TEXT_LENGTH),
                text(value.getResumeProfessionnel(), MAX_LONG_TEXT_LENGTH));
    }

    private PublicCvResponse.Education education(CvResponse.EducationDto value) {
        return new PublicCvResponse.Education(
                text(value.getEtablissement(), MAX_MEDIUM_TEXT_LENGTH),
                text(value.getDiplome(), MAX_MEDIUM_TEXT_LENGTH),
                text(value.getDomaine(), MAX_MEDIUM_TEXT_LENGTH), value.getDateDebut(),
                value.getDateFin(), text(value.getDescription(), MAX_LONG_TEXT_LENGTH));
    }

    private PublicCvResponse.Experience experience(CvResponse.ExperienceDto value) {
        return new PublicCvResponse.Experience(
                text(value.getEntreprise(), MAX_MEDIUM_TEXT_LENGTH),
                text(value.getPoste(), MAX_MEDIUM_TEXT_LENGTH),
                text(value.getLieu(), MAX_MEDIUM_TEXT_LENGTH), value.getDateDebut(),
                value.getDateFin(), text(value.getDescription(), MAX_LONG_TEXT_LENGTH),
                value.getActuel());
    }

    private PublicCvResponse.Skill skill(CvResponse.SkillDto value) {
        return new PublicCvResponse.Skill(
                text(value.getNom(), MAX_SHORT_TEXT_LENGTH), value.getNiveau(),
                text(value.getCategorie(), MAX_SHORT_TEXT_LENGTH));
    }

    private PublicCvResponse.SpokenLanguage language(CvResponse.LanguageDto value) {
        return new PublicCvResponse.SpokenLanguage(
                text(value.getLangue(), MAX_SHORT_TEXT_LENGTH), value.getNiveau());
    }

    private PublicCvResponse.Certification certification(CvResponse.CertificationDto value) {
        return new PublicCvResponse.Certification(
                text(value.getNom(), MAX_MEDIUM_TEXT_LENGTH),
                text(value.getOrganisme(), MAX_MEDIUM_TEXT_LENGTH), value.getDateObtention(),
                value.getDateExpiration(), urlPolicy.sanitizeExternalUrl(value.getCredentialUrl()));
    }

    private PublicCvResponse.Project project(CvResponse.ProjectDto value) {
        return new PublicCvResponse.Project(
                text(value.getNom(), MAX_MEDIUM_TEXT_LENGTH),
                text(value.getDescription(), MAX_LONG_TEXT_LENGTH),
                text(value.getTechnologies(), MAX_URL_LENGTH),
                urlPolicy.sanitizeExternalUrl(value.getLien()),
                value.getDateDebut(), value.getDateFin());
    }

    private PublicCvResponse.Style style(CvResponse.StyleDto value) {
        String template = value != null && TEMPLATES.contains(value.getTemplateId())
                ? value.getTemplateId() : "moderne";
        String font = value != null && FONTS.contains(value.getFontFamily())
                ? value.getFontFamily() : "Roboto";
        Long color = value == null || value.getPrimaryColor() == null
                || value.getPrimaryColor() < 0 || value.getPrimaryColor() > 4294967295L
                ? 4280648683L : value.getPrimaryColor();
        return new PublicCvResponse.Style(template, color, font);
    }

    private CvResponse.PersonalInfoDto documentPersonalInfo(PublicCvResponse.PersonalInfo value) {
        if (value == null) return null;
        return CvResponse.PersonalInfoDto.builder()
                .nom(value.nom()).prenom(value.prenom()).email(value.email())
                .telephone(value.telephone()).ville(value.ville()).pays(value.pays())
                .photoUrl(value.photoUrl()).linkedIn(value.linkedIn()).portfolio(value.portfolio())
                .titrePoste(value.titrePoste()).resumeProfessionnel(value.resumeProfessionnel())
                .build();
    }

    private CvResponse.EducationDto documentEducation(PublicCvResponse.Education value) {
        return CvResponse.EducationDto.builder().etablissement(value.etablissement())
                .diplome(value.diplome()).domaine(value.domaine())
                .dateDebut(value.dateDebut()).dateFin(value.dateFin())
                .description(value.description()).build();
    }

    private CvResponse.ExperienceDto documentExperience(PublicCvResponse.Experience value) {
        return CvResponse.ExperienceDto.builder().entreprise(value.entreprise())
                .poste(value.poste()).lieu(value.lieu()).dateDebut(value.dateDebut())
                .dateFin(value.dateFin()).description(value.description())
                .actuel(value.actuel()).build();
    }

    private CvResponse.SkillDto documentSkill(PublicCvResponse.Skill value) {
        return CvResponse.SkillDto.builder().nom(value.nom()).niveau(value.niveau())
                .categorie(value.categorie()).build();
    }

    private CvResponse.LanguageDto documentLanguage(PublicCvResponse.SpokenLanguage value) {
        return CvResponse.LanguageDto.builder().langue(value.langue()).niveau(value.niveau()).build();
    }

    private CvResponse.CertificationDto documentCertification(PublicCvResponse.Certification value) {
        return CvResponse.CertificationDto.builder().nom(value.nom()).organisme(value.organisme())
                .dateObtention(value.dateObtention()).dateExpiration(value.dateExpiration())
                .credentialUrl(value.credentialUrl()).build();
    }

    private CvResponse.ProjectDto documentProject(PublicCvResponse.Project value) {
        return CvResponse.ProjectDto.builder().nom(value.nom()).description(value.description())
                .technologies(value.technologies()).lien(value.lien())
                .dateDebut(value.dateDebut()).dateFin(value.dateFin()).build();
    }

    private CvResponse.StyleDto documentStyle(PublicCvResponse.Style value) {
        return CvResponse.StyleDto.builder().templateId(value.templateId())
                .primaryColor(value.primaryColor()).fontFamily(value.fontFamily()).build();
    }

    private PersonalInfo modelPersonalInfo(PublicCvResponse.PersonalInfo value) {
        if (value == null) return null;
        return PersonalInfo.builder().nom(value.nom()).prenom(value.prenom())
                .email(value.email()).telephone(value.telephone()).ville(value.ville())
                .pays(value.pays()).photoUrl(value.photoUrl()).linkedIn(value.linkedIn())
                .portfolio(value.portfolio()).titrePoste(value.titrePoste())
                .resumeProfessionnel(value.resumeProfessionnel()).build();
    }

    private Education modelEducation(PublicCvResponse.Education value) {
        return Education.builder().etablissement(value.etablissement()).diplome(value.diplome())
                .domaine(value.domaine()).dateDebut(value.dateDebut()).dateFin(value.dateFin())
                .description(value.description()).build();
    }

    private Experience modelExperience(PublicCvResponse.Experience value) {
        return Experience.builder().entreprise(value.entreprise()).poste(value.poste())
                .lieu(value.lieu()).dateDebut(value.dateDebut()).dateFin(value.dateFin())
                .description(value.description()).actuel(value.actuel()).build();
    }

    private Skill modelSkill(PublicCvResponse.Skill value) {
        return Skill.builder().nom(value.nom()).niveau(value.niveau())
                .categorie(value.categorie()).build();
    }

    private Language modelLanguage(PublicCvResponse.SpokenLanguage value) {
        return Language.builder().langue(value.langue()).niveau(value.niveau()).build();
    }

    private Certification modelCertification(PublicCvResponse.Certification value) {
        return Certification.builder().nom(value.nom()).organisme(value.organisme())
                .dateObtention(value.dateObtention()).dateExpiration(value.dateExpiration())
                .credentialUrl(value.credentialUrl()).build();
    }

    private Project modelProject(PublicCvResponse.Project value) {
        return Project.builder().nom(value.nom()).description(value.description())
                .technologies(value.technologies()).lien(value.lien())
                .dateDebut(value.dateDebut()).dateFin(value.dateFin()).build();
    }

    private <T, R> List<R> map(List<T> values, Function<T, R> mapper) {
        return map(values, Integer.MAX_VALUE, mapper);
    }

    private <T, R> List<R> map(List<T> values, int limit, Function<T, R> mapper) {
        return values == null ? List.of() : values.stream()
                .filter(Objects::nonNull).limit(limit).map(mapper).toList();
    }

    private String text(String value, int maxCodePoints) {
        return contentSanitizer.text(value, maxCodePoints);
    }
}
