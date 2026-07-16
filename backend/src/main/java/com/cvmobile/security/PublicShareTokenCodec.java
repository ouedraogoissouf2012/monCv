package com.cvmobile.security;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.regex.Pattern;

@Component
public final class PublicShareTokenCodec {
    private static final Pattern TOKEN_PATTERN = Pattern.compile(
            "(?:[0-9a-fA-F]{32}|[A-Za-z0-9_-]{43})");
    private static final int TOKEN_BYTES = 32;
    private static final int NONCE_BYTES = 12;
    private static final int GCM_TAG_BITS = 128;
    private static final byte FORMAT_VERSION = 1;

    private final SecureRandom secureRandom = new SecureRandom();
    private final SecretKeySpec encryptionKey;

    public PublicShareTokenCodec(PublicPortfolioSecurityProperties properties) {
        byte[] key = decodeKey(properties.encryptionKey());
        this.encryptionKey = new SecretKeySpec(key, "AES");
    }

    public String generate() {
        byte[] token = new byte[TOKEN_BYTES];
        secureRandom.nextBytes(token);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(token);
    }

    public String requireValid(String token) {
        if (token == null || !TOKEN_PATTERN.matcher(token).matches()) {
            throw new InvalidPublicShareTokenException();
        }
        return token;
    }

    public boolean isLegacy(String token) {
        return token != null && token.length() == 32
                && TOKEN_PATTERN.matcher(token).matches();
    }

    public String digest(String token) {
        String validToken = requireValid(token);
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest(validToken.getBytes(StandardCharsets.US_ASCII));
            return HexFormat.of().formatHex(hash);
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("SHA-256 indisponible", exception);
        }
    }

    public boolean matchesDigest(String token, String expectedDigest) {
        if (expectedDigest == null) return false;
        byte[] actual = digest(token).getBytes(StandardCharsets.US_ASCII);
        byte[] expected = expectedDigest.getBytes(StandardCharsets.US_ASCII);
        return MessageDigest.isEqual(actual, expected);
    }

    public String encrypt(String token) {
        String validToken = requireValid(token);
        byte[] nonce = new byte[NONCE_BYTES];
        secureRandom.nextBytes(nonce);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, encryptionKey,
                    new GCMParameterSpec(GCM_TAG_BITS, nonce));
            cipher.updateAAD(new byte[]{FORMAT_VERSION});
            byte[] ciphertext = cipher.doFinal(
                    validToken.getBytes(StandardCharsets.US_ASCII));
            ByteBuffer payload = ByteBuffer.allocate(1 + nonce.length + ciphertext.length);
            payload.put(FORMAT_VERSION).put(nonce).put(ciphertext);
            return Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(payload.array());
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("Chiffrement du lien public impossible", exception);
        }
    }

    public Optional<String> decrypt(String encryptedToken) {
        if (encryptedToken == null || encryptedToken.isBlank()) return Optional.empty();
        try {
            byte[] payload = Base64.getUrlDecoder().decode(encryptedToken);
            if (payload.length <= 1 + NONCE_BYTES || payload[0] != FORMAT_VERSION) {
                return Optional.empty();
            }
            byte[] nonce = new byte[NONCE_BYTES];
            System.arraycopy(payload, 1, nonce, 0, nonce.length);
            byte[] ciphertext = new byte[payload.length - 1 - nonce.length];
            System.arraycopy(payload, 1 + nonce.length, ciphertext, 0, ciphertext.length);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, encryptionKey,
                    new GCMParameterSpec(GCM_TAG_BITS, nonce));
            cipher.updateAAD(new byte[]{FORMAT_VERSION});
            String token = new String(cipher.doFinal(ciphertext), StandardCharsets.US_ASCII);
            return TOKEN_PATTERN.matcher(token).matches()
                    ? Optional.of(token)
                    : Optional.empty();
        } catch (GeneralSecurityException | IllegalArgumentException exception) {
            return Optional.empty();
        }
    }

    byte[] keyBytes() {
        return encryptionKey.getEncoded().clone();
    }

    private static byte[] decodeKey(String value) {
        try {
            byte[] key = Base64.getDecoder().decode(value);
            if (key.length != 32) {
                throw new IllegalArgumentException(
                        "PUBLIC_LINK_ENCRYPTION_KEY doit contenir exactement 32 octets");
            }
            return key;
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException(
                    "PUBLIC_LINK_ENCRYPTION_KEY doit etre une valeur Base64 de 32 octets",
                    exception);
        }
    }
}
