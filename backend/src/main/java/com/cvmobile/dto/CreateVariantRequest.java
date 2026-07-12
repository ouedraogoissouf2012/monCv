package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Requete pour creer une variante d'un CV adaptee a une offre d'emploi.
 * Le jobDescription est envoye a l'IA pour adapter le contenu.
 * Le label est optionnel — extrait automatiquement par l'IA si absent.
 */
@Data
public class CreateVariantRequest {

    @NotBlank(message = "Le texte de l'offre est obligatoire")
    private String jobDescription;

    @Size(max = 200, message = "Le label ne doit pas depasser 200 caracteres")
    private String label;
}
