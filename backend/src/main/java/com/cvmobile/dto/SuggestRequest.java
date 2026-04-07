package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
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
}
