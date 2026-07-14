package com.cvmobile.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ApplicationMessagesRequest {

    @NotNull
    private Long cvId;

    @NotBlank(message = "Le texte de l'offre est obligatoire")
    @Size(min = 20, max = 20000, message = "Le texte de l'offre doit contenir entre 20 et 20000 caracteres")
    private String jobDescription;

    @Pattern(
            regexp = "SIMPLE|PROFESSIONAL|DIRECT|JUNIOR|SENIOR",
            message = "Le ton doit etre SIMPLE, PROFESSIONAL, DIRECT, JUNIOR ou SENIOR")
    private String tone = "PROFESSIONAL";

    @AssertTrue(message = "Le consentement IA est obligatoire avant d'envoyer un CV a l'IA")
    private boolean aiConsentAccepted;
}
