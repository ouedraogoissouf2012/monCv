package com.cvmobile.security;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import com.cvmobile.exception.PublicDocumentUnavailableException;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PublicDocumentGuardTest {
    @Test
    void rejectsOversizedAndEmptyDocuments() {
        PublicDocumentGuard guard = guard(4);

        assertThatThrownBy(() -> guard.generate(() -> new byte[5]))
                .isInstanceOf(PublicDocumentUnavailableException.class);
        assertThatThrownBy(() -> guard.generate(() -> new byte[0]))
                .isInstanceOf(PublicDocumentUnavailableException.class);
        assertThat(guard.generate(() -> new byte[]{1, 2, 3})).hasSize(3);
    }

    @Test
    void rejectsConcurrentGenerationWhenTheBulkheadIsFull() throws Exception {
        PublicDocumentGuard guard = guard(1024);
        CountDownLatch entered = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        CompletableFuture<byte[]> first = CompletableFuture.supplyAsync(() ->
                guard.generate(() -> {
                    entered.countDown();
                    await(release);
                    return new byte[]{1};
                }));

        assertThat(entered.await(1, TimeUnit.SECONDS)).isTrue();
        assertThatThrownBy(() -> guard.generate(() -> new byte[]{2}))
                .isInstanceOf(PublicDocumentUnavailableException.class);
        release.countDown();
        assertThat(first.get(1, TimeUnit.SECONDS)).containsExactly(1);
    }

    private PublicDocumentGuard guard(int maxBytes) {
        return new PublicDocumentGuard(new PublicPortfolioSecurityProperties(
                "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=",
                Duration.ofMinutes(5), 1, Duration.ofMillis(25),
                maxBytes, List.of()));
    }

    private void await(CountDownLatch latch) {
        try {
            latch.await(1, TimeUnit.SECONDS);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
        }
    }
}
