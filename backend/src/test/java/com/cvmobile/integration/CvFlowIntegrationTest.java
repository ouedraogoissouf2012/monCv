package com.cvmobile.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Test d'integration complet du flow CV :
 * Register → Login → Create CV → Get CV → Enhance IA → Share → Duplicate → Delete
 *
 * Utilise H2 en memoire (profil test), pas besoin de PostgreSQL.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class CvFlowIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;

    private static String accessToken;
    private static Long cvId;

    // ── 1. INSCRIPTION ──────────────────────────────────────────

    @Test
    @Order(1)
    void register_devraitCreerUnUtilisateur() throws Exception {
        mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                        "email", "test@integration.com",
                        "password", "Test1234!",
                        "prenom", "Test",
                        "nom", "Integration"
                ))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());
    }

    // ── 2. CONNEXION ────────────────────────────────────────────

    @Test
    @Order(2)
    void login_devraitRetournerUnToken() throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                        "email", "test@integration.com",
                        "password", "Test1234!"
                ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andReturn();

        Map<String, Object> body = mapper.readValue(
                result.getResponse().getContentAsString(), Map.class);
        accessToken = (String) body.get("accessToken");
    }

    // ── 3. LOGIN ECHOUE ─────────────────────────────────────────

    @Test
    @Order(3)
    void login_mauvaisMotDePasse_devrait401() throws Exception {
        mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                        "email", "test@integration.com",
                        "password", "MauvaisMotDePasse"
                ))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
    }

    // ── 4. CREATION CV COMPLET ──────────────────────────────────

    @Test
    @Order(4)
    void createCv_devraitCreerUnCvComplet() throws Exception {
        String cvJson = mapper.writeValueAsString(Map.of(
                "titre", "Developpeur Full Stack",
                "personalInfo", Map.of(
                        "prenom", "Test",
                        "nom", "Integration",
                        "email", "test@integration.com",
                        "telephone", "+225 0700000000",
                        "ville", "Abidjan",
                        "pays", "Cote d'Ivoire",
                        "titrePoste", "Developpeur Full Stack Java",
                        "resumeProfessionnel", "Developpeur avec 3 ans d'experience"
                ),
                "experiences", java.util.List.of(Map.of(
                        "poste", "Developpeur Web",
                        "entreprise", "TechCorp",
                        "lieu", "Abidjan",
                        "dateDebut", "2023-01-01",
                        "dateFin", "2025-12-31",
                        "description", "- Developpement applications web\n- Collaboration equipe agile",
                        "actuel", false
                )),
                "educations", java.util.List.of(Map.of(
                        "diplome", "Licence Informatique",
                        "etablissement", "Universite Test",
                        "dateDebut", "2019-10-01",
                        "dateFin", "2022-07-01",
                        "description", "Informatique"
                )),
                "skills", java.util.List.of(
                        Map.of("nom", "Java", "niveau", 4),
                        Map.of("nom", "Angular", "niveau", 3),
                        Map.of("nom", "Spring Boot", "niveau", 4)
                ),
                "languages", java.util.List.of(
                        Map.of("nom", "Francais", "langue", "Francais", "niveau", "C2"),
                        Map.of("nom", "Anglais", "langue", "Anglais", "niveau", "B1")
                )
        ));

        MvcResult result = mvc.perform(post("/api/cvs")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(cvJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.titre").value("Developpeur Full Stack"))
                .andExpect(jsonPath("$.personalInfo.prenom").value("Test"))
                .andExpect(jsonPath("$.experiences", hasSize(1)))
                .andExpect(jsonPath("$.skills", hasSize(3)))
                .andExpect(jsonPath("$.languages", hasSize(2)))
                .andReturn();

        Map<String, Object> body = mapper.readValue(
                result.getResponse().getContentAsString(), Map.class);
        cvId = ((Number) body.get("id")).longValue();
    }

    // ── 5. LECTURE CV ────────────────────────────────────────────

    @Test
    @Order(5)
    void getCv_devraitRetournerLeCvCree() throws Exception {
        mvc.perform(get("/api/cvs/" + cvId)
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(cvId))
                .andExpect(jsonPath("$.personalInfo.titrePoste").value("Developpeur Full Stack Java"));
    }

    // ── 6. LISTE DES CVS ────────────────────────────────────────

    @Test
    @Order(6)
    void getAllCvs_devraitRetournerAuMoins1Cv() throws Exception {
        mvc.perform(get("/api/cvs")
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(1))));
    }

    // ── 7. MISE A JOUR CV ───────────────────────────────────────

    @Test
    @Order(7)
    void updateCv_devraitModifierLeTitre() throws Exception {
        String updateJson = mapper.writeValueAsString(Map.of(
                "titre", "Senior Developpeur Full Stack",
                "personalInfo", Map.of(
                        "prenom", "Test",
                        "nom", "Integration",
                        "email", "test@integration.com",
                        "titrePoste", "Senior Developpeur Full Stack"
                ),
                "experiences", java.util.List.of(),
                "educations", java.util.List.of(),
                "skills", java.util.List.of(),
                "languages", java.util.List.of()
        ));

        mvc.perform(put("/api/cvs/" + cvId)
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.titre").value("Senior Developpeur Full Stack"));
    }

    // ── 8. DUPLICATION CV ───────────────────────────────────────

    @Test
    @Order(8)
    void duplicateCv_devraitCreerUneCopie() throws Exception {
        mvc.perform(post("/api/cvs/" + cvId + "/duplicate")
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.titre").value("Copie de Senior Developpeur Full Stack"))
                .andExpect(jsonPath("$.id").value(not(cvId)));
    }

    // ── 9. PARTAGE PUBLIC ───────────────────────────────────────

    @Test
    @Order(9)
    void shareCv_devraitGenererUnToken() throws Exception {
        mvc.perform(post("/api/cvs/" + cvId + "/share")
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.publicToken").isNotEmpty());
    }

    // ── 10. ACCES SANS TOKEN = 403 ──────────────────────────────

    @Test
    @Order(10)
    void getCv_sansToken_devrait403() throws Exception {
        mvc.perform(get("/api/cvs"))
                .andExpect(status().isUnauthorized());
    }

    // ── 11. CV INEXISTANT = 404 ─────────────────────────────────

    @Test
    @Order(11)
    void getCv_inexistant_devrait404OuBadRequest() throws Exception {
        mvc.perform(get("/api/cvs/99999")
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().is4xxClientError());
    }

    // ── 12. SUPPRESSION CV ──────────────────────────────────────

    @Test
    @Order(12)
    void deleteCv_devraitSupprimerLeCv() throws Exception {
        mvc.perform(delete("/api/cvs/" + cvId)
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isNoContent());

        // Verifier qu'il n'existe plus
        mvc.perform(get("/api/cvs/" + cvId)
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().is4xxClientError());
    }

    // ── 13. IA GENERATE RESUME ──────────────────────────────────

    @Test
    @Order(13)
    void generateResume_devraitRetournerUnTexte() throws Exception {
        mvc.perform(post("/api/ai/generate-resume")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                        "titrePoste", "Developpeur Java",
                        "competences", "Java, Spring Boot",
                        "experience", "2 ans"
                ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resume").isNotEmpty());
    }

    // ── 14. HEALTH CHECK ────────────────────────────────────────

    @Test
    @Order(14)
    void healthCheck_devraitRetournerUp() throws Exception {
        mvc.perform(get("/actuator/health"))
                .andExpect(status().isOk());
    }
}
