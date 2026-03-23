package com.cvmobile.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

class JwtTokenProviderTest {

    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUp() {
        jwtTokenProvider = new JwtTokenProvider();
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtSecret",
                "TestSecretKeyForUnitTestsOnly1234567890ABCDEFGHIJ");
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtExpiration", 3600000L);
        ReflectionTestUtils.setField(jwtTokenProvider, "refreshExpiration", 86400000L);
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
