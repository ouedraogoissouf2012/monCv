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

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Caracterisation du CRUD CV authentifie : creation, lecture, liste, mise a
 * jour, duplication, suppression et cas d'erreur (CV inexistant).
 *
 * <p>Decoupe de l'ancien {@code CvFlowIntegrationTest} ordonne (#234).
 * Chaque test recree son propre utilisateur et son propre CV via
 * {@code @BeforeEach} — aucun ordre implicite, aucun etat statique.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties =
        "jwt.secret=IntegrationTest-B8yR4nM7qW2xK9pL5vT1sD6fH3jU0eA7zC4gN8mQ2rX6kP9wV5b")
class CvCrudFlowIntegrationTest extends PostgresIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;

    private String bearer;

    @BeforeEach
    void authenticate() throws Exception {
        bearer = new IntegrationAuth(mvc, mapper).registerAndLogin().bearer();
    }

    /** Cree un CV complet pour l'utilisateur courant et renvoie son id. */
    private long createCvAndReturnId() throws Exception {
        MvcResult result = mvc.perform(post("/api/cvs")
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(CvFixtures.completeCv())))
                .andExpect(status().isCreated())
                .andReturn();

        Map<?, ?> body = mapper.readValue(
                result.getResponse().getContentAsString(), Map.class);
        return ((Number) body.get("id")).longValue();
    }

    @Test
    void createCv_devraitCreerUnCvComplet() throws Exception {
        mvc.perform(post("/api/cvs")
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(CvFixtures.completeCv())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.titre").value("Developpeur Full Stack"))
                .andExpect(jsonPath("$.personalInfo.prenom").value("Test"))
                .andExpect(jsonPath("$.experiences", hasSize(1)))
                .andExpect(jsonPath("$.skills", hasSize(3)))
                .andExpect(jsonPath("$.languages", hasSize(2)))
                .andExpect(jsonPath("$.style.templateId").value("moderne"))
                .andExpect(jsonPath("$.style.primaryColor").value(CvFixtures.COLOR_MODERNE))
                .andExpect(jsonPath("$.style.fontFamily").value("Roboto"));
    }

    @Test
    void getCv_devraitRetournerLeCvCree() throws Exception {
        long cvId = createCvAndReturnId();

        mvc.perform(get("/api/cvs/" + cvId)
                        .header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(cvId))
                .andExpect(jsonPath("$.personalInfo.titrePoste").value("Developpeur Full Stack Java"))
                .andExpect(jsonPath("$.style.templateId").value("moderne"))
                .andExpect(jsonPath("$.style.primaryColor").value(CvFixtures.COLOR_MODERNE))
                .andExpect(jsonPath("$.style.fontFamily").value("Roboto"));
    }

    @Test
    void getAllCvs_devraitRetournerAuMoins1Cv() throws Exception {
        createCvAndReturnId();

        mvc.perform(get("/api/cvs")
                        .header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(1))));
    }

    @Test
    void updateCv_devraitModifierLeTitre() throws Exception {
        long cvId = createCvAndReturnId();

        mvc.perform(put("/api/cvs/" + cvId)
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(CvFixtures.renamedCv())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.titre").value("Senior Developpeur Full Stack"))
                .andExpect(jsonPath("$.style.templateId").value("classique"))
                .andExpect(jsonPath("$.style.primaryColor").value(CvFixtures.COLOR_CLASSIQUE))
                .andExpect(jsonPath("$.style.fontFamily").value("Lato"));
    }

    @Test
    void duplicateCv_devraitCreerUneCopie() throws Exception {
        long cvId = createCvAndReturnId();
        // Renomme d'abord en "Senior ..." pour caracteriser le prefixe "Copie de".
        mvc.perform(put("/api/cvs/" + cvId)
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(CvFixtures.renamedCv())))
                .andExpect(status().isOk());

        mvc.perform(post("/api/cvs/" + cvId + "/duplicate")
                        .header("Authorization", bearer))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.titre").value("Copie de Senior Developpeur Full Stack"))
                .andExpect(jsonPath("$.id").value(not(cvId)))
                .andExpect(jsonPath("$.style.templateId").value("classique"))
                .andExpect(jsonPath("$.style.primaryColor").value(CvFixtures.COLOR_CLASSIQUE))
                .andExpect(jsonPath("$.style.fontFamily").value("Lato"));
    }

    @Test
    void getCv_inexistant_devrait4xx() throws Exception {
        mvc.perform(get("/api/cvs/99999")
                        .header("Authorization", bearer))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void deleteCv_devraitSupprimerLeCv() throws Exception {
        long cvId = createCvAndReturnId();

        mvc.perform(delete("/api/cvs/" + cvId)
                        .header("Authorization", bearer))
                .andExpect(status().isNoContent());

        mvc.perform(get("/api/cvs/" + cvId)
                        .header("Authorization", bearer))
                .andExpect(status().is4xxClientError());
    }
}
