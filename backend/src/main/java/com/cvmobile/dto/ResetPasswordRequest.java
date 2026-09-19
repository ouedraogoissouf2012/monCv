package com.cvmobile.dto;

import com.cvmobile.validation.StrongPassword;
import jakarta.validation.constraints.NotBlank;

/**
 * Reinitialisation effective (issue #381). Le mot de passe subit la meme
 * validation que l'inscription : toutes deux portent {@link StrongPassword},
 * qui est la definition unique de la politique (issue #511). La regle etait
 * auparavant recopiee ici, ce qui laissait les deux copies diverger.
 */
public record ResetPasswordRequest(
        @NotBlank(message = "Le jeton est obligatoire")
        String token,

        @NotBlank(message = "Le mot de passe est obligatoire")
        @StrongPassword
        String newPassword
) {
}
