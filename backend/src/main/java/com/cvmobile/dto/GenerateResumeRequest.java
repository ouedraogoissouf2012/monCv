package com.cvmobile.dto;

import jakarta.validation.constraints.AssertTrue;
import lombok.Data;

@Data
public class GenerateResumeRequest {
    private String titrePoste;
    private String competences;
    private String experience;

    @AssertTrue(message = "Le consentement IA est obligatoire avant d'envoyer des donnees a l'IA")
    private boolean aiConsentAccepted;
}
