package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record GoogleAuthRequest(
        @NotBlank(message = "Le jeton Google est obligatoire")
        @Size(max = 10000, message = "Le jeton Google est trop long")
        String credential) {
}
