package com.cvmobile.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AiConsentValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void enhanceCv_exigeConsentementIa() {
        EnhanceCvRequest request = new EnhanceCvRequest();
        request.setCvId(42L);
        request.setLevel("MEDIUM");
        request.setAiConsentAccepted(false);

        var violations = validator.validate(request);

        assertThat(violations)
                .anyMatch(v -> v.getMessage().contains("consentement IA"));
    }

    @Test
    void matchJob_accepteQuandConsentementPresent() {
        JobMatchRequest request = new JobMatchRequest();
        request.setCvId(42L);
        request.setJobDescription("Offre detaillee pour un poste de developpeur backend Spring Boot.");
        request.setAiConsentAccepted(true);

        var violations = validator.validate(request);

        assertThat(violations).isEmpty();
    }

    @Test
    void applicationMessages_exigeOffreTonValideEtConsentement() {
        ApplicationMessagesRequest request = new ApplicationMessagesRequest();
        request.setCvId(42L);
        request.setJobDescription("court");
        request.setTone("FANTAISISTE");
        request.setAiConsentAccepted(false);

        var violations = validator.validate(request);

        assertThat(violations).extracting(v -> v.getPropertyPath().toString())
                .contains("jobDescription", "tone", "aiConsentAccepted");
    }
}
