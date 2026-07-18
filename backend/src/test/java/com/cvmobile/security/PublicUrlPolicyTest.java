package com.cvmobile.security;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PublicUrlPolicyTest {
    private static final String FILENAME =
            "123e4567-e89b-12d3-a456-426614174000.jpg";
    private final PublicUrlPolicy policy = new PublicUrlPolicy(
            new PublicPortfolioSecurityProperties(
                    "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=",
                    Duration.ofMinutes(5), 2, Duration.ofMillis(100),
                    10 * 1024 * 1024, List.of("https://api.example.test")));

    @Test
    void acceptsOnlyConfiguredUploadOriginsAndExtractsOpaqueFilename() {
        String approved = "https://api.example.test/api/uploads/photos/" + FILENAME;

        assertThat(policy.sanitizeMediaUrl(approved)).isEqualTo(approved);
        assertThat(policy.extractPhotoFilename(approved)).contains(FILENAME);
        assertThat(policy.sanitizeMediaUrl("/api/uploads/photos/" + FILENAME))
                .isEqualTo("/api/uploads/photos/" + FILENAME);
    }

    @Test
    void rejectsTrackersQueriesUserInfoAndPathConfusion() {
        assertThat(policy.sanitizeMediaUrl(
                "https://tracker.example/api/uploads/photos/" + FILENAME)).isNull();
        assertThat(policy.sanitizeMediaUrl(
                "https://api.example.test/api/uploads/photos/" + FILENAME + "?track=1")).isNull();
        assertThat(policy.sanitizeMediaUrl(
                "https://user@api.example.test/api/uploads/photos/" + FILENAME)).isNull();
        assertThat(policy.sanitizeMediaUrl("/api/uploads/photos/../../secret.jpg")).isNull();
        assertThat(policy.sanitizeExternalUrl("javascript:alert(1)")).isNull();
    }
}
