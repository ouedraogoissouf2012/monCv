package com.cvmobile.integration;

import com.cvmobile.integration.support.CvFixtures;
import com.cvmobile.integration.support.IntegrationAuth;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.HashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat de la mise a jour CV vis-a-vis de l'identite (issue #537).
 *
 * <p>Un PUT remplace la ressource entiere : un corps sans identite est une
 * requete invalide. Auparavant elle produisait une 500 — l'embarque
 * {@code PersonalInfo} null violait la contrainte {@code NOT NULL} de
 * {@code afficher_infos_sensibles} — puis, apres #506, une conservation
 * silencieuse de l'identite courante : semantique PATCH sous un verbe PUT.
 *
 * <p>La contrainte porte le groupe {@link com.cvmobile.validation.OnUpdate}
 * et ne s'applique donc pas a la creation, ou l'absence d'identite reste
 * legitime. Les deux faces sont couvertes ici, la seconde garantissant la
 * non-regression du contrat de creation.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("La mise a jour exige l'identite, la creation ne l'exige pas")
class CvUpdateContractIntegrationTest extends PostgresIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;

    private String bearer;

    @BeforeEach
    void authenticate() throws Exception {
        bearer = new IntegrationAuth(mvc, mapper).registerAndLogin().bearer();
    }

    @Test
    @DisplayName("sans la cle personalInfo : 400 et non 500")
    void putSansLaClePersonalInfoEstRejete() throws Exception {
        long cvId = createCv(CvFixtures.completeCv());

        mvc.perform(put("/api/cvs/" + cvId)
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(sansIdentite())))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("avec personalInfo explicitement null : 400")
    void putAvecIdentiteNulleEstRejete() throws Exception {
        long cvId = createCv(CvFixtures.completeCv());
        // Corps reellement emis par le client mobile quand l'identite est
        // absente (cv_mapper.dart) : la cle est presente et vaut null.
        Map<String, Object> corps = sansIdentite();
        corps.put("personalInfo", null);

        mvc.perform(put("/api/cvs/" + cvId)
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(corps)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("un rejet laisse intacte l'identite deja enregistree")
    void unRejetLaisseLIdentiteIntacte() throws Exception {
        long cvId = createCv(CvFixtures.completeCv());

        mvc.perform(put("/api/cvs/" + cvId)
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(sansIdentite())))
                .andExpect(status().isBadRequest());

        mvc.perform(get("/api/cvs/" + cvId).header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.personalInfo.prenom").value("Test"))
                .andExpect(jsonPath("$.personalInfo.nom").value("Integration"));
    }

    @Test
    @DisplayName("avec identite : la mise a jour remplace bien l'identite")
    void putAvecIdentiteRemplaceLIdentite() throws Exception {
        long cvId = createCv(CvFixtures.completeCv());
        Map<String, Object> corps = sansIdentite();
        corps.put("personalInfo", Map.of(
                "prenom", "Awa",
                "nom", "Kone",
                "email", "awa.kone@example.com"));

        mvc.perform(put("/api/cvs/" + cvId)
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(corps)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.personalInfo.prenom").value("Awa"))
                .andExpect(jsonPath("$.personalInfo.nom").value("Kone"));
    }

    @Test
    @DisplayName("les contraintes du groupe par defaut restent appliquees")
    void lesContraintesDuGroupeParDefautRestentAppliquees() throws Exception {
        // Garde-fou du piege documente sur OnUpdate : citer ce seul groupe dans
        // @Validated desactiverait silencieusement @NotBlank sur le titre. Ce
        // test repondrait alors 200 au lieu de 400.
        long cvId = createCv(CvFixtures.completeCv());
        Map<String, Object> corps = new HashMap<>(CvFixtures.completeCv());
        corps.put("titre", "   ");

        mvc.perform(put("/api/cvs/" + cvId)
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(corps)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("la creation sans identite reste acceptee")
    void laCreationSansIdentiteResteAcceptee() throws Exception {
        // Non-regression : la contrainte porte le groupe OnUpdate, elle ne doit
        // pas durcir le contrat de creation.
        mvc.perform(post("/api/cvs")
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(sansIdentite())))
                .andExpect(status().isCreated());
    }

    /** Fixture complete privee de sa seule cle identite. */
    private static Map<String, Object> sansIdentite() {
        Map<String, Object> corps = new HashMap<>(CvFixtures.completeCv());
        corps.remove("personalInfo");
        return corps;
    }

    private long createCv(Map<String, Object> corps) throws Exception {
        MvcResult result = mvc.perform(post("/api/cvs")
                        .header("Authorization", bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(corps)))
                .andExpect(status().isCreated())
                .andReturn();

        Map<?, ?> body = mapper.readValue(
                result.getResponse().getContentAsString(), Map.class);
        return ((Number) body.get("id")).longValue();
    }
}
