package com.cvmobile.integration;

import com.cvmobile.integration.support.CvFixtures;
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
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Caracterisation de l'activation du partage public d'un CV : la route
 * proprietaire {@code POST /api/cvs/{id}/share} genere un jeton public.
 *
 * <p>Decoupe de l'ancien {@code CvFlowIntegrationTest} ordonne (#234).
 * Complementaire de {@link PublicCvSecurityIntegrationTest} qui couvre la
 * consommation publique du jeton et les en-tetes de securite.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties =
        "jwt.secret=IntegrationTest-B8yR4nM7qW2xK9pL5vT1sD6fH3jU0eA7zC4gN8mQ2rX6kP9wV5b")
class PublicShareFlowIntegrationTest extends PostgresIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;

    private String bearer;

    @BeforeEach
    void authenticate() throws Exception {
        bearer = new IntegrationAuth(mvc, mapper).registerAndLogin().bearer();
    }

    @Test
    void shareCv_devraitGenererUnToken() throws Exception {
        MvcResult created = mvc.perform(post("/api/cvs")
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(CvFixtures.completeCv())))
                .andExpect(status().isCreated())
                .andReturn();
        long cvId = ((Number) mapper.readValue(
                created.getResponse().getContentAsString(), Map.class).get("id")).longValue();

        mvc.perform(post("/api/cvs/" + cvId + "/share")
                        .header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.publicToken").isNotEmpty());
    }
}
