package com.cvmobile.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Levee quand un utilisateur tente de s'inscrire avec un email deja utilise.
 */
@ResponseStatus(HttpStatus.CONFLICT)
public class DuplicateEmailException extends RuntimeException {

    private final String email;

    public DuplicateEmailException(String email) {
        super("Cet email est deja utilise : " + email);
        this.email = email;
    }

    public String getEmail() { return email; }
}
