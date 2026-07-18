package com.cvmobile.exception;

public class GoogleAuthException extends RuntimeException {
    private final String code;

    public GoogleAuthException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
