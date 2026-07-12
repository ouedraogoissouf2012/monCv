package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.AssertTrue;
import lombok.Data;

@Data
public class JobMatchRequest {
    @NotNull
    private Long cvId;

    @NotBlank(message = "Le texte de l'offre est obligatoire")
    private String jobDescription;

    @AssertTrue(message = "Le consentement IA est obligatoire avant d'envoyer un CV a l'IA")
    private boolean aiConsentAccepted;
}
