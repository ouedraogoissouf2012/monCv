package com.cvmobile.integration;

import com.cvmobile.model.Cv;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.model.UploadedPhoto;
import com.cvmobile.repository.UploadedPhotoRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import com.cvmobile.service.cv.PublicCvAccessService;
import com.cvmobile.service.FileStorageService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.mock.web.MockMultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.hamcrest.Matchers.containsString;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties =
        "jwt.secret=PublicSecurity-B8yR4nM7qW2xK9pL5vT1sD6fH3jU0eA7zC4gN8mQ2rX6kP9wV5b")
class PublicCvSecurityIntegrationTest extends PostgresIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired UserRepository userRepository;
    @Autowired CvRepository cvRepository;
    @Autowired PublicShareTokenCodec tokenCodec;
    @Autowired PublicCvAccessService accessService;
    @Autowired FileStorageService fileStorageService;
    @Autowired UploadedPhotoRepository uploadedPhotoRepository;

    private User owner;

    private String token;
    private Long cvId;
    private Long userId;
    private String storedPhotoFilename;

    @BeforeEach
    void createPublicCv() {
        token = tokenCodec.generate();
        owner = userRepository.save(User.builder()
                .email("public-security-" + UUID.randomUUID() + "@example.test")
                .password("encoded-password").role(User.Role.USER).build());
        userId = owner.getId();
        String storedPhotoUrl = fileStorageService.storePhoto(new MockMultipartFile(
                "file", "portrait.jpg", "image/jpeg",
                new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF}));
        storedPhotoFilename = storedPhotoUrl.substring(storedPhotoUrl.lastIndexOf('/') + 1);
        uploadedPhotoRepository.saveAndFlush(new UploadedPhoto(storedPhotoFilename, owner));
        Cv cv = cvRepository.saveAndFlush(Cv.builder().titre("CV securise").user(owner)
                .personalInfo(PersonalInfo.builder().nom("Kone").prenom("Awa")
                        .email("private@example.test").telephone("+22501020304")
                        .adresse("Adresse privee").codePostal("00000")
                        .photoUrl(storedPhotoUrl).build())
                .publicToken(tokenCodec.encrypt(token)).publicTokenHash(tokenCodec.digest(token))
                .publicDownloadsEnabled(true).publicContactEnabled(false).build());
        cvId = cv.getId();
    }

    @AfterEach
    void deleteFixture() throws Exception {
        if (cvId != null) cvRepository.deleteById(cvId);
        if (userId != null) userRepository.deleteById(userId);
        if (storedPhotoFilename != null) {
            java.nio.file.Files.deleteIfExists(fileStorageService.resolve(storedPhotoFilename));
        }
    }

    @Test
    void realPublicRouteHidesPrivateDataAndAppliesResponseHeaders() throws Exception {
        mvc.perform(get("/api/cvs/public/{token}", token))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", containsString("no-store")))
                .andExpect(header().string("Referrer-Policy", "no-referrer"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(jsonPath("$.titre").value("CV securise"))
                .andExpect(jsonPath("$.personalInfo.email").doesNotExist())
                .andExpect(jsonPath("$.personalInfo.telephone").doesNotExist())
                .andExpect(jsonPath("$.personalInfo.adresse").doesNotExist())
                .andExpect(jsonPath("$.personalInfo.codePostal").doesNotExist())
                .andExpect(jsonPath("$.personalInfo.photoUrl")
                        .value("/api/cvs/public/" + token + "/photo"))
                .andExpect(jsonPath("$.id").doesNotExist())
                .andExpect(jsonPath("$.publicToken").doesNotExist());

        Cv stored = cvRepository.findById(cvId).orElseThrow();
        assertThat(stored.getPublicToken()).isNotEqualTo(token);
        assertThat(stored.getPublicTokenHash()).isEqualTo(tokenCodec.digest(token));

        mvc.perform(get("/api/cvs/public/{token}/photo", token))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "image/jpeg"));

        mvc.perform(get("/api/uploads/photos/{filename}", storedPhotoFilename))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/uploads/photos/{filename}", storedPhotoFilename)
                        .with(user(owner)))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "private, no-store"))
                .andExpect(result -> assertThat(
                        result.getResponse().getHeaders(HttpHeaders.VARY))
                        .contains(HttpHeaders.AUTHORIZATION));
    }

    @Test
    void shareEndpointRejectsSimpleCrossSiteContentType() throws Exception {
        mvc.perform(post("/api/cvs/public/{token}/share", token)
                        .contentType(MediaType.TEXT_PLAIN).content("{}"))
                .andExpect(status().isUnsupportedMediaType());
        mvc.perform(post("/api/cvs/public/{token}/share", token)
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isNoContent());
    }

    @Test
    void concurrentShareUpdatesAreNotLost() throws Exception {
        int requestCount = 20;
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(8);
        List<Future<?>> futures = new ArrayList<>();
        try {
            for (int index = 0; index < requestCount; index++) {
                futures.add(executor.submit(() -> {
                    start.await();
                    accessService.trackShare(token);
                    return null;
                }));
            }
            start.countDown();
            for (Future<?> future : futures) future.get(15, TimeUnit.SECONDS);
        } finally {
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS)).isTrue();
        }

        assertThat(cvRepository.findById(cvId).orElseThrow().getShareCount())
                .isEqualTo(requestCount);
    }
}
