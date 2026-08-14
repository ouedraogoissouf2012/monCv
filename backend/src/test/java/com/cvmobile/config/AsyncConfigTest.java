package com.cvmobile.config;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifie que l'executor d'emails (issue #495) est <strong>borne</strong> et que sa
 * politique de rejet est <strong>explicite</strong>, conditions de la propriete de temps
 * de reponse constant : un pool non borne ou un repli sur le thread appelant
 * reintroduirait l'ecart de latence exploitable pour l'enumeration des comptes.
 */
class AsyncConfigTest {

    private ThreadPoolTaskExecutor executor;

    @AfterEach
    void shutdown() {
        if (executor != null) {
            executor.shutdown();
        }
    }

    @Test
    void emailTaskExecutor_estUnPoolBorneAvecRejetExplicite() {
        executor = new AsyncConfig().emailTaskExecutor();

        assertThat(executor.getCorePoolSize()).isEqualTo(2);
        assertThat(executor.getMaxPoolSize()).isEqualTo(5);
        assertThat(executor.getQueueCapacity()).isEqualTo(100);
        assertThat(executor.getThreadPoolExecutor().getRejectedExecutionHandler())
                .isInstanceOf(ThreadPoolExecutor.AbortPolicy.class);
    }

    @Test
    void emailTaskExecutor_executeEffectivementUneTache() throws InterruptedException {
        executor = new AsyncConfig().emailTaskExecutor();
        StringBuilder marker = new StringBuilder();

        executor.execute(() -> marker.append("done"));
        ThreadPoolExecutor pool = executor.getThreadPoolExecutor();
        pool.shutdown();
        boolean terminated = pool.awaitTermination(5, TimeUnit.SECONDS);

        assertThat(terminated).isTrue();
        assertThat(marker.toString()).isEqualTo("done");
    }
}
