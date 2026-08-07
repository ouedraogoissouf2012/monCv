package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicShareSettingsRequest;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import com.cvmobile.service.cv.CvFinder;
import com.cvmobile.service.cv.CvShareService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Verifie les invariants de securite du partage public : le token clair n'est
 * jamais persiste (seuls le chiffre et l'empreinte le sont), la desactivation
 * revoque les deux, et couper le partage-contact coupe aussi les telechargements.
 *
 * Cible {@link CvShareService} — proprietaire de cette logique depuis la
 * decomposition de {@code CvService} (issue #254) — via ses collaborateurs
 * mockes, le lookup passant par {@link CvFinder}.
 */
@ExtendWith(MockitoExtension.class)
class CvShareSecurityServiceTest {
    @Mock CvRepository cvRepository;
    @Mock CvMapper cvMapper;
    @Mock PublicShareTokenCodec tokenCodec;
    @Mock CvFinder cvFinder;
    @InjectMocks CvShareService service;

    @Test
    void storesOnlyEncryptedAndHashedRepresentationsOfANewToken() {
        Cv cv = Cv.builder().id(12L).titre("CV").build();
        when(cvFinder.findByIdAndUserId(12L, 4L)).thenReturn(cv);
        when(tokenCodec.generate()).thenReturn("raw-token");
        when(tokenCodec.digest("raw-token")).thenReturn("token-digest");
        when(tokenCodec.encrypt("raw-token")).thenReturn("encrypted-token");
        when(cvRepository.save(cv)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(CvResponse.builder().build());

        CvResponse response = service.generateShareToken(12L, 4L);

        assertThat(response.getPublicToken()).isEqualTo("raw-token");
        assertThat(cv.getPublicToken()).isEqualTo("encrypted-token");
        assertThat(cv.getPublicTokenHash()).isEqualTo("token-digest");
    }

    @Test
    void reusesAnAuthenticatedEncryptedTokenWithoutRotatingTheLink() {
        Cv cv = Cv.builder().id(12L).titre("CV")
                .publicToken("encrypted-token").publicTokenHash("token-digest").build();
        when(cvFinder.findByIdAndUserId(12L, 4L)).thenReturn(cv);
        when(tokenCodec.decrypt("encrypted-token")).thenReturn(Optional.of("raw-token"));
        when(tokenCodec.matchesDigest("raw-token", "token-digest")).thenReturn(true);
        when(cvRepository.save(cv)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(CvResponse.builder().build());

        CvResponse response = service.generateShareToken(12L, 4L);

        assertThat(response.getPublicToken()).isEqualTo("raw-token");
        verify(tokenCodec).decrypt("encrypted-token");
    }

    @Test
    void deactivationRevokesBothLookupAndRecoveryMaterial() {
        Cv cv = Cv.builder().id(12L).titre("CV")
                .publicToken("encrypted-token").publicTokenHash("token-digest").build();
        when(cvFinder.findByIdAndUserId(12L, 4L)).thenReturn(cv);
        when(cvRepository.save(cv)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(CvResponse.builder().build());

        service.deactivateShare(12L, 4L);

        assertThat(cv.getPublicToken()).isNull();
        assertThat(cv.getPublicTokenHash()).isNull();
    }

    @Test
    void downloadsCannotRemainEnabledWhenContactSharingIsDisabled() {
        Cv cv = Cv.builder().id(12L).titre("CV")
                .publicToken("encrypted-token").publicTokenHash("token-digest").build();
        PublicShareSettingsRequest request = new PublicShareSettingsRequest();
        request.setContactEnabled(false);
        request.setDownloadsEnabled(true);
        when(cvFinder.findByIdAndUserId(12L, 4L)).thenReturn(cv);
        when(tokenCodec.decrypt("encrypted-token")).thenReturn(Optional.of("raw-token"));
        when(tokenCodec.matchesDigest("raw-token", "token-digest")).thenReturn(true);
        when(cvRepository.save(cv)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(CvResponse.builder().build());

        CvResponse response = service.updateShareSettings(12L, request, 4L);

        assertThat(cv.isPublicContactEnabled()).isFalse();
        assertThat(cv.isPublicDownloadsEnabled()).isFalse();
        assertThat(response.getPublicToken()).isEqualTo("raw-token");
    }
}
