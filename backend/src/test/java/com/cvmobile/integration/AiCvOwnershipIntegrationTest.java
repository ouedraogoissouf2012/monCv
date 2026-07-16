package com.cvmobile.integration;

import com.cvmobile.model.Cv;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.security.JwtTokenProvider;
import com.cvmobile.service.ai.client.CompositeAiClient;
import com.cvmobile.service.ai.client.MockAiClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = "spring.jpa.open-in-view=false")
class AiCvOwnershipIntegrationTest extends PostgresIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper mapper;
    @Autowired private JwtTokenProvider jwtTokenProvider;
    @Autowired private UserRepository userRepository;
    @Autowired private CvRepository cvRepository;

    @MockBean(name = "compositeAiClient")
    private CompositeAiClient aiClient;

    private final MockAiClient deterministicResponse = new MockAiClient();
    private User owner;
    private User attacker;
    private User admin;
    private Cv ownerCv;

    @BeforeEach
    void createTwoUsersAndCv() {
        String suffix = UUID.randomUUID().toString();
        owner = saveUser("owner-" + suffix + "@example.com", User.Role.USER);
        attacker = saveUser("attacker-" + suffix + "@example.com", User.Role.USER);
        admin = saveUser("admin-" + suffix + "@example.com", User.Role.ADMIN);
        ownerCv = cvRepository.save(Cv.builder()
                .titre("OWNER_SECRET_CV")
                .user(owner)
                .build());
    }

    @AfterEach
    void deleteFixture() {
        if (ownerCv != null && cvRepository.existsById(ownerCv.getId())) {
            cvRepository.deleteById(ownerCv.getId());
        }
        userRepository.deleteAllById(List.of(owner.getId(), attacker.getId(), admin.getId()));
    }

    @ParameterizedTest(name = "{0} refuse un CV tiers et un CV absent sans appeler l IA")
    @EnumSource(AiEndpoint.class)
    void thirdPartyAndMissingCvHaveSameNotFoundContract(AiEndpoint endpoint) throws Exception {
        MvcResult foreign = perform(endpoint, token(attacker), ownerCv.getId())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"))
                .andReturn();
        assertThat(foreign.getResponse().getContentAsString()).doesNotContain("OWNER_SECRET_CV");

        cvRepository.deleteById(ownerCv.getId());
        MvcResult absent = perform(endpoint, token(attacker), ownerCv.getId())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"))
                .andReturn();

        JsonNode foreignBody = mapper.readTree(foreign.getResponse().getContentAsString());
        JsonNode absentBody = mapper.readTree(absent.getResponse().getContentAsString());
        assertThat(foreignBody.path("message").asText())
                .isEqualTo(absentBody.path("message").asText());
        verifyNoInteractions(aiClient);
    }

    @ParameterizedTest(name = "{0} bloque un utilisateur non authentifie avant l IA")
    @EnumSource(AiEndpoint.class)
    void unauthenticatedRequestCannotReachAi(AiEndpoint endpoint) throws Exception {
        perform(endpoint, null, ownerCv.getId())
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(aiClient);
    }

    @ParameterizedTest(name = "{0} autorise le proprietaire et appelle l IA")
    @EnumSource(AiEndpoint.class)
    void ownerCanUseEachAiEndpoint(AiEndpoint endpoint) throws Exception {
        when(aiClient.complete(anyString(), anyInt())).thenAnswer(invocation ->
                deterministicResponse.complete(invocation.getArgument(0), invocation.getArgument(1)));

        perform(endpoint, token(owner), ownerCv.getId())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.aiGenerated").value(true));

        verify(aiClient).complete(anyString(), anyInt());
        verify(aiClient).isFallbackResult();
    }

    @ParameterizedTest(name = "{0} n accorde aucun bypass administrateur")
    @EnumSource(AiEndpoint.class)
    void administratorCannotUseAnotherUsersCv(AiEndpoint endpoint) throws Exception {
        perform(endpoint, token(admin), ownerCv.getId())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"));
        verifyNoInteractions(aiClient);
    }

    @Test
    void variantRefuseUnCvTiersAvantAdaptationIa() throws Exception {
        performVariant(token(attacker), ownerCv.getId())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"));
        verifyNoInteractions(aiClient);
    }

    @Test
    void docxUsesTheSameOwnershipPolicyAndLoadsDetailsForOwner() throws Exception {
        mvc.perform(get("/api/cvs/" + ownerCv.getId() + "/docx")
                        .header("Authorization", "Bearer " + token(owner)))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(
                        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"));

        mvc.perform(get("/api/cvs/" + ownerCv.getId() + "/docx")
                        .header("Authorization", "Bearer " + token(attacker)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"));
    }

    private org.springframework.test.web.servlet.ResultActions perform(
            AiEndpoint endpoint, String token, Long cvId) throws Exception {
        var request = post(endpoint.path)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(endpoint.body(cvId)));
        if (token != null) request.header("Authorization", "Bearer " + token);
        return mvc.perform(request);
    }

    private org.springframework.test.web.servlet.ResultActions performVariant(String token, Long cvId)
            throws Exception {
        return mvc.perform(post("/api/cvs/" + cvId + "/variant")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                        "jobDescription", "Developpeur backend Java et Spring Boot"))));
    }

    private String token(User user) {
        return jwtTokenProvider.generateToken(user.getEmail());
    }

    private User saveUser(String email, User.Role role) {
        return userRepository.save(User.builder()
                .email(email)
                .password("encoded-test-password")
                .role(role)
                .build());
    }

    private enum AiEndpoint {
        ENHANCE("/api/ai/enhance-cv") {
            @Override Map<String, Object> body(Long cvId) {
                return Map.of("cvId", cvId, "level", "LITE", "aiConsentAccepted", true);
            }
        },
        MATCH("/api/ai/match-job") {
            @Override Map<String, Object> body(Long cvId) {
                return Map.of("cvId", cvId, "jobDescription", "Developpeur backend Java et Spring Boot",
                        "aiConsentAccepted", true);
            }
        },
        APPLICATION_MESSAGES("/api/ai/application-messages") {
            @Override Map<String, Object> body(Long cvId) {
                return Map.of("cvId", cvId, "jobDescription", "Recherche Developpeur backend Java et Spring Boot",
                        "tone", "PROFESSIONAL", "aiConsentAccepted", true);
            }
        };

        private final String path;

        AiEndpoint(String path) { this.path = path; }

        abstract Map<String, Object> body(Long cvId);
    }
}
