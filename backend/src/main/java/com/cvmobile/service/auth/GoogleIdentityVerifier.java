package com.cvmobile.service.auth;

public interface GoogleIdentityVerifier {
    GoogleIdentity verify(String credential);
}
