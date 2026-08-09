package com.cvmobile.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Demande de reinitialisation de mot de passe (issue #381). */
public record ForgotPasswordRequest(
        @NotBlank(message = "L'email est obligatoire")
        @Email(message = "Format d'email invalide")
        @Size(max = 255, message = "L'email ne doit pas depasser 255 caracteres")
        String email
) {
}
