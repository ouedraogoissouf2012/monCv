package com.cvmobile.service.import_;

import com.cvmobile.dto.CvRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Validator;
import java.util.Set;
import org.springframework.stereotype.Component;

/**
 * Applique la meme bean-validation que le CRUD avant createCv (issue #510).
 */
@Component
public class ImportedCvRequestValidator {

    private final Validator validator;

    public ImportedCvRequestValidator(Validator validator) {
        this.validator = validator;
    }

    public void requireValid(CvRequest request) {
        Set<ConstraintViolation<CvRequest>> violations = validator.validate(request);
        if (!violations.isEmpty()) {
            throw new ConstraintViolationException(violations);
        }
    }
}
