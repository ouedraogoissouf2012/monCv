package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class JobMatchRequest {
    @NotNull
    private Long cvId;

    @NotBlank(message = "Le texte de l'offre est obligatoire")
    @Size(max = 20000, message = "L'offre ne doit pas depasser 20000 caracteres")
    private String jobDescription;

    @AssertTrue(message = "Le consentement IA est obligatoire avant d'envoyer un CV a l'IA")
    private boolean aiConsentAccepted;
}
