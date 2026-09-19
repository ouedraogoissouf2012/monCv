package com.cvmobile.integration;

import com.cvmobile.dto.NotificationDtos;
import com.cvmobile.model.DeviceToken;
import com.cvmobile.model.User;
import com.cvmobile.repository.DeviceTokenRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.service.notification.NotificationService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Enregistrement d'un jeton d'appareil (issue #511).
 *
 * <p>Sur PostgreSQL reel : {@code ON CONFLICT} n'existe pas en base embarquee, et
 * c'est precisement la contrainte d'unicite qui est en jeu ici.
 *
 * <p>Le defaut corrige : {@code registerDevice} lisait le jeton, puis ecrivait.
 * Entre les deux, une requete concurrente portant le meme jeton pouvait inserer
 * la ligne ; la seconde insertion violait alors l'unicite et remontait en 500,
 * pour une operation pourtant idempotente.
 */
@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "spring.jpa.open-in-view=false")
@DisplayName("Enregistrement de jeton d'appareil (Postgres reel)")
class DeviceTokenUpsertIntegrationTest extends PostgresIntegrationTest {

    private static final int TIMEOUT_SECONDS = 15;

    @Autowired private NotificationService notifications;
    @Autowired private DeviceTokenRepository tokens;
    @Autowired private UserRepository users;

    private User proprietaire;
    private User second;
    private String jeton;

    @BeforeEach
    void seed() {
        proprietaire = users.save(User.builder()
                .email("device-" + UUID.randomUUID() + "@it.test")
                .password("encoded-test-password")
                .role(User.Role.USER).build());
        second = users.save(User.builder()
                .email("device-" + UUID.randomUUID() + "@it.test")
                .password("encoded-test-password")
                .role(User.Role.USER).build());
        jeton = "fcm-" + UUID.randomUUID();
    }

    @AfterEach
    void cleanUp() {
        tokens.findByToken(jeton).map(DeviceToken::getId).ifPresent(tokens::deleteById);
        users.deleteById(proprietaire.getId());
        users.deleteById(second.getId());
    }

    private NotificationDtos.DeviceTokenRequest requete() {
        return new NotificationDtos.DeviceTokenRequest(jeton, "android");
    }

    @Test
    @DisplayName("un premier enregistrement cree le jeton")
    void premierEnregistrement_creeLeJeton() {
        notifications.registerDevice(proprietaire, requete());

        DeviceToken enregistre = tokens.findByToken(jeton).orElseThrow();
        assertThat(enregistre.getUser().getId()).isEqualTo(proprietaire.getId());
        assertThat(enregistre.getPlatform()).isEqualTo("android");
    }

    @Test
    @DisplayName("reenregistrer le meme jeton ne cree pas de doublon")
    void reenregistrement_resteIdempotent() {
        notifications.registerDevice(proprietaire, requete());
        notifications.registerDevice(proprietaire, requete());

        assertThat(tokens.findByUserId(proprietaire.getId()))
                .as("l'application reenregistre son jeton a chaque demarrage")
                .hasSize(1);
    }

    @Test
    @DisplayName("un jeton repris par un autre compte lui est reaffecte")
    void jetonRepris_estReaffecte() {
        notifications.registerDevice(proprietaire, requete());

        notifications.registerDevice(second, requete());

        assertThat(tokens.findByToken(jeton).orElseThrow().getUser().getId())
                .as("appareil partage ou reinstallation : le jeton suit le dernier compte")
                .isEqualTo(second.getId());
        assertThat(tokens.findByUserId(proprietaire.getId()))
                .as("l'ancien proprietaire ne doit plus recevoir ses notifications")
                .isEmpty();
    }

    @Test
    @DisplayName("deux enregistrements concurrents du meme jeton n'echouent pas")
    void enregistrementsConcurrents_aucuneViolationDUnicite() throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Callable<Throwable> enregistrer = () -> {
                try {
                    notifications.registerDevice(proprietaire, requete());
                    return null;
                } catch (Throwable echec) {
                    return echec;
                }
            };

            List<Future<Throwable>> resultats =
                    pool.invokeAll(List.of(enregistrer, enregistrer));

            for (Future<Throwable> resultat : resultats) {
                assertThat(resultat.get(TIMEOUT_SECONDS, TimeUnit.SECONDS))
                        .as("c'est exactement la course qui produisait une 500 :"
                                + " les deux appels ne trouvaient aucune ligne,"
                                + " puis tentaient tous deux l'insertion")
                        .isNull();
            }
        } finally {
            pool.shutdownNow();
        }

        assertThat(tokens.findByUserId(proprietaire.getId()))
                .as("une seule ligne doit subsister, quelle que soit la concurrence")
                .hasSize(1);
    }
}
