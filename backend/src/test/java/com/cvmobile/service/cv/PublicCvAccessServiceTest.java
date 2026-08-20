package com.cvmobile.service.cv;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import com.cvmobile.config.RateLimitProperties;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicCvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.PublicCvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.security.InvalidPublicShareTokenException;
import com.cvmobile.security.PublicShareTokenCodec;
import com.cvmobile.security.RateLimitResult;
import com.cvmobile.security.RateLimitService;
import com.cvmobile.security.SecurityIdentifierHasher;
import com.cvmobile.security.PublicUrlPolicy;
import com.cvmobile.service.PhotoService;
import com.cvmobile.service.notification.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.Duration;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PublicCvAccessServiceTest {
    @Mock CvRepository cvRepository;
    @Mock PublicCvMapper publicCvMapper;
    @Mock SecurityIdentifierHasher identifierHasher;
    @Mock RateLimitService rateLimitService;
    @Mock NotificationService notificationService;
    @Mock PublicUrlPolicy urlPolicy;
    @Mock PhotoService photoService;

    private PublicShareTokenCodec tokenCodec;
    private PublicPortfolioSecurityProperties securityProperties;

    @BeforeEach
    void setUp() {
        securityProperties = securityProperties();
        tokenCodec = new PublicShareTokenCodec(securityProperties);
    }

    @Test
    void returnsWhitelistedPortfolioAndUsesAtomicViewIncrement() {
        String token = tokenCodec.generate();
        Cv cv = cv();
        PublicCvResponse expected = response();
        when(cvRepository.findByPublicTokenHash(tokenCodec.digest(token)))
                .thenReturn(Optional.of(cv));
        when(publicCvMapper.toResponse(cv, null)).thenReturn(expected);
        when(identifierHasher.hash("public-view", "203.0.113.7"))
                .thenReturn("visitor-hash");
        when(cvRepository.incrementViewCount(12L)).thenReturn(1);

        PublicCvResponse result = service(false).getPortfolio(token, "203.0.113.7");

        assertThat(result).isSameAs(expected);
        verify(cvRepository).incrementViewCount(12L);
        verify(notificationService).notifyViewMilestone(cv);
        assertThat(cv.getViewCount()).isEqualTo(8);
    }

    @Test
    void notificationDedupDoesNotHideThePortfolio() {
        String token = tokenCodec.generate();
        Cv cv = cv();
        PublicCvResponse expected = response();
        when(cvRepository.findByPublicTokenHash(tokenCodec.digest(token)))
                .thenReturn(Optional.of(cv));
        when(publicCvMapper.toResponse(cv, null)).thenReturn(expected);
        when(identifierHasher.hash("public-view", "203.0.113.7"))
                .thenReturn("visitor-hash");
        when(cvRepository.incrementViewCount(12L)).thenReturn(1);
        org.mockito.Mockito.doThrow(new DataIntegrityViolationException("dup"))
                .when(notificationService).notifyViewMilestone(cv);

        PublicCvResponse result = service(false).getPortfolio(token, "203.0.113.7");

        assertThat(result).isSameAs(expected);
        verify(cvRepository).incrementViewCount(12L);
        assertThat(cv.getViewCount()).isEqualTo(8);
    }

    @Test
    void migratesLegacyPlaintextTokenWithoutChangingThePublicLink() {
        String token = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        Cv cv = cv();
        cv.setPublicToken(token);
        when(cvRepository.findByPublicTokenHash(tokenCodec.digest(token)))
                .thenReturn(Optional.empty());
        when(cvRepository.findByPublicToken(token)).thenReturn(Optional.of(cv));
        when(cvRepository.save(cv)).thenReturn(cv);
        when(publicCvMapper.toResponse(cv, null)).thenReturn(response());
        when(identifierHasher.hash("public-view", "unknown")).thenReturn("visitor-hash");

        service(false).getPortfolio(token, "unknown");

        assertThat(cv.getPublicTokenHash()).isEqualTo(tokenCodec.digest(token));
        assertThat(cv.getPublicToken()).isNotEqualTo(token);
        assertThat(tokenCodec.decrypt(cv.getPublicToken())).contains(token);
        verify(cvRepository).save(cv);
    }

    @Test
    void rejectsMalformedAndOversizedTokensBeforeAnyDatabaseQuery() {
        PublicCvAccessService service = service(false);

        assertThatThrownBy(() -> service.getPortfolio("../admin", "127.0.0.1"))
                .isInstanceOf(InvalidPublicShareTokenException.class);
        assertThatThrownBy(() -> service.getPortfolio("a".repeat(10_000), "127.0.0.1"))
                .isInstanceOf(InvalidPublicShareTokenException.class);
        verifyNoInteractions(cvRepository);
    }

    @Test
    void distributedDeduplicationPreventsRepeatedViewWrites() {
        String token = tokenCodec.generate();
        Cv cv = cv();
        when(cvRepository.findByPublicTokenHash(tokenCodec.digest(token)))
                .thenReturn(Optional.of(cv));
        when(publicCvMapper.toResponse(cv, null)).thenReturn(response());
        when(identifierHasher.hash("public-view", "203.0.113.7"))
                .thenReturn("visitor-hash");
        when(rateLimitService.consume(
                "public-view:12:visitor-hash", 1, Duration.ofMinutes(5)))
                .thenReturn(RateLimitResult.rejected(Duration.ofMinutes(4)));

        service(true).getPortfolio(token, "203.0.113.7");

        verify(cvRepository, never()).incrementViewCount(12L);
    }

    @Test
    void returnsMappedDocumentSourcesWhenDownloadsAreEnabled() {
        Cv cv = cv();
        cv.setPublicDownloadsEnabled(true);
        String token = tokenFor(cv);
        CvResponse pdfResponse = mock(CvResponse.class);
        when(publicCvMapper.toDocumentResponse(cv)).thenReturn(pdfResponse);
        when(publicCvMapper.toDocumentModel(cv)).thenReturn(cv);

        PublicCvAccessService.PdfSource pdf = service(false).getPdfSource(token);
        PublicCvAccessService.DocxSource docx = service(false).getDocxSource(token);

        assertThat(pdf.cvId()).isEqualTo(12L);
        assertThat(pdf.cv()).isSameAs(pdfResponse);
        assertThat(docx.cvId()).isEqualTo(12L);
        assertThat(docx.cv()).isSameAs(cv);
    }

    @Test
    void hidesDocumentEndpointsWhenDownloadsAreDisabled() {
        Cv cv = cv();
        String token = tokenFor(cv);
        PublicCvAccessService accessService = service(false);

        assertThatThrownBy(() -> accessService.getPdfSource(token))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> accessService.getDocxSource(token))
                .isInstanceOf(ResourceNotFoundException.class);
        verifyNoInteractions(publicCvMapper);
    }

    @Test
    void loadsOnlyTheTokenOwnersPhotoAndHidesStorageMisses() {
        Cv cv = cv();
        cv.setPersonalInfo(PersonalInfo.builder().photoUrl("/api/photos/photo.png").build());
        String token = tokenFor(cv);
        var storedPhoto = new com.cvmobile.service.FileStorageService.StoredPhoto(
                new ByteArrayResource(new byte[] {1, 2, 3}), "image/png", 3L);
        when(urlPolicy.extractPhotoFilename("/api/photos/photo.png"))
                .thenReturn(Optional.of("photo.png"));
        when(photoService.loadOwned("photo.png", 4L)).thenReturn(storedPhoto);
        PublicCvAccessService accessService = service(false);

        assertThat(accessService.getPhoto(token)).isSameAs(storedPhoto);

        when(photoService.loadOwned("photo.png", 4L))
                .thenThrow(new ResourceNotFoundException("missing"));
        assertThatThrownBy(() -> accessService.getPhoto(token))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Lien de partage invalide");
    }

    @Test
    void exposesOnlyTokenScopedPhotoUrls() {
        Cv cv = cv();
        cv.setPersonalInfo(PersonalInfo.builder().photoUrl("/api/photos/photo.png").build());
        String token = tokenFor(cv);
        PublicCvResponse expected = response();
        when(urlPolicy.extractPhotoFilename("/api/photos/photo.png"))
                .thenReturn(Optional.of("photo.png"));
        when(publicCvMapper.toResponse(
                cv, "/api/cvs/public/" + token + "/photo"))
                .thenReturn(expected);
        when(identifierHasher.hash("public-view", "198.51.100.8"))
                .thenReturn("visitor-hash");

        assertThat(service(false).getPortfolio(token, "198.51.100.8"))
                .isSameAs(expected);
    }

    @Test
    void tracksDownloadAndShareCounters() {
        Cv cv = cv();
        String token = tokenFor(cv);
        PublicCvAccessService accessService = service(false);

        accessService.trackDownload(12L);
        accessService.trackShare(token);

        verify(cvRepository).incrementDownloadCount(12L);
        verify(cvRepository).incrementShareCount(12L);
    }

    private String tokenFor(Cv cv) {
        String token = tokenCodec.generate();
        when(cvRepository.findByPublicTokenHash(tokenCodec.digest(token)))
                .thenReturn(Optional.of(cv));
        return token;
    }

    private PublicCvAccessService service(boolean rateLimitEnabled) {
        return new PublicCvAccessService(
                cvRepository, publicCvMapper, tokenCodec,
                identifierHasher, rateLimitService, rateLimitProperties(rateLimitEnabled),
                securityProperties, notificationService, urlPolicy, photoService);
    }

    private Cv cv() {
        return Cv.builder().id(12L).titre("CV Produit").viewCount(7)
                .user(User.builder().id(4L).build()).build();
    }

    private PublicCvResponse response() {
        return new PublicCvResponse(
                "CV Produit", null, List.of(), List.of(), List.of(), List.of(),
                List.of(), List.of(), new PublicCvResponse.Style("moderne", 1L, "Roboto"),
                false, false);
    }

    private PublicPortfolioSecurityProperties securityProperties() {
        return new PublicPortfolioSecurityProperties(
                "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=",
                Duration.ofMinutes(5), 2, Duration.ofMillis(100),
                10 * 1024 * 1024, List.of());
    }

    private RateLimitProperties rateLimitProperties(boolean enabled) {
        return new RateLimitProperties(
                enabled, true, 10, Duration.ofMinutes(1),
                20, Duration.ofHours(1), 5, Duration.ofHours(1),
                60, Duration.ofMinutes(1), 6, Duration.ofMinutes(1),
                20, Duration.ofMinutes(1), "redis://unused", "test:");
    }
}
