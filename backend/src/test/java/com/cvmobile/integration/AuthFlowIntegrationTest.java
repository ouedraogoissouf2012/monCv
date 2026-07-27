package com.cvmobile.integration;

import com.cvmobile.integration.support.IntegrationAuth;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Caracterisation du flow d'authentification : inscription, connexion,
 * rejet des identifiants invalides, protection des routes privees et
 * liveness publique.
 *
 * <p>Decoupe de l'ancien {@code CvFlowIntegrationTest} ordonne (#234).
 * Chaque test est isole : pas d'ordre, pas d'etat statique.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties =
        "jwt.secret=IntegrationTest-B8yR4nM7qW2xK9pL5vT1sD6fH3jU0eA7zC4gN8mQ2rX6kP9wV5b")
class AuthFlowIntegrationTest extends PostgresIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;

    private IntegrationAuth auth;

    @BeforeEach
    void setUpAuth() {
        auth = new IntegrationAuth(mvc, mapper);
    }

    @Test
    void register_devraitCreerUnUtilisateurAvecToken() throws Exception {
        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", "register-" + UUID.randomUUID() + "@integration.test",
                                "password", IntegrationAuth.PASSWORD,
                                "prenom", "Test",
                                "nom", "Integration"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());
    }

    @Test
    void login_devraitRetournerUnToken() throws Exception {
        IntegrationAuth.AuthenticatedUser userAccount = auth.registerAndLogin();

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", userAccount.email(),
                                "password", IntegrationAuth.PASSWORD))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());
    }

    @Test
    void login_mauvaisMotDePasse_devrait401() throws Exception {
        IntegrationAuth.AuthenticatedUser userAccount = auth.registerAndLogin();

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", userAccount.email(),
                                "password", "MauvaisMotDePasse"))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
    }

    @Test
    void getCvs_sansToken_devrait401() throws Exception {
        mvc.perform(get("/api/cvs"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void healthCheck_devraitRetournerUp() throws Exception {
        mvc.perform(get("/actuator/health/liveness"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.components").doesNotExist());
    }
}
