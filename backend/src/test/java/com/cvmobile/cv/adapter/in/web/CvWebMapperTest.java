package com.cvmobile.cv.adapter.in.web;

import static org.assertj.core.api.Assertions.assertThat;

import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.CvStyle;
import com.cvmobile.cv.domain.model.LanguageLevel;
import com.cvmobile.dto.CvRequest;
import com.cvmobile.model.Language;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Conversion de la requete web {@link CvRequest} vers l'agregat de domaine
 * {@link Cv}. Tests purs (sans Spring).
 */
@DisplayName("CvWebMapper (CvRequest -> domaine)")
class CvWebMapperTest {

    private static final long OWNER = 7L;

    private final CvWebMapper mapper = new CvWebMapper();

    private CvRequest fullRequest() {
        return CvRequest.builder()
                .titre("Mon CV")
                .personalInfo(CvRequest.PersonalInfoDto.builder()
                        .nom("Traore").prenom("Alex").email("i@x.io")
                        .titrePoste("Dev Backend").build())
                .style(CvRequest.StyleDto.builder()
                        .templateId("classique").primaryColor(99L).fontFamily("Lato").build())
                .experiences(List.of(CvRequest.ExperienceDto.builder()
                        .id(1L).entreprise("ACME").poste("Dev").lieu("Paris")
                        .dateDebut(LocalDate.of(2020, 1, 1)).description("x").actuel(true).build()))
                .educations(List.of(CvRequest.EducationDto.builder()
                        .etablissement("U").diplome("Master").build()))
                .skills(List.of(CvRequest.SkillDto.builder().nom("Java").niveau(5).build()))
                .languages(List.of(CvRequest.LanguageDto.builder()
                        .langue("Anglais").niveau(Language.NiveauLangue.C1).build()))
                .certifications(List.of(CvRequest.CertificationDto.builder().nom("AWS").build()))
                .projects(List.of(CvRequest.ProjectDto.builder().nom("MonCV").build()))
                .build();
    }

    @Test
    @DisplayName("mappe titre, proprietaire, style et personalInfo")
    void mapsScalars() {
        Cv cv = mapper.toDomain(fullRequest(), OWNER);

        assertThat(cv.getTitre()).isEqualTo("Mon CV");
        assertThat(cv.getOwnerId()).isEqualTo(OWNER);
        assertThat(cv.getStyle()).isEqualTo(CvStyle.of("classique", 99L, "Lato"));
        assertThat(cv.getPersonalInfo().nom()).isEqualTo("Traore");
        assertThat(cv.getPersonalInfo().titrePoste()).isEqualTo("Dev Backend");
    }

    @Test
    @DisplayName("mappe toutes les sections en preservant les identifiants fournis")
    void mapsSections() {
        Cv cv = mapper.toDomain(fullRequest(), OWNER);

        assertThat(cv.getExperiences()).singleElement().satisfies(e -> {
            assertThat(e.id()).isEqualTo(1L);
            assertThat(e.entreprise()).isEqualTo("ACME");
            assertThat(e.actuel()).isTrue();
        });
        assertThat(cv.getEducations()).hasSize(1);
        assertThat(cv.getSkills()).singleElement()
                .satisfies(s -> assertThat(s.nom()).isEqualTo("Java"));
        assertThat(cv.getLanguages()).singleElement()
                .satisfies(l -> assertThat(l.niveau()).isEqualTo(LanguageLevel.C1));
        assertThat(cv.getCertifications()).hasSize(1);
        assertThat(cv.getProjects()).hasSize(1);
    }

    @Test
    @DisplayName("style absent -> style par defaut")
    void defaultStyleWhenAbsent() {
        CvRequest req = CvRequest.builder().titre("Sans style").build();

        Cv cv = mapper.toDomain(req, OWNER);

        assertThat(cv.getStyle()).isEqualTo(CvStyle.defaults());
    }

    @Test
    @DisplayName("style partiel -> complete avec les valeurs par defaut")
    void partialStyleFilledWithDefaults() {
        CvRequest req = CvRequest.builder()
                .titre("Style partiel")
                .style(CvRequest.StyleDto.builder().templateId("minimaliste").build())
                .build();

        Cv cv = mapper.toDomain(req, OWNER);

        assertThat(cv.getStyle().templateId()).isEqualTo("minimaliste");
        assertThat(cv.getStyle().primaryColor()).isEqualTo(CvStyle.defaults().primaryColor());
        assertThat(cv.getStyle().fontFamily()).isEqualTo(CvStyle.defaults().fontFamily());
    }

    @Test
    @DisplayName("collections nulles -> agregat sans sections")
    void nullCollectionsYieldEmpty() {
        CvRequest req = CvRequest.builder().titre("Vide").build();

        Cv cv = mapper.toDomain(req, OWNER);

        assertThat(cv.getExperiences()).isEmpty();
        assertThat(cv.getSkills()).isEmpty();
        assertThat(cv.getPersonalInfo()).isNull();
    }
}
