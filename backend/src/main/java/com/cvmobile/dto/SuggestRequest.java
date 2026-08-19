package com.cvmobile.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SuggestRequest {

    @NotBlank(message = "Le poste est obligatoire")
    private String poste;

    private String entreprise;

    private String secteur;

    @Size(max = 5000, message = "La description ne doit pas depasser 5000 caracteres")
    private String description;

    @AssertTrue(message = "Le consentement IA est obligatoire avant d'envoyer des donnees a l'IA")
    private boolean aiConsentAccepted;
}
