package com.cvmobile.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Mise a jour partielle du profil : seuls les champs non-null sont appliques.
 * Remplace un {@code Map<String,String>} non type (mass-assignment) par un
 * contrat type, valide et borne.
 */
@Data
public class UpdateProfileRequest {

    @Size(max = 100, message = "Le nom ne doit pas depasser 100 caracteres")
    private String nom;

    @Size(max = 100, message = "Le prenom ne doit pas depasser 100 caracteres")
    private String prenom;
}
