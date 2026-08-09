package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Reinitialisation effective (issue #381). Le mot de passe subit la meme
 * validation que l'inscription ({@code RegisterRequest}).
 */
public record ResetPasswordRequest(
        @NotBlank(message = "Le jeton est obligatoire")
        String token,

        @NotBlank(message = "Le mot de passe est obligatoire")
        @Size(min = 6, max = 100,
                message = "Le mot de passe doit contenir entre 6 et 100 caracteres")
        String newPassword
) {
}
