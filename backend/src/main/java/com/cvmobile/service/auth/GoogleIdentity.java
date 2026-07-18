package com.cvmobile.service.auth;

public record GoogleIdentity(
        String subject,
        String email,
        boolean emailVerified,
        String givenName,
        String familyName,
        String pictureUrl) {
}
