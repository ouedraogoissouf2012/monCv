package com.cvmobile.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UpdateProfileRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void rejetteUnNomOuPrenomTropLong() {
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setNom("a".repeat(101));
        request.setPrenom("a".repeat(101));

        var violations = validator.validate(request);

        assertThat(violations).extracting(v -> v.getPropertyPath().toString())
                .contains("nom", "prenom");
    }

    @Test
    void accepteUnProfilPartielValide() {
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setNom("Ouedraogo"); // prenom null -> mise a jour partielle

        assertThat(validator.validate(request)).isEmpty();
    }
}
