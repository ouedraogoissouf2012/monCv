package com.cvmobile.integration;

import com.cvmobile.model.Cv;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.service.ai.client.CompositeAiClient;
import com.cvmobile.service.ai.client.MockAiClient;
import com.cvmobile.service.cv.ICvService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Prouve la frontiere transactionnelle de la creation de variante (issue #254,
 * M-4) : l'appel IA (HTTP externe) NE doit PAS s'executer dans une transaction
 * DB, sinon une connexion HikariCP reste retenue pendant tout le round-trip IA
 * (risque d'epuisement du pool sous concurrence / provider lent).
 *
 * <p>Un test unitaire ne peut pas distinguer ce comportement : les proxys
 * {@code @Transactional} n'existent qu'avec un contexte Spring reel. On mock le
 * client IA de plus bas niveau pour capturer
 * {@link TransactionSynchronizationManager#isActualTransactionActive()} au
 * moment exact de l'appel.
 */
@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "spring.jpa.open-in-view=false")
class CvVariantTransactionBoundaryIntegrationTest extends PostgresIntegrationTest {

    @Autowired private ICvService cvService;
    @Autowired private UserRepository userRepository;
    @Autowired private CvRepository cvRepository;

    @MockBean(name = "compositeAiClient")
    private CompositeAiClient aiClient;

    private final MockAiClient deterministicResponse = new MockAiClient();

    /** Vrai par defaut : si l'IA n'est jamais appelee, l'assertion echoue. */
    private final AtomicBoolean transactionActiveDuringAiCall = new AtomicBoolean(true);

    private User owner;
    private Cv ownerCv;

    @BeforeEach
    void seedOwnerAndCv() {
        String suffix = UUID.randomUUID().toString();
        owner = userRepository.save(User.builder()
                .email("owner-" + suffix + "@example.com")
                .password("encoded-test-password")
                .role(User.Role.USER)
                .build());
        ownerCv = cvRepository.save(Cv.builder()
                .titre("CV a adapter")
                .user(owner)
                .build());
    }

    @AfterEach
    void cleanUp() {
        cvRepository.findByParentIdAndUserId(ownerCv.getId(), owner.getId())
                .forEach(variant -> cvRepository.deleteById(variant.getId()));
        if (cvRepository.existsById(ownerCv.getId())) {
            cvRepository.deleteById(ownerCv.getId());
        }
        userRepository.deleteById(owner.getId());
    }

    @Test
    void adaptationIaSExecuteHorsTransaction() {
        when(aiClient.complete(anyString(), anyInt())).thenAnswer(invocation -> {
            transactionActiveDuringAiCall.set(
                    TransactionSynchronizationManager.isActualTransactionActive());
            return deterministicResponse.complete(
                    invocation.getArgument(0), invocation.getArgument(1));
        });
        when(aiClient.isFallbackResult()).thenReturn(false);

        cvService.createVariant(
                ownerCv.getId(), "Developpeur backend Java et Spring Boot", null, owner.getId());

        assertThat(transactionActiveDuringAiCall.get())
                .as("l'appel IA (HTTP externe) ne doit pas retenir de connexion DB "
                        + "dans une transaction ouverte")
                .isFalse();
    }
}
