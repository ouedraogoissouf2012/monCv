package com.cvmobile.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Levee lors d'une erreur de generation PDF ou DOCX.
 */
@ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
public class PdfGenerationException extends RuntimeException {

    public PdfGenerationException(String message) {
        super(message);
    }

    public PdfGenerationException(String message, Throwable cause) {
        super(message, cause);
    }
}
