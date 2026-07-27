package com.cvmobile.integration.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Fabrique d'authentification pour les tests d'integration decoupes (#234).
 *
 * <p>Chaque appel a {@link #registerAndLogin} cree un utilisateur unique
 * (email base sur un UUID) puis le connecte, garantissant l'isolation entre
 * suites et methodes — aucun etat statique partage, contrairement a l'ancien
 * {@code CvFlowIntegrationTest} ordonne.
 *
 * <p>Ce helper ne porte aucune assertion metier : il verifie uniquement les
 * codes HTTP techniques necessaires a la production d'un jeton exploitable,
 * conformement au critere de l'issue (helpers sans assertion cachee).
 */
public final class IntegrationAuth {

    /** Mot de passe conforme a la contrainte (6-100 caracteres) du DTO. */
    public static final String PASSWORD = "Test1234!";

    private final MockMvc mvc;
    private final ObjectMapper mapper;

    public IntegrationAuth(MockMvc mvc, ObjectMapper mapper) {
        this.mvc = mvc;
        this.mapper = mapper;
    }

    /**
     * Identite d'un utilisateur de test authentifie : son email et son jeton
     * d'acces Bearer. Immuable.
     */
    public record AuthenticatedUser(String email, String accessToken) {
        /** Valeur prete a l'emploi pour l'en-tete {@code Authorization}. */
        public String bearer() {
            return "Bearer " + accessToken;
        }
    }

    /**
     * Enregistre un nouvel utilisateur unique puis le connecte.
     *
     * @return l'email genere et le jeton d'acces
     * @throws Exception si un appel MockMvc echoue
     */
    public AuthenticatedUser registerAndLogin() throws Exception {
        String email = "flow-" + UUID.randomUUID() + "@integration.test";

        mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", email,
                                "password", PASSWORD,
                                "prenom", "Test",
                                "nom", "Integration"))))
                .andExpect(status().isCreated());

        return new AuthenticatedUser(email, login(email));
    }

    /**
     * Connecte un utilisateur existant et renvoie son jeton d'acces.
     *
     * @param email l'email d'un utilisateur deja enregistre
     * @return le jeton d'acces Bearer
     * @throws Exception si un appel MockMvc echoue
     */
    public String login(String email) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", email,
                                "password", PASSWORD))))
                .andExpect(status().isOk())
                .andReturn();

        Map<?, ?> body = mapper.readValue(
                result.getResponse().getContentAsString(), Map.class);
        return (String) body.get("accessToken");
    }
}
