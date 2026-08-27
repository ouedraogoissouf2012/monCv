package com.cvmobile.service.import_;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cvmobile.dto.CvRequest;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;

class ImportedCvRequestValidatorTest {

    private final ImportedCvRequestValidator validator =
            new ImportedCvRequestValidator(Validation.buildDefaultValidatorFactory().getValidator());

    @Test
    void refuseUnTitreVideCommeLeCrud() {
        CvRequest imported = CvRequest.builder().titre("").build();
        assertThatThrownBy(() -> validator.requireValid(imported))
                .isInstanceOf(ConstraintViolationException.class);
    }

    @Test
    void accepteUnTitreValide() {
        CvRequest imported = CvRequest.builder().titre("CV Awa").build();
        assertThatCode(() -> validator.requireValid(imported)).doesNotThrowAnyException();
    }
}
