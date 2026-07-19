package com.cvmobile.service.auth;

import com.cvmobile.exception.GoogleAuthException;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GoogleIdentityVerifierImpl implements GoogleIdentityVerifier {
    private final String clientId;
    private final GoogleIdTokenVerifier verifier;

    @Autowired
    public GoogleIdentityVerifierImpl(@Value("${google.auth.client-id:}") String clientId) {
        this(clientId, createVerifier(clientId));
    }

    GoogleIdentityVerifierImpl(String clientId, GoogleIdTokenVerifier verifier) {
        this.clientId = clientId;
        this.verifier = verifier;
    }

    @Override
    public GoogleIdentity verify(String credential) {
        if (clientId == null || clientId.isBlank()) {
            throw new GoogleAuthException("GOOGLE_AUTH_UNAVAILABLE", "La connexion Google n'est pas configuree");
        }
        try {
            GoogleIdToken token = verifier.verify(credential);
            if (token == null) throw invalidToken();
            GoogleIdToken.Payload payload = token.getPayload();
            boolean verified = Boolean.TRUE.equals(payload.getEmailVerified());
            if (!verified || payload.getSubject() == null || payload.getEmail() == null) throw invalidToken();
            return new GoogleIdentity(
                    payload.getSubject(), payload.getEmail(), true,
                    (String) payload.get("given_name"), (String) payload.get("family_name"),
                    (String) payload.get("picture"));
        } catch (GoogleAuthException exception) {
            throw exception;
        } catch (Exception exception) {
            throw invalidToken();
        }
    }

    private GoogleAuthException invalidToken() {
        return new GoogleAuthException("GOOGLE_TOKEN_INVALID", "Le jeton Google est invalide ou expire");
    }

    private static GoogleIdTokenVerifier createVerifier(String clientId) {
        if (clientId == null || clientId.isBlank()) return null;
        return new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(List.of(clientId))
                .build();
    }
}
