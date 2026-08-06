package com.cvmobile.service.cv;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.security.PublicShareTokenCodec;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CvShareServiceTest {

    @Mock private CvRepository cvRepository;
    @Mock private CvMapper cvMapper;
    @Mock private PublicShareTokenCodec publicShareTokenCodec;
    @Mock private CvFinder cvFinder;

    @InjectMocks
    private CvShareService shareService;

    @Test
    void generateShareToken_sansTokenExistant_enCreeUnNouveau() {
        Cv cv = Cv.builder().id(10L).titre("CV").build();
        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(cv);
        when(publicShareTokenCodec.generate()).thenReturn("raw-token");
        when(publicShareTokenCodec.digest("raw-token")).thenReturn("hash");
        when(publicShareTokenCodec.encrypt("raw-token")).thenReturn("encrypted");
        when(cvRepository.save(cv)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(CvResponse.builder().id(10L).build());

        CvResponse result = shareService.generateShareToken(10L, 1L);

        // Le token en clair est renvoye au client ; la version chiffree + le hash sont persistes.
        assertThat(result.getPublicToken()).isEqualTo("raw-token");
        assertThat(cv.getPublicToken()).isEqualTo("encrypted");
        assertThat(cv.getPublicTokenHash()).isEqualTo("hash");
    }

    @Test
    void deactivateShare_effaceTokenEtHash() {
        Cv cv = Cv.builder().id(10L).titre("CV")
                .publicToken("encrypted").publicTokenHash("hash").build();
        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(cv);
        when(cvRepository.save(cv)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(CvResponse.builder().id(10L).build());

        shareService.deactivateShare(10L, 1L);

        assertThat(cv.getPublicToken()).isNull();
        assertThat(cv.getPublicTokenHash()).isNull();
    }
}
