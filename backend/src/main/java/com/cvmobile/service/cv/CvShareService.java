package com.cvmobile.service.cv;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicShareSettingsRequest;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Gestion du lien de partage public d'un CV par son proprietaire (issue #254) :
 * generation, regeneration, desactivation et parametres de partage.
 *
 * Extrait de {@code CvService}. Les methodes s'executent dans la transaction de
 * la facade appelante.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CvShareService {

    private final CvRepository cvRepository;
    private final CvMapper cvMapper;
    private final PublicShareTokenCodec publicShareTokenCodec;
    private final CvFinder cvFinder;

    public CvResponse generateShareToken(Long cvId, Long userId) {
        Cv cv = cvFinder.findByIdAndUserId(cvId, userId);
        String token = recoverActiveToken(cv);
        if (token == null) token = protectNewToken(cv);
        cv = cvRepository.save(cv);
        log.info("Lien de partage actif pour CV id={}", cvId);
        return shareResponse(cv, token);
    }

    public CvResponse regenerateShareToken(Long cvId, Long userId) {
        Cv cv = cvFinder.findByIdAndUserId(cvId, userId);
        String token = protectNewToken(cv);
        return shareResponse(cvRepository.save(cv), token);
    }

    public CvResponse deactivateShare(Long cvId, Long userId) {
        Cv cv = cvFinder.findByIdAndUserId(cvId, userId);
        cv.setPublicToken(null);
        cv.setPublicTokenHash(null);
        return cvMapper.toResponse(cvRepository.save(cv));
    }

    public CvResponse updateShareSettings(
            Long cvId, PublicShareSettingsRequest request, Long userId) {
        Cv cv = cvFinder.findByIdAndUserId(cvId, userId);
        cv.setPublicContactEnabled(request.isContactEnabled());
        cv.setPublicDownloadsEnabled(
                request.isDownloadsEnabled() && request.isContactEnabled());
        String token = recoverActiveToken(cv);
        if (token == null && (cv.getPublicTokenHash() != null
                || cv.getPublicToken() != null)) {
            token = protectNewToken(cv);
        }
        return shareResponse(cvRepository.save(cv), token);
    }

    private String recoverActiveToken(Cv cv) {
        if (cv.getPublicToken() == null) return null;
        if (cv.getPublicTokenHash() == null
                && publicShareTokenCodec.isLegacy(cv.getPublicToken())) {
            String legacyToken = cv.getPublicToken();
            cv.setPublicTokenHash(publicShareTokenCodec.digest(legacyToken));
            cv.setPublicToken(publicShareTokenCodec.encrypt(legacyToken));
            return legacyToken;
        }
        return publicShareTokenCodec.decrypt(cv.getPublicToken())
                .filter(token -> publicShareTokenCodec.matchesDigest(
                        token, cv.getPublicTokenHash()))
                .orElse(null);
    }

    private String protectNewToken(Cv cv) {
        String token = publicShareTokenCodec.generate();
        cv.setPublicTokenHash(publicShareTokenCodec.digest(token));
        cv.setPublicToken(publicShareTokenCodec.encrypt(token));
        return token;
    }

    private CvResponse shareResponse(Cv cv, String token) {
        CvResponse response = cvMapper.toResponse(cv);
        response.setPublicToken(token);
        return response;
    }
}
