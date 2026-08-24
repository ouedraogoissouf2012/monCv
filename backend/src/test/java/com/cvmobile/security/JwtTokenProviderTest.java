package com.cvmobile.security;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.charset.StandardCharsets;
import java.util.Date;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtTokenProviderTest {

    private static final String TEST_SECRET =
            "TestOnly-A7zQ9mK2xR8pL4vN6sT1wY5cD3fH0jU7eB9gM2qX8kP4rV6nC5sD8wZ1kP4";

    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUp() {
        jwtTokenProvider = new JwtTokenProvider();
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtSecret", TEST_SECRET);
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtExpiration", 3600000L);
        ReflectionTestUtils.setField(jwtTokenProvider, "refreshExpiration", 86400000L);
    }

    @Test
    void validateSecret_accepteUnSecretLongEtEntropique() {
        jwtTokenProvider.validateSecret();
        assertThat(JwtTokenProvider.shannonEntropy(TEST_SECRET)).isGreaterThan(4.0);
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
        String token = jwtTokenProvider.generateToken("test@example.com", 0);

        assertThat(token).isNotBlank();
        assertThat(jwtTokenProvider.validateToken(token)).isTrue();
        assertThat(jwtTokenProvider.validateAccessToken(token)).isTrue();
        assertThat(jwtTokenProvider.validateRefreshToken(token)).isFalse();
    }

    @Test
    void getEmailFromToken_devraitRetournerLEmailCorrect() {
        String email = "user@example.com";
        String token = jwtTokenProvider.generateToken(email, 0);

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
        String accessToken  = jwtTokenProvider.generateToken(email, 0);
        String refreshToken = jwtTokenProvider.generateRefreshToken(email, 0);

        assertThat(accessToken).isNotEqualTo(refreshToken);
        assertThat(jwtTokenProvider.getEmailFromToken(refreshToken)).isEqualTo(email);
        assertThat(jwtTokenProvider.validateRefreshToken(refreshToken)).isTrue();
        assertThat(jwtTokenProvider.validateAccessToken(refreshToken)).isFalse();
    }

    // ── Expiration & signature (T-1) ────────────────────────────────
    // Chemin de securite critique : un jeton perime ou mal signe DOIT etre
    // rejete. On force une expiration passee via une duree negative.

    @Test
    void validateToken_avecAccessTokenExpire_devraitRetournerFalse() {
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtExpiration", -1000L);
        String expired = jwtTokenProvider.generateToken("user@example.com", 0);

        assertThat(jwtTokenProvider.validateToken(expired)).isFalse();
        assertThat(jwtTokenProvider.validateAccessToken(expired)).isFalse();
        assertThat(jwtTokenProvider.validateRefreshToken(expired)).isFalse();
    }

    @Test
    void validateRefreshToken_avecRefreshExpire_devraitRetournerFalse() {
        ReflectionTestUtils.setField(jwtTokenProvider, "refreshExpiration", -1000L);
        String expired = jwtTokenProvider.generateRefreshToken("user@example.com", 0);

        assertThat(jwtTokenProvider.validateRefreshToken(expired)).isFalse();
        assertThat(jwtTokenProvider.validateToken(expired)).isFalse();
    }

    @Test
    void getEmailFromToken_avecTokenExpire_devraitLeverExpiredJwtException() {
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtExpiration", -1000L);
        String expired = jwtTokenProvider.generateToken("user@example.com", 0);

        assertThatThrownBy(() -> jwtTokenProvider.getEmailFromToken(expired))
                .isInstanceOf(ExpiredJwtException.class);
    }

    // ── Generation de sessions / revocation (#505) ──────────────────
    // La regle de revocation vit ici et nulle part ailleurs : un jeton n'est
    // exploitable que s'il porte la generation courante du compte.

    @Test
    void matchesTokenVersion_memeGeneration_devraitRetournerTrue() {
        assertThat(jwtTokenProvider.matchesTokenVersion(
                jwtTokenProvider.generateToken("user@example.com", 7), 7)).isTrue();
        assertThat(jwtTokenProvider.matchesTokenVersion(
                jwtTokenProvider.generateRefreshToken("user@example.com", 7), 7)).isTrue();
    }

    @Test
    void matchesTokenVersion_generationRevoquee_devraitRetournerFalse() {
        // Le compte est passe a la generation 8 (deconnexion / reinitialisation) :
        // access ET refresh emis en generation 7 doivent tomber.
        String access = jwtTokenProvider.generateToken("user@example.com", 7);
        String refresh = jwtTokenProvider.generateRefreshToken("user@example.com", 7);

        assertThat(jwtTokenProvider.matchesTokenVersion(access, 8)).isFalse();
        assertThat(jwtTokenProvider.matchesTokenVersion(refresh, 8)).isFalse();
        // Le jeton reste par ailleurs valide et bien type : seule la generation le disqualifie.
        assertThat(jwtTokenProvider.validateAccessToken(access)).isTrue();
        assertThat(jwtTokenProvider.validateRefreshToken(refresh)).isTrue();
    }

    @Test
    void matchesTokenVersion_jetonInvalideOuExpire_devraitRetournerFalse() {
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtExpiration", -1000L);
        String expired = jwtTokenProvider.generateToken("user@example.com", 0);

        assertThat(jwtTokenProvider.matchesTokenVersion(expired, 0)).isFalse();
        assertThat(jwtTokenProvider.matchesTokenVersion("token.invalide.xxx", 0)).isFalse();
    }

    @Test
    void matchesTokenVersion_jetonAnterieurSansClaim_vautLaGenerationZero() {
        // Compatibilite (V19) : les jetons emis avant l'introduction du claim ne
        // portent pas de generation. On leur prete la generation 0 — valeur initiale
        // de tout compte — donc ils restent acceptes tant qu'aucune revocation n'a eu
        // lieu, et tombent des la premiere (generation >= 1).
        String legacy = Jwts.builder()
                .subject("user@example.com")
                .claim("token_type", "access")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 3600000L))
                .signWith(Keys.hmacShaKeyFor(TEST_SECRET.getBytes(StandardCharsets.UTF_8)))
                .compact();

        assertThat(jwtTokenProvider.validateAccessToken(legacy)).isTrue();
        assertThat(jwtTokenProvider.matchesTokenVersion(legacy, 0)).isTrue();
        assertThat(jwtTokenProvider.matchesTokenVersion(legacy, 1)).isFalse();
    }

    @Test
    void validateToken_avecMauvaiseSignature_devraitRetournerFalse() {
        String token = jwtTokenProvider.generateToken("user@example.com", 0);

        // Meme email, mais un secret different -> signature invalide.
        JwtTokenProvider other = new JwtTokenProvider();
        ReflectionTestUtils.setField(other, "jwtSecret",
                "OtherKey-Z9yP2mK7xR4pL8vN1sT6wY3cD5fH0jU9eB2gM7qX4kP1rV8nC6sD3wZ5kP0");
        ReflectionTestUtils.setField(other, "jwtExpiration", 3600000L);
        ReflectionTestUtils.setField(other, "refreshExpiration", 86400000L);

        assertThat(other.validateToken(token)).isFalse();
        assertThat(other.validateAccessToken(token)).isFalse();
        assertThatThrownBy(() -> other.getEmailFromToken(token))
                .isInstanceOf(JwtException.class);
    }
}
