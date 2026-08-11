package com.cvmobile.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class GenerateResumeRequest {
    @Size(max = 200, message = "Le titre ne doit pas depasser 200 caracteres")
    private String titrePoste;

    @Size(max = 5000, message = "Les competences ne doivent pas depasser 5000 caracteres")
    private String competences;

    @Size(max = 5000, message = "L'experience ne doit pas depasser 5000 caracteres")
    private String experience;

    @AssertTrue(message = "Le consentement IA est obligatoire avant d'envoyer des donnees a l'IA")
    private boolean aiConsentAccepted;
}
