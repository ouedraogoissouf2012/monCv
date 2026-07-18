package com.cvmobile.service.cv;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import com.cvmobile.config.RateLimitProperties;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicCvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.PublicCvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import com.cvmobile.security.PublicUrlPolicy;
import com.cvmobile.security.RateLimitResult;
import com.cvmobile.security.RateLimitService;
import com.cvmobile.security.SecurityIdentifierHasher;
import com.cvmobile.service.notification.NotificationService;
import com.cvmobile.service.FileStorageService;
import com.cvmobile.service.PhotoService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class PublicCvAccessService {
    private final CvRepository cvRepository;
    private final PublicCvMapper publicCvMapper;
    private final PublicShareTokenCodec tokenCodec;
    private final SecurityIdentifierHasher identifierHasher;
    private final RateLimitService rateLimitService;
    private final RateLimitProperties rateLimitProperties;
    private final PublicPortfolioSecurityProperties securityProperties;
    private final NotificationService notificationService;
    private final PublicUrlPolicy urlPolicy;
    private final PhotoService photoService;

    @Transactional
    public PublicCvResponse getPortfolio(String rawToken, String clientAddress) {
        Cv cv = findPublicCv(rawToken);
        String storedPhotoUrl = cv.getPersonalInfo() == null
                ? null : cv.getPersonalInfo().getPhotoUrl();
        String publicPhotoUrl = storedPhotoUrl == null ? null
                : urlPolicy.extractPhotoFilename(storedPhotoUrl)
                        .map(ignored -> "/api/cvs/public/"
                                + tokenCodec.requireValid(rawToken) + "/photo")
                        .orElse(null);
        PublicCvResponse response = publicCvMapper.toResponse(cv, publicPhotoUrl);
        trackViewBestEffort(cv, clientAddress);
        return response;
    }

    @Transactional
    public PdfSource getPdfSource(String rawToken) {
        Cv cv = findPublicCv(rawToken);
        ensureDownloadsEnabled(cv);
        return new PdfSource(cv.getId(), publicCvMapper.toDocumentResponse(cv));
    }

    @Transactional
    public DocxSource getDocxSource(String rawToken) {
        Cv cv = findPublicCv(rawToken);
        ensureDownloadsEnabled(cv);
        return new DocxSource(cv.getId(), publicCvMapper.toDocumentModel(cv));
    }

    @Transactional
    public FileStorageService.StoredPhoto getPhoto(String rawToken) {
        Cv cv = findPublicCv(rawToken);
        String photoUrl = cv.getPersonalInfo() == null ? null : cv.getPersonalInfo().getPhotoUrl();
        String filename = urlPolicy.extractPhotoFilename(photoUrl).orElseThrow(this::invalidLink);
        try {
            return photoService.loadOwned(filename, cv.getUser().getId());
        } catch (ResourceNotFoundException exception) {
            throw invalidLink();
        }
    }

    @Transactional
    public void trackDownload(Long cvId) {
        cvRepository.incrementDownloadCount(cvId);
    }

    @Transactional
    public void trackShare(String rawToken) {
        Cv cv = findPublicCv(rawToken);
        cvRepository.incrementShareCount(cv.getId());
    }

    private Cv findPublicCv(String rawToken) {
        String token = tokenCodec.requireValid(rawToken);
        String digest = tokenCodec.digest(token);
        return cvRepository.findByPublicTokenHash(digest)
                .orElseGet(() -> migrateLegacyToken(token, digest));
    }

    private Cv migrateLegacyToken(String token, String digest) {
        if (!tokenCodec.isLegacy(token)) throw invalidLink();
        Cv cv = cvRepository.findByPublicToken(token).orElseThrow(this::invalidLink);
        cv.setPublicTokenHash(digest);
        cv.setPublicToken(tokenCodec.encrypt(token));
        return cvRepository.save(cv);
    }

    private void trackViewBestEffort(Cv cv, String clientAddress) {
        try {
            String fingerprint = identifierHasher.hash("public-view", clientAddress);
            boolean shouldCount = !rateLimitProperties.enabled()
                    || consumeViewQuota(cv.getId(), fingerprint).allowed();
            if (!shouldCount) return;
            cv.getUser().getId();
            int previousCount = cv.getViewCount();
            if (cvRepository.incrementViewCount(cv.getId()) == 1) {
                cv.setViewCount(previousCount + 1);
                notificationService.notifyViewMilestone(cv);
            }
        } catch (RuntimeException exception) {
            log.warn("Comptage de vue ignore pour cvId={}", cv.getId());
        }
    }

    private RateLimitResult consumeViewQuota(Long cvId, String fingerprint) {
        return rateLimitService.consume(
                "public-view:" + cvId + ":" + fingerprint,
                1,
                securityProperties.viewDeduplicationWindow());
    }

    private void ensureDownloadsEnabled(Cv cv) {
        if (!cv.isPublicDownloadsEnabled()) throw invalidLink();
    }

    private ResourceNotFoundException invalidLink() {
        return new ResourceNotFoundException("Lien de partage invalide ou expire");
    }

    public record PdfSource(Long cvId, CvResponse cv) {
    }

    public record DocxSource(Long cvId, Cv cv) {
    }
}
