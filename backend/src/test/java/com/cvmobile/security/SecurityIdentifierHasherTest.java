package com.cvmobile.security;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class SecurityIdentifierHasherTest {
    private final SecurityIdentifierHasher hasher = new SecurityIdentifierHasher(
            new PublicShareTokenCodec(new PublicPortfolioSecurityProperties(
                    "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=",
                    Duration.ofMinutes(5), 2, Duration.ofMillis(100),
                    10 * 1024 * 1024, List.of())));

    @Test
    void producesStablePurposeBoundPseudonymsWithoutLeakingTheIp() {
        String first = hasher.hash("rate-limit", "203.0.113.42");
        String repeated = hasher.hash("rate-limit", "203.0.113.42");
        String otherPurpose = hasher.hash("public-view", "203.0.113.42");

        assertThat(first).isEqualTo(repeated).hasSize(32);
        assertThat(first).isNotEqualTo(otherPurpose).doesNotContain("203.0.113.42");
    }
}
