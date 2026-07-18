package com.cvmobile.security;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PublicShareTokenCodecTest {
    private static final String KEY =
            "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=";
    private final PublicShareTokenCodec codec = new PublicShareTokenCodec(properties());

    @Test
    void generatedTokensHave256BitsAndDoNotCollide() {
        Set<String> tokens = new HashSet<>();
        for (int i = 0; i < 256; i++) tokens.add(codec.generate());

        assertThat(tokens).hasSize(256);
        assertThat(tokens).allMatch(token -> token.matches("[A-Za-z0-9_-]{43}"));
    }

    @Test
    void encryptsAuthenticatesAndHashesWithoutPersistingPlaintext() {
        String token = codec.generate();
        String encrypted = codec.encrypt(token);
        String digest = codec.digest(token);

        assertThat(encrypted).doesNotContain(token);
        assertThat(digest).hasSize(64).doesNotContain(token);
        assertThat(codec.decrypt(encrypted)).contains(token);
        assertThat(codec.matchesDigest(token, digest)).isTrue();
    }

    @Test
    void rejectsTamperedCiphertextAndMalformedTokens() {
        String encrypted = codec.encrypt(codec.generate());
        char replacement = encrypted.endsWith("A") ? 'B' : 'A';
        String tampered = encrypted.substring(0, encrypted.length() - 1) + replacement;

        assertThat(codec.decrypt(tampered)).isEmpty();
        assertThatThrownBy(() -> codec.requireValid("../secret"))
                .isInstanceOf(InvalidPublicShareTokenException.class);
        assertThatThrownBy(() -> codec.requireValid("a".repeat(10_000)))
                .isInstanceOf(InvalidPublicShareTokenException.class);
    }

    @Test
    void acceptsLegacyUuidTokensForTransparentMigration() {
        assertThat(codec.isLegacy("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")).isTrue();
        assertThat(codec.requireValid("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))
                .hasSize(32);
    }

    private PublicPortfolioSecurityProperties properties() {
        return new PublicPortfolioSecurityProperties(
                KEY, Duration.ofMinutes(5), 2, Duration.ofMillis(100),
                10 * 1024 * 1024, List.of("http://localhost:8082"));
    }
}
