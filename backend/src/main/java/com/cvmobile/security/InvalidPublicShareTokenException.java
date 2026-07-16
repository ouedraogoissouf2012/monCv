package com.cvmobile.security;

import com.cvmobile.exception.ResourceNotFoundException;

public final class InvalidPublicShareTokenException extends ResourceNotFoundException {
    public InvalidPublicShareTokenException() {
        super("Lien de partage invalide ou expire");
    }
}
