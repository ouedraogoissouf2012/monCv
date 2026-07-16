package com.cvmobile.service.cv;

import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PublicShareTokenMigrationService {
    public static final int BATCH_SIZE = 100;

    private final CvRepository cvRepository;
    private final PublicShareTokenCodec tokenCodec;

    @Transactional
    public int migrateNextBatch() {
        List<Cv> links = cvRepository.findLegacyPublicTokens(PageRequest.of(0, BATCH_SIZE));
        for (Cv cv : links) migrateOrDisable(cv);
        return links.size();
    }

    private void migrateOrDisable(Cv cv) {
        String stored = cv.getPublicToken();
        try {
            String rawToken = tokenCodec.decrypt(stored)
                    .orElseGet(() -> tokenCodec.requireValid(stored));
            cv.setPublicTokenHash(tokenCodec.digest(rawToken));
            cv.setPublicToken(tokenCodec.encrypt(rawToken));
        } catch (RuntimeException exception) {
            cv.setPublicToken(null);
            cv.setPublicTokenHash(null);
            cv.setPublicDownloadsEnabled(false);
            cv.setPublicContactEnabled(false);
            log.warn("Lien public corrompu desactive pour cvId={}", cv.getId());
        }
    }
}
