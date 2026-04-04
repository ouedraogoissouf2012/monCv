package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class JobMatchRequest {
    @NotNull
    private Long cvId;

    @NotBlank(message = "Le texte de l'offre est obligatoire")
    private String jobDescription;
}
