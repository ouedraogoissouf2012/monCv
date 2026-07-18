package com.cvmobile.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

import static com.cvmobile.dto.CvValidationLimits.MAX_SECTION_ITEMS;
import static org.assertj.core.api.Assertions.assertThat;

class CvRequestValidationTest {
    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void rejectsOversizedCollectionsAndLongNestedContent() {
        CvRequest.EducationDto education = CvRequest.EducationDto.builder()
                .etablissement("Universite")
                .diplome("Master")
                .dateDebut(LocalDate.of(2020, 1, 1))
                .description("x".repeat(CvValidationLimits.MAX_LONG_TEXT_LENGTH + 1))
                .build();
        CvRequest request = CvRequest.builder()
                .titre("CV")
                .educations(Collections.nCopies(MAX_SECTION_ITEMS + 1, education))
                .build();

        Set<String> paths = validator.validate(request).stream()
                .map(violation -> violation.getPropertyPath().toString())
                .collect(java.util.stream.Collectors.toSet());

        assertThat(paths).contains("educations", "educations[0].description");
    }

    @Test
    void rejectsNullElementsBeforeTheyReachMappingCode() {
        List<CvRequest.ProjectDto> projects = new ArrayList<>();
        projects.add(null);
        CvRequest request = CvRequest.builder().titre("CV").projects(projects).build();

        assertThat(validator.validate(request))
                .extracting(violation -> violation.getPropertyPath().toString())
                .containsExactly("projects[0].<list element>");
    }
}
