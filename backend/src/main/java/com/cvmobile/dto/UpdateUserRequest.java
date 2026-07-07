package com.cvmobile.dto;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO pour la mise a jour du profil utilisateur.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateUserRequest {

    @Size(max = 100, message = "Le nom ne doit pas depasser 100 caracteres")
    private String nom;

    @Size(max = 100, message = "Le prenom ne doit pas depasser 100 caracteres")
    private String prenom;
}
