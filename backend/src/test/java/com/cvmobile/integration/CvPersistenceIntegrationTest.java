package com.cvmobile.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CvPersistenceIntegrationTest extends PostgresIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;

    @Test
    void createdCvRemainsCompleteWhenReadBack() throws Exception {
        String email = "persistence-" + UUID.randomUUID() + "@integration.test";
        String token = register(email);
        String cvId = createCv(token, email);

        mvc.perform(get("/api/cvs/{id}", cvId).header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.titre").value("Developpeur Full Stack Java"))
                .andExpect(jsonPath("$.personalInfo.email").value(email))
                .andExpect(jsonPath("$.personalInfo.telephone").value("+225 0700000000"))
                .andExpect(jsonPath("$.personalInfo.titrePoste").value("Developpeur Full Stack Java"))
                .andExpect(jsonPath("$.personalInfo.resumeProfessionnel").value(
                        "Developpeur Full Stack avec trois ans d'experience en Java, Spring Boot et Angular."))
                .andExpect(jsonPath("$.experiences[0].entreprise").value("TechCorp"))
                .andExpect(jsonPath("$.experiences[0].description").value(
                        "Developpement d'applications web testees et livrees avec une equipe agile."))
                .andExpect(jsonPath("$.educations[0].diplome").value("Licence Informatique"))
                .andExpect(jsonPath("$.skills[*].nom", containsInAnyOrder("Java", "Angular", "Spring Boot")))
                .andExpect(jsonPath("$.languages[*].langue", containsInAnyOrder("Francais", "Anglais")))
                .andExpect(jsonPath("$.style.templateId").value("ats"));

        mvc.perform(get("/api/cvs").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", hasItem(Integer.valueOf(cvId))));
    }

    private String register(String email) throws Exception {
        String response = mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "email", email,
                                "password", "Test1234!",
                                "prenom", "Test",
                                "nom", "Persistence"))))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).get("accessToken").asText();
    }

    private String createCv(String token, String email) throws Exception {
        Map<String, Object> cv = Map.of(
                "titre", "Developpeur Full Stack Java",
                "personalInfo", Map.of(
                        "prenom", "Test", "nom", "Persistence", "email", email,
                        "telephone", "+225 0700000000", "ville", "Abidjan",
                        "titrePoste", "Developpeur Full Stack Java",
                        "resumeProfessionnel",
                        "Developpeur Full Stack avec trois ans d'experience en Java, Spring Boot et Angular."),
                "experiences", List.of(Map.of(
                        "poste", "Developpeur Web", "entreprise", "TechCorp", "lieu", "Abidjan",
                        "dateDebut", "2023-01-01", "dateFin", "2025-12-31", "actuel", false,
                        "description", "Developpement d'applications web testees et livrees avec une equipe agile.")),
                "educations", List.of(Map.of(
                        "diplome", "Licence Informatique", "etablissement", "Universite",
                        "lieu", "Abidjan", "dateDebut", "2019-09-01", "dateFin", "2022-06-30")),
                "skills", List.of(Map.of("nom", "Java"), Map.of("nom", "Angular"),
                        Map.of("nom", "Spring Boot")),
                "languages", List.of(Map.of("nom", "Francais", "langue", "Francais", "niveau", "C2"),
                        Map.of("nom", "Anglais", "langue", "Anglais", "niveau", "B1")),
                "style", Map.of("templateId", "ats", "primaryColor", 0xFF2563EBL, "fontFamily", "Roboto"));

        String response = mvc.perform(post("/api/cvs")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(cv)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        JsonNode created = mapper.readTree(response);
        return created.get("id").asText();
    }
}
