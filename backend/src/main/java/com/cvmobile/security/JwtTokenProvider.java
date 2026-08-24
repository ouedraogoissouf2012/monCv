package com.cvmobile.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class JwtTokenProvider {

    private static final String TOKEN_TYPE_CLAIM = "token_type";
    private static final String TOKEN_VERSION_CLAIM = "token_version";
    private static final String ACCESS_TOKEN = "access";
    private static final String REFRESH_TOKEN = "refresh";

    /** Generation pretee aux jetons emis avant l'introduction du claim (#505). */
    private static final int LEGACY_TOKEN_VERSION = 0;

    static final int MIN_SECRET_LENGTH = 64;
    static final double MIN_SECRET_ENTROPY = 4.0;
    private static final Set<String> BLOCKED_SECRETS = Set.of(
            "cvMobileDevSecretKey2024AtLeast32CharsLong!");

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration;

    @PostConstruct
    void validateSecret() {
        if (jwtSecret == null || jwtSecret.isBlank()) {
            throw new IllegalStateException("JWT_SECRET environment variable is required");
        }
        if (BLOCKED_SECRETS.contains(jwtSecret)) {
            throw new IllegalStateException("JWT_SECRET must not be a known development key");
        }
        if (jwtSecret.length() < MIN_SECRET_LENGTH) {
            throw new IllegalStateException(
                    "JWT_SECRET must be at least " + MIN_SECRET_LENGTH + " characters");
        }
        if (shannonEntropy(jwtSecret) <= MIN_SECRET_ENTROPY) {
            throw new IllegalStateException("JWT_SECRET entropy must be greater than 4.0 bits per character");
        }
    }

    static double shannonEntropy(String value) {
        if (value == null || value.isEmpty()) return 0.0;
        Map<Integer, Long> frequencies = value.codePoints().boxed()
                .collect(Collectors.groupingBy(Function.identity(), Collectors.counting()));
        double length = value.codePointCount(0, value.length());
        return frequencies.values().stream().mapToDouble(count -> {
            double probability = count / length;
            return -probability * (Math.log(probability) / Math.log(2));
        }).sum();
    }

    private SecretKey getSigningKey() {
        byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    /**
     * Emet un access token pour la generation de sessions {@code tokenVersion}
     * du compte (issue #505). Aucune surcharge sans generation n'est exposee :
     * un jeton non revocable ne doit pas pouvoir etre emis par inadvertance.
     */
    public String generateToken(String email, int tokenVersion) {
        return buildToken(email, ACCESS_TOKEN, tokenVersion, jwtExpiration);
    }

    /** Emet un refresh token pour la generation de sessions {@code tokenVersion}. */
    public String generateRefreshToken(String email, int tokenVersion) {
        return buildToken(email, REFRESH_TOKEN, tokenVersion, refreshExpiration);
    }

    private String buildToken(String email, String tokenType, int tokenVersion, long lifetimeMillis) {
        Date now = new Date();

        return Jwts.builder()
                .subject(email)
                .claim(TOKEN_TYPE_CLAIM, tokenType)
                .claim(TOKEN_VERSION_CLAIM, tokenVersion)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + lifetimeMillis))
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * Verifie que le jeton appartient encore a la generation de sessions courante
     * du compte (issue #505). Implementation unique de la regle de revocation :
     * {@link JwtAuthenticationFilter} l'applique aux access tokens, et
     * {@code AuthService#refreshToken} aux refresh tokens — ces derniers
     * n'empruntent pas le filtre puisque {@code /api/auth/refresh} est permitAll.
     *
     * <p>Un jeton emis avant la migration V19 ne porte pas le claim : on lui prete
     * la generation 0, valeur initiale de tout compte. La garantie de revocation
     * reste entiere, toute revocation portant le compte a une generation &gt;= 1 —
     * ces jetons anterieurs sont donc rejetes des la premiere revocation. Cette
     * branche de compatibilite pourra tomber une fois ecoulee la duree de vie des
     * refresh tokens apres deploiement (7 jours en production).
     *
     * @param token          jeton signe a verifier
     * @param currentVersion generation de sessions actuellement persistee pour le compte
     * @return {@code true} si le jeton est exploitable pour ce compte
     */
    public boolean matchesTokenVersion(String token, int currentVersion) {
        Claims claims = parseClaims(token);
        if (claims == null) {
            return false;
        }

        Object tokenVersion = claims.get(TOKEN_VERSION_CLAIM);
        if (tokenVersion == null) {
            return currentVersion == LEGACY_TOKEN_VERSION;
        }
        return tokenVersion instanceof Number version && version.intValue() == currentVersion;
    }

    public String getEmailFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.getSubject();
    }

    public boolean validateToken(String token) {
        return parseClaims(token) != null;
    }

    public boolean validateAccessToken(String token) {
        return hasTokenType(token, ACCESS_TOKEN);
    }

    public boolean validateRefreshToken(String token) {
        return hasTokenType(token, REFRESH_TOKEN);
    }

    private boolean hasTokenType(String token, String expectedType) {
        Claims claims = parseClaims(token);
        return claims != null && expectedType.equals(claims.get(TOKEN_TYPE_CLAIM, String.class));
    }

    private Claims parseClaims(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (JwtException | IllegalArgumentException e) {
            return null;
        }
    }
}
