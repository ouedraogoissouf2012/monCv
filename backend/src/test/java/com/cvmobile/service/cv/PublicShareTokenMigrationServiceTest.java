package com.cvmobile.service.cv;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;

import java.time.Duration;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PublicShareTokenMigrationServiceTest {
    private final CvRepository repository = mock(CvRepository.class);
    private final PublicShareTokenCodec codec = new PublicShareTokenCodec(
            new PublicPortfolioSecurityProperties(
                    "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=",
                    Duration.ofMinutes(5), 2, Duration.ofMillis(100),
                    10 * 1024 * 1024, List.of()));
    private final PublicShareTokenMigrationService service =
            new PublicShareTokenMigrationService(repository, codec);

    @Test
    void encryptsLegacyPlaintextAndCreatesLookupDigest() {
        String rawToken = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        Cv cv = Cv.builder().id(1L).publicToken(rawToken).build();
        when(repository.findLegacyPublicTokens(any(Pageable.class))).thenReturn(List.of(cv));

        assertThat(service.migrateNextBatch()).isEqualTo(1);

        assertThat(cv.getPublicTokenHash()).isEqualTo(codec.digest(rawToken));
        assertThat(cv.getPublicToken()).isNotEqualTo(rawToken);
        assertThat(codec.decrypt(cv.getPublicToken())).contains(rawToken);
    }

    @Test
    void disablesCorruptedLegacyLinksInsteadOfLeavingThemPublic() {
        Cv cv = Cv.builder().id(2L).publicToken("../corrupted")
                .publicDownloadsEnabled(true).publicContactEnabled(true).build();
        when(repository.findLegacyPublicTokens(any(Pageable.class))).thenReturn(List.of(cv));

        service.migrateNextBatch();

        assertThat(cv.getPublicToken()).isNull();
        assertThat(cv.getPublicTokenHash()).isNull();
        assertThat(cv.isPublicDownloadsEnabled()).isFalse();
        assertThat(cv.isPublicContactEnabled()).isFalse();
    }
}
