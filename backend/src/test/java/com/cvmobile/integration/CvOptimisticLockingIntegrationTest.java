package com.cvmobile.integration;

import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.application.usecase.UpdateCvUseCase;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.Experience;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Prouve le verrou optimiste de l'agregat CV (issue #506).
 *
 * <p>Avant {@code @Version}, deux {@code PUT /cvs/{id}} concurrents se
 * recouvraient en silence : chacun lisait l'etat, remplacait les sections
 * ({@code orphanRemoval}) puis ecrivait, et la derniere transaction validee
 * effacait le travail de l'autre <em>sans aucune erreur</em>. Un test
 * sequentiel ne peut pas le montrer : il faut deux transactions reellement
 * entrelacees, d'ou les deux threads et la barriere qui les fait lire avant que
 * l'une ou l'autre ne valide.
 */
@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "spring.jpa.open-in-view=false")
@DisplayName("Verrou optimiste sur l'edition de CV (Postgres reel)")
class CvOptimisticLockingIntegrationTest extends PostgresIntegrationTest {

    /** Marge large : borne une eventuelle attente, sans rendre le test sensible a la charge. */
    private static final int STAGING_TIMEOUT_SECONDS = 10;

    @Autowired private UpdateCvUseCase updateCvUseCase;
    @Autowired private CvRepositoryPort port;
    @Autowired private CvRepository cvRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private PlatformTransactionManager transactionManager;

    private TransactionTemplate transactions;
    private User owner;
    private long cvId;

    @BeforeEach
    void seedOwnerAndCv() {
        transactions = new TransactionTemplate(transactionManager);
        owner = userRepository.save(User.builder()
                .email("editor-" + UUID.randomUUID() + "@it.test")
                .password("encoded-test-password")
                .role(User.Role.USER)
                .build());
        cvId = port.save(Cv.create("CV partage", owner.getId())).getId();
    }

    @AfterEach
    void cleanUp() {
        if (cvRepository.existsById(cvId)) cvRepository.deleteById(cvId);
        userRepository.deleteById(owner.getId());
    }

    @Test
    @DisplayName("deux editions concurrentes : la seconde echoue au lieu d'effacer la premiere")
    void concurrentUpdatesRejectTheStaleWriterInsteadOfLosingItsRival()
            throws InterruptedException {
        CountDownLatch staged = new CountDownLatch(2);
        ExecutorService threads = Executors.newFixedThreadPool(2);
        try {
            Future<Void> mobile = threads.submit(stagedUpdate("Depuis le mobile", "ACME", staged));
            Future<Void> web = threads.submit(stagedUpdate("Depuis le web", "GLOBEX", staged));

            List<Throwable> failures = List.of(mobile, web).stream()
                    .map(CvOptimisticLockingIntegrationTest::failureOf)
                    .filter(java.util.Objects::nonNull)
                    .toList();

            assertThat(failures)
                    .as("une seule des deux editions concurrentes doit aboutir")
                    .singleElement()
                    .isInstanceOf(OptimisticLockingFailureException.class);
        } finally {
            threads.shutdownNow();
            assertThat(threads.awaitTermination(STAGING_TIMEOUT_SECONDS, TimeUnit.SECONDS)).isTrue();
        }

        Cv survivor = port.findByIdAndOwnerId(cvId, owner.getId()).orElseThrow();
        assertThat(survivor.getExperiences())
                .as("l'edition rejetee ne doit avoir ni ajoute ni efface de section")
                .singleElement()
                .satisfies(experience -> assertThat(survivor.getTitre())
                        .isEqualTo("Depuis le " + ("ACME".equals(experience.entreprise()) ? "mobile" : "web")));
    }

    /**
     * L'issue #506 porte sur des sections effacees : le verrou serait inutile
     * s'il ignorait les modifications ne touchant que les collections filles.
     */
    @Test
    @DisplayName("la revision progresse meme quand seules les sections changent")
    void versionAdvancesWhenOnlySectionsChange() {
        Long initialVersion = cvRepository.findById(cvId).orElseThrow().getVersion();

        transactions.executeWithoutResult(status -> {
            Cv changes = port.findByIdAndOwnerId(cvId, owner.getId()).orElseThrow();
            changes.replaceExperiences(List.of(experience("ACME")));
            updateCvUseCase.update(cvId, owner.getId(), changes);
        });

        assertThat(cvRepository.findById(cvId).orElseThrow().getVersion())
                .as("un ajout de section doit incrementer la revision de l'agregat")
                .isGreaterThan(initialVersion);
    }

    /** Une edition isolee ne doit evidemment pas etre penalisee par le verrou. */
    @Test
    @DisplayName("une edition sans concurrence aboutit normalement")
    void aLoneUpdateStillSucceeds() {
        transactions.executeWithoutResult(status -> {
            Cv changes = Cv.create("Titre unique", owner.getId());
            updateCvUseCase.update(cvId, owner.getId(), changes);
        });

        assertThat(port.findByIdAndOwnerId(cvId, owner.getId()).orElseThrow().getTitre())
                .isEqualTo("Titre unique");
    }

    /**
     * Chaque thread lit et prepare son ecriture, puis attend l'autre avant de
     * valider : c'est cet entrelacement — et lui seul — qui produisait la perte
     * de donnees silencieuse.
     */
    private Callable<Void> stagedUpdate(String titre, String entreprise, CountDownLatch staged) {
        return () -> transactions.execute(status -> {
            Cv changes = Cv.create(titre, owner.getId());
            changes.replaceExperiences(List.of(experience(entreprise)));
            updateCvUseCase.update(cvId, owner.getId(), changes);
            awaitPeer(staged);
            return null;
        });
    }

    private static void awaitPeer(CountDownLatch staged) {
        staged.countDown();
        try {
            staged.await(STAGING_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Attente du thread concurrent interrompue", interrupted);
        }
    }

    /** {@code null} si l'edition a abouti, sinon la cause reelle de son echec. */
    private static Throwable failureOf(Future<Void> update) {
        try {
            update.get(STAGING_TIMEOUT_SECONDS, TimeUnit.SECONDS);
            return null;
        } catch (ExecutionException failure) {
            return failure.getCause();
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Attente du resultat interrompue", interrupted);
        } catch (java.util.concurrent.TimeoutException timeout) {
            throw new IllegalStateException("Edition concurrente bloquee", timeout);
        }
    }

    private static Experience experience(String entreprise) {
        return Experience.of(null, entreprise, "Developpeur", "Ouagadougou",
                LocalDate.of(2021, 1, 1), LocalDate.of(2023, 1, 1), "Concu un service", false);
    }
}
