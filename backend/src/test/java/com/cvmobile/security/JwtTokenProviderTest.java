package com.cvmobile.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtTokenProviderTest {

    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUp() {
        jwtTokenProvider = new JwtTokenProvider();
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtSecret",
                "TestOnly-A7zQ9mK2xR8pL4vN6sT1wY5cD3fH0jU7eB9gM2qX8kP4rV6nC5sD8wZ1kP4");
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtExpiration", 3600000L);
        ReflectionTestUtils.setField(jwtTokenProvider, "refreshExpiration", 86400000L);
    }

    @Test
    void validateSecret_accepteUnSecretLongEtEntropique() {
        jwtTokenProvider.validateSecret();
        assertThat(JwtTokenProvider.shannonEntropy(
                "TestOnly-A7zQ9mK2xR8pL4vN6sT1wY5cD3fH0jU7eB9gM2qX8kP4rV6nC5sD8wZ1kP4"))
                .isGreaterThan(4.0);
    }

    @Test
    void validateSecret_refuseUnSecretNull() {
        assertInvalidSecret(null, "required");
    }

    @Test
    void validateSecret_refuseUnSecretVide() {
        assertInvalidSecret("   ", "required");
    }

    @Test
    void validateSecret_refuseUnSecretCourt() {
        assertInvalidSecret("Short-A7zQ9mK2xR8p", "at least 64");
    }

    @Test
    void validateSecret_refuseLAncienneCleDev() {
        assertInvalidSecret("cvMobileDevSecretKey2024AtLeast32CharsLong!", "known development key");
    }

    @Test
    void validateSecret_refuseUnSecretLongMaisPrevisible() {
        assertInvalidSecret("a".repeat(80), "entropy");
    }

    private void assertInvalidSecret(String value, String message) {
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtSecret", value);
        assertThatThrownBy(jwtTokenProvider::validateSecret)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining(message);
    }

    @Test
    void generateToken_devraitRetournerUnTokenValide() {
        String token = jwtTokenProvider.generateToken("test@example.com");

        assertThat(token).isNotBlank();
        assertThat(jwtTokenProvider.validateToken(token)).isTrue();
    }

    @Test
    void getEmailFromToken_devraitRetournerLEmailCorrect() {
        String email = "user@example.com";
        String token = jwtTokenProvider.generateToken(email);

        assertThat(jwtTokenProvider.getEmailFromToken(token)).isEqualTo(email);
    }

    @Test
    void validateToken_avecTokenInvalide_devraitRetournerFalse() {
        assertThat(jwtTokenProvider.validateToken("token.invalide.xxx")).isFalse();
    }

    @Test
    void validateToken_avecTokenVide_devraitRetournerFalse() {
        assertThat(jwtTokenProvider.validateToken("")).isFalse();
    }

    @Test
    void generateRefreshToken_devraitEtreDistinctDuAccessToken() {
        String email = "user@example.com";
        String accessToken  = jwtTokenProvider.generateToken(email);
        String refreshToken = jwtTokenProvider.generateRefreshToken(email);

        assertThat(accessToken).isNotEqualTo(refreshToken);
        assertThat(jwtTokenProvider.getEmailFromToken(refreshToken)).isEqualTo(email);
    }
}
