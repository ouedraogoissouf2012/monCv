package com.cvmobile.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.TOO_MANY_REQUESTS)
public class RateLimitException extends RuntimeException {
    public RateLimitException() {
        super("Trop de tentatives. Veuillez reessayer dans quelques minutes.");
    }

    public RateLimitException(String message) {
        super(message);
    }
}
