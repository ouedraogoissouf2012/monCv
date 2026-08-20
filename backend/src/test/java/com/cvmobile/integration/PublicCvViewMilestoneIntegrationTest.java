package com.cvmobile.integration;

import com.cvmobile.model.Cv;
import com.cvmobile.model.DeviceToken;
import com.cvmobile.model.NotificationDelivery;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.DeviceTokenRepository;
import com.cvmobile.repository.NotificationDeliveryRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import com.cvmobile.service.cv.PublicCvAccessService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doReturn;

/**
 * Issue #507 : une collision UNIQUE sur le palier de vues ne doit pas marquer
 * la transaction de lecture rollback-only (500 + vue perdue).
 */
@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties =
        "jwt.secret=ViewMilestone-B8yR4nM7qW2xK9pL5vT1sD6fH3jU0eA7zC4gN8mQ2rX6kP9wV5b")
class PublicCvViewMilestoneIntegrationTest extends PostgresIntegrationTest {

    @Autowired PublicCvAccessService accessService;
    @Autowired CvRepository cvRepository;
    @Autowired UserRepository userRepository;
    @Autowired DeviceTokenRepository deviceTokens;
    @Autowired PublicShareTokenCodec tokenCodec;
    @SpyBean NotificationDeliveryRepository deliveries;

    private User owner;
    private Long cvId;
    private Long deliveryId;
    private String token;

    @BeforeEach
    void seedPublicCvAtNinthView() {
        token = tokenCodec.generate();
        owner = userRepository.save(User.builder()
                .email("views-" + UUID.randomUUID() + "@example.test")
                .password("encoded-password")
                .role(User.Role.USER)
                .build());
        Cv cv = cvRepository.saveAndFlush(Cv.builder()
                .titre("CV vues")
                .user(owner)
                .viewCount(9)
                .publicToken(tokenCodec.encrypt(token))
                .publicTokenHash(tokenCodec.digest(token))
                .build());
        cvId = cv.getId();
        deviceTokens.save(DeviceToken.builder()
                .user(owner).token("device-" + UUID.randomUUID())
                .platform("android").build());
        deliveryId = deliveries.saveAndFlush(NotificationDelivery.builder()
                .user(owner).cv(cv).notificationType("CV_VIEWS")
                .deduplicationKey("views:" + cvId + ":10").build()).getId();
        doReturn(false).when(deliveries).existsByDeduplicationKey(anyString());
    }

    @AfterEach
    void deleteFixture() {
        if (deliveryId != null) deliveries.deleteById(deliveryId);
        if (cvId != null) cvRepository.deleteById(cvId);
        if (owner != null) {
            deviceTokens.findByUserId(owner.getId()).forEach(deviceTokens::delete);
            userRepository.deleteById(owner.getId());
        }
    }

    @Test
    void collisionDeDedupNEmpecheNiLaLectureNiLeComptage() {
        assertThatCode(() -> accessService.getPortfolio(token, "203.0.113.10"))
                .doesNotThrowAnyException();

        assertThat(cvRepository.findById(cvId).orElseThrow().getViewCount())
                .isEqualTo(10);
    }
}
