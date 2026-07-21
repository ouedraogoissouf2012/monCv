package com.cvmobile.service.auth;

import com.cvmobile.exception.GoogleAuthException;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GoogleIdentityVerifierImplTest {
    @Mock GoogleIdTokenVerifier verifier;
    @Mock GoogleIdToken token;

    @Test
    void rejectsAuthenticationWhenGoogleIsNotConfigured() {
        GoogleIdentityVerifierImpl service = new GoogleIdentityVerifierImpl(" ");

        assertCode(service, "credential", "GOOGLE_AUTH_UNAVAILABLE");
    }

    @Test
    void buildsTheSdkVerifierWhenGoogleIsConfigured() {
        assertThatCode(() -> new GoogleIdentityVerifierImpl("client-id"))
                .doesNotThrowAnyException();
    }

    @Test
    void rejectsUnknownAndMalformedTokensWithTheSameContract() throws Exception {
        GoogleIdentityVerifierImpl service = service();
        when(verifier.verify("unknown")).thenReturn(null);
        when(verifier.verify("malformed")).thenThrow(new IOException("invalid token"));

        assertCode(service, "unknown", "GOOGLE_TOKEN_INVALID");
        assertCode(service, "malformed", "GOOGLE_TOKEN_INVALID");
    }

    @Test
    void rejectsUnverifiedOrIncompleteIdentities() throws Exception {
        GoogleIdentityVerifierImpl service = service();
        when(verifier.verify("credential")).thenReturn(token);

        assertInvalidPayload(service, payload(false, "subject", "user@example.com"));
        assertInvalidPayload(service, payload(true, null, "user@example.com"));
        assertInvalidPayload(service, payload(true, "subject", null));
    }

    @Test
    void mapsVerifiedIdentityClaims() throws Exception {
        GoogleIdentityVerifierImpl service = service();
        GoogleIdToken.Payload payload = payload(true, "google-123", "user@example.com");
        payload.set("given_name", "Ada");
        payload.set("family_name", "Lovelace");
        payload.set("picture", "https://images.example.test/ada.png");
        when(verifier.verify("credential")).thenReturn(token);
        when(token.getPayload()).thenReturn(payload);

        GoogleIdentity identity = service.verify("credential");

        assertThat(identity).isEqualTo(new GoogleIdentity(
                "google-123", "user@example.com", true,
                "Ada", "Lovelace", "https://images.example.test/ada.png"));
    }

    private GoogleIdentityVerifierImpl service() {
        return new GoogleIdentityVerifierImpl("client-id", verifier);
    }

    private void assertInvalidPayload(
            GoogleIdentityVerifierImpl service, GoogleIdToken.Payload payload) throws Exception {
        when(token.getPayload()).thenReturn(payload);
        assertCode(service, "credential", "GOOGLE_TOKEN_INVALID");
    }

    private GoogleIdToken.Payload payload(boolean verified, String subject, String email) {
        return new GoogleIdToken.Payload()
                .setEmailVerified(verified)
                .setSubject(subject)
                .setEmail(email);
    }

    private void assertCode(
            GoogleIdentityVerifierImpl service, String credential, String expectedCode) {
        assertThatThrownBy(() -> service.verify(credential))
                .isInstanceOf(GoogleAuthException.class)
                .extracting(error -> ((GoogleAuthException) error).getCode())
                .isEqualTo(expectedCode);
    }
}
