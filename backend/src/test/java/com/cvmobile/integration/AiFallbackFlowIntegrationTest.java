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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Caracterisation du comportement IA sans cle DeepSeek configuree.
 *
 * <p>En profil {@code test}, {@code DEEPSEEK_API_KEY} est vide. L'architecture
 * cible propage {@code AiKeyInvalidException} vers un HTTP 503 + code
 * {@code AI_KEY_INVALID}, sans mode degrade silencieux qui masquerait un
 * probleme de configuration. Decoupe de l'ancien {@code CvFlowIntegrationTest}
 * ordonne (#234).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties =
        "jwt.secret=IntegrationTest-B8yR4nM7qW2xK9pL5vT1sD6fH3jU0eA7zC4gN8mQ2rX6kP9wV5b")
class AiFallbackFlowIntegrationTest extends PostgresIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;

    private String bearer;

    @BeforeEach
    void authenticate() throws Exception {
        bearer = new IntegrationAuth(mvc, mapper).registerAndLogin().bearer();
    }

    @Test
    void generateResume_sansCleDeepSeek_devraitRetourner503() throws Exception {
        mvc.perform(post("/api/ai/generate-resume")
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "titrePoste", "Developpeur Java",
                                "competences", "Java, Spring Boot",
                                "experience", "2 ans",
                                "aiConsentAccepted", true))))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("AI_KEY_INVALID"));
    }
}
