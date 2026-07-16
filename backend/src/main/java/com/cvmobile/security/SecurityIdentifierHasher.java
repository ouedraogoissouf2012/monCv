package com.cvmobile.security;

import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;

@Component
public final class SecurityIdentifierHasher {
    private static final int OUTPUT_BYTES = 16;
    private static final byte[] KEY_CONTEXT =
            "moncv/security-identifier/v1".getBytes(StandardCharsets.UTF_8);
    private final SecretKeySpec key;

    public SecurityIdentifierHasher(PublicShareTokenCodec tokenCodec) {
        this.key = new SecretKeySpec(deriveKey(tokenCodec.keyBytes()), "HmacSHA256");
    }

    public String hash(String purpose, String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(key);
            byte[] digest = mac.doFinal((purpose + "\0" + normalize(value))
                    .getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest, 0, OUTPUT_BYTES);
        } catch (Exception exception) {
            throw new IllegalStateException("HMAC-SHA256 indisponible", exception);
        }
    }

    private String normalize(String value) {
        if (value == null || value.isBlank()) return "unknown";
        return value.trim().toLowerCase(java.util.Locale.ROOT);
    }

    private byte[] deriveKey(byte[] masterKey) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(masterKey, "HmacSHA256"));
            return mac.doFinal(KEY_CONTEXT);
        } catch (Exception exception) {
            throw new IllegalStateException("Derivation HMAC-SHA256 indisponible", exception);
        }
    }
}
