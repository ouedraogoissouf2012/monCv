package com.cvmobile.mapper;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import com.cvmobile.dto.PublicCvResponse;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.User;
import com.cvmobile.security.PublicContentSanitizer;
import com.cvmobile.security.PublicUrlPolicy;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;

import java.time.Duration;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PublicCvMapperTest {
    private final PublicCvMapper mapper = new PublicCvMapper(
            Mappers.getMapper(CvMapper.class),
            new PublicUrlPolicy(properties()),
            new PublicContentSanitizer());

    @Test
    void exposesOnlyWhitelistedFieldsAndRedactsPrivateContact() throws Exception {
        Cv cv = cv(false, "https://tracker.example/pixel.jpg");
        cv.addEducation(Education.builder().id(99L).etablissement("Universite")
                .diplome("Master").dateDebut(LocalDate.of(2020, 1, 1)).build());

        PublicCvResponse response = mapper.toResponse(cv);
        JsonNode json = new ObjectMapper().registerModule(new JavaTimeModule())
                .valueToTree(response);

        assertThat(response.personalInfo().email()).isNull();
        assertThat(response.personalInfo().telephone()).isNull();
        assertThat(response.personalInfo().photoUrl()).isNull();
        assertThat(response.personalInfo().linkedIn()).isNull();
        assertThat(response.style().templateId()).isEqualTo("moderne");
        assertThat(response.style().fontFamily()).isEqualTo("Roboto");
        assertThat(json.has("id")).isFalse();
        assertThat(json.has("createdAt")).isFalse();
        assertThat(json.has("updatedAt")).isFalse();
        assertThat(json.has("publicToken")).isFalse();
        assertThat(json.path("educations").get(0).has("id")).isFalse();
        assertThat(json.path("personalInfo").has("adresse")).isFalse();
        assertThat(json.path("personalInfo").has("codePostal")).isFalse();
    }

    @Test
    void keepsExplicitContactAndApprovedBackendMediaOnly() {
        String photo = "http://localhost:8082/api/uploads/photos/"
                + "123e4567-e89b-12d3-a456-426614174000.jpg";
        PublicCvResponse response = mapper.toResponse(cv(true, photo));

        assertThat(response.personalInfo().email()).isEqualTo("candidate@example.com");
        assertThat(response.personalInfo().telephone()).isEqualTo("+22501020304");
        assertThat(response.personalInfo().photoUrl()).isEqualTo(photo);
        assertThat(response.personalInfo().portfolio()).isEqualTo("https://example.com/cv");
    }

    @Test
    void boundsLegacyContentAndIgnoresNullCollectionEntries() {
        Cv cv = cv(true, null);
        cv.setTitre("CV\u0000" + "x".repeat(250));
        for (int index = 0; index < 55; index++) {
            cv.addEducation(Education.builder().etablissement("Ecole " + index)
                    .diplome("Diplome").dateDebut(LocalDate.of(2020, 1, 1)).build());
        }
        cv.getEducations().add(null);

        PublicCvResponse response = mapper.toResponse(cv);

        assertThat(response.titre()).doesNotContain("\u0000").hasSize(200);
        assertThat(response.educations()).hasSize(50).doesNotContainNull();
    }

    @Test
    void appliesTheSameUrlAndPrivacyPolicyToDocxModels() {
        Cv cv = cv(false, "https://tracker.example/pixel.jpg");
        cv.addProject(Project.builder().nom("Projet")
                .lien("javascript:alert(1)").build());

        Cv document = mapper.toDocumentModel(cv);

        assertThat(document.getPersonalInfo().getAdresse()).isNull();
        assertThat(document.getPersonalInfo().getEmail()).isNull();
        assertThat(document.getPersonalInfo().getPhotoUrl()).isNull();
        assertThat(document.getProjects().getFirst().getLien()).isNull();
    }

    private Cv cv(boolean contactEnabled, String photoUrl) {
        return Cv.builder()
                .id(12L)
                .titre("CV Produit")
                .user(User.builder().id(4L).build())
                .publicContactEnabled(contactEnabled)
                .publicDownloadsEnabled(contactEnabled)
                .styleTemplateId("../../unknown")
                .styleFontFamily("Untrusted Remote Font")
                .personalInfo(PersonalInfo.builder()
                        .nom("Kone").prenom("Awa")
                        .email("candidate@example.com")
                        .telephone("+22501020304")
                        .adresse("Rue privee").codePostal("00225")
                        .ville("Abidjan").pays("Cote d'Ivoire")
                        .photoUrl(photoUrl)
                        .linkedIn("javascript:alert(1)")
                        .portfolio("https://example.com/cv")
                        .build())
                .build();
    }

    private PublicPortfolioSecurityProperties properties() {
        return new PublicPortfolioSecurityProperties(
                "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=",
                Duration.ofMinutes(5), 2, Duration.ofMillis(100),
                10 * 1024 * 1024, List.of("http://localhost:8082"));
    }
}
