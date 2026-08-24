package com.cvmobile.integration;

import com.cvmobile.integration.support.IntegrationAuth;
import com.cvmobile.model.PasswordResetToken;
import com.cvmobile.model.User;
import com.cvmobile.repository.PasswordResetTokenRepository;
import com.cvmobile.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Revocation de session de bout en bout (issue #505), sur Postgres reel : la
 * migration V19, le claim de generation et sa verification sont exerces ensemble.
 *
 * <p>Le scenario de l'issue est celui qu'on refuse : un refresh token vole reste
 * valide 7 jours, la victime « recupere » son compte, et l'attaquant continue a
 * regenerer des access tokens via {@code /api/auth/refresh} (permitAll). Chaque
 * test verifie donc les deux faces — les jetons anterieurs tombent, le compte
 * reste utilisable.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SessionRevocationIntegrationTest extends PostgresIntegrationTest {

    private static final String NOUVEAU_MOT_DE_PASSE = "NouveauMotDePasse1";

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;
    @Autowired private UserRepository users;
    @Autowired private PasswordResetTokenRepository resetTokens;

    /** Jetons d'une session, tels que le client les stocke. */
    private record Session(String email, String accessToken, String refreshToken) {}

    @Test
    void logout_devraitRejeterLesJetonsDeLaSessionFermee() throws Exception {
        Session session = registerAndLogin();

        mvc.perform(post("/api/auth/logout").header("Authorization", "Bearer " + session.accessToken()))
                .andExpect(status().isNoContent());

        // L'access token de la session fermee ne passe plus le filtre...
        mvc.perform(get("/api/cvs").header("Authorization", "Bearer " + session.accessToken()))
                .andExpect(status().isUnauthorized());
        // ...et le refresh ne peut plus rien re-emettre, bien qu'il soit encore
        // signe, non expire et permitAll (le coeur du scenario de l'issue).
        assertRefreshRejected(session.refreshToken());
        // La generation persistee a bien change (0 -> 1).
        assertThat(tokenVersionOf(session.email())).isEqualTo(1);
    }

    @Test
    void logout_devraitLaisserLeCompteUtilisableApresUneNouvelleConnexion() throws Exception {
        Session session = registerAndLogin();

        mvc.perform(post("/api/auth/logout").header("Authorization", "Bearer " + session.accessToken()))
                .andExpect(status().isNoContent());

        // Revoquer n'est pas bloquer : la reconnexion emet des jetons de la
        // nouvelle generation, immediatement exploitables.
        Session reconnexion = login(session.email(), IntegrationAuth.PASSWORD);
        mvc.perform(get("/api/cvs").header("Authorization", "Bearer " + reconnexion.accessToken()))
                .andExpect(status().isOk());
        mvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(
                                Map.of("refreshToken", reconnexion.refreshToken()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());
    }

    @Test
    void logout_sansJeton_devrait401SansRienRevoquer() throws Exception {
        Session session = registerAndLogin();

        mvc.perform(post("/api/auth/logout")).andExpect(status().isUnauthorized());

        // Aucune revocation par un anonyme : la session en cours reste valide.
        assertThat(tokenVersionOf(session.email())).isZero();
        mvc.perform(get("/api/cvs").header("Authorization", "Bearer " + session.accessToken()))
                .andExpect(status().isOk());
    }

    @Test
    void resetPassword_devraitRejeterLesJetonsEmisAvantLaReinitialisation() throws Exception {
        Session volee = registerAndLogin();
        String lien = issueResetToken(volee.email());

        mvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(
                                Map.of("token", lien, "newPassword", NOUVEAU_MOT_DE_PASSE))))
                .andExpect(status().isOk());

        // Le scenario exact de l'issue : le refresh « vole » ne regenere plus rien.
        assertRefreshRejected(volee.refreshToken());
        mvc.perform(get("/api/cvs").header("Authorization", "Bearer " + volee.accessToken()))
                .andExpect(status().isUnauthorized());
        assertThat(tokenVersionOf(volee.email())).isEqualTo(1);

        // La victime reprend bien la main avec son nouveau mot de passe.
        Session recuperee = login(volee.email(), NOUVEAU_MOT_DE_PASSE);
        mvc.perform(get("/api/cvs").header("Authorization", "Bearer " + recuperee.accessToken()))
                .andExpect(status().isOk());
    }

    @Test
    void resetPassword_avecUnJetonInvalide_neRevoqueAucuneSession() throws Exception {
        Session session = registerAndLogin();

        mvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(
                                Map.of("token", "jeton-inconnu", "newPassword", NOUVEAU_MOT_DE_PASSE))))
                .andExpect(status().isBadRequest());

        // Un echec ne doit pas offrir a un tiers un levier de deconnexion gratuit.
        assertThat(tokenVersionOf(session.email())).isZero();
        mvc.perform(get("/api/cvs").header("Authorization", "Bearer " + session.accessToken()))
                .andExpect(status().isOk());
    }

    private void assertRefreshRejected(String refreshToken) throws Exception {
        mvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("refreshToken", refreshToken))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_TOKEN"));
    }

    private int tokenVersionOf(String email) {
        return users.findByEmailIgnoreCase(email).map(User::getTokenVersion).orElseThrow();
    }

    /**
     * Cree un jeton de reinitialisation exploitable et renvoie sa valeur en clair.
     * Le service ne stocke que l'empreinte SHA-256 du jeton et ne transmet le clair
     * que par email : le test doit donc fabriquer le couple lui-meme.
     */
    private String issueResetToken(String email) {
        String rawToken = UUID.randomUUID().toString();
        Long userId = users.findByEmailIgnoreCase(email).orElseThrow().getId();
        resetTokens.save(PasswordResetToken.builder()
                .userId(userId)
                .tokenHash(sha256Hex(rawToken))
                .expiresAt(Instant.now().plus(Duration.ofMinutes(10)))
                .build());
        return rawToken;
    }

    private static String sha256Hex(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 indisponible", exception);
        }
    }

    private Session registerAndLogin() throws Exception {
        String email = "revocation-" + UUID.randomUUID() + "@integration.test";
        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", email,
                                "password", IntegrationAuth.PASSWORD,
                                "prenom", "Test",
                                "nom", "Revocation"))))
                .andExpect(status().isCreated());
        return login(email, IntegrationAuth.PASSWORD);
    }

    private Session login(String email, String password) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(
                                Map.of("email", email, "password", password))))
                .andExpect(status().isOk())
                .andReturn();

        Map<?, ?> body = mapper.readValue(result.getResponse().getContentAsString(), Map.class);
        return new Session(email, (String) body.get("accessToken"), (String) body.get("refreshToken"));
    }
}
