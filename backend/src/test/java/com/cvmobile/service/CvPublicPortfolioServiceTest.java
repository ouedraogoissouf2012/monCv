package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicShareSettingsRequest;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.User;
import com.cvmobile.observability.BusinessMetrics;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.CvViewRepository;
import com.cvmobile.service.ai.IEnhancementService;
import com.cvmobile.service.notification.NotificationService;
import com.cvmobile.service.user.IUserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class CvPublicPortfolioServiceTest {

    @Mock CvRepository cvRepository;
    @Mock CvViewRepository cvViewRepository;
    @Mock IUserService userService;
    @Mock CvMapper cvMapper;
    @Mock IEnhancementService enhancementService;
    @Mock NotificationService notificationService;
    @Mock BusinessMetrics businessMetrics;

    @InjectMocks CvService service;

    private Cv cv;

    @BeforeEach
    void setUp() {
        cv = Cv.builder()
                .id(12L)
                .titre("CV Produit")
                .user(User.builder().id(4L).build())
                .publicToken("public-token")
                .personalInfo(PersonalInfo.builder()
                        .email("candidate@example.com")
                        .telephone("+22501020304")
                        .adresse("Rue privee")
                        .codePostal("00225")
                        .ville("Abidjan")
                        .build())
                .viewCount(7)
                .downloadCount(2)
                .shareCount(3)
                .build();
    }

    @Test
    void publicResponseRedactsPrivateContactAndOwnerAnalytics() {
        CvResponse.PersonalInfoDto info = CvResponse.PersonalInfoDto.builder()
                .email("candidate@example.com")
                .telephone("+22501020304")
                .adresse("Rue privee")
                .codePostal("00225")
                .ville("Abidjan")
                .build();
        CvResponse response = CvResponse.builder()
                .id(12L)
                .personalInfo(info)
                .publicToken("public-token")
                .downloadCount(2)
                .shareCount(3)
                .build();
        when(cvRepository.findByPublicToken("public-token"))
                .thenReturn(Optional.of(cv));
        when(cvMapper.toResponse(cv)).thenReturn(response);

        CvResponse result = service.getCvByPublicToken("public-token");

        assertThat(result.getPersonalInfo().getEmail()).isNull();
        assertThat(result.getPersonalInfo().getTelephone()).isNull();
        assertThat(result.getPersonalInfo().getAdresse()).isNull();
        assertThat(result.getPersonalInfo().getCodePostal()).isNull();
        assertThat(result.getPersonalInfo().getVille()).isEqualTo("Abidjan");
        assertThat(result.getPublicToken()).isNull();
        assertThat(result.getDownloadCount()).isZero();
        assertThat(result.getShareCount()).isZero();
    }

    @Test
    void downloadsRequireExplicitContactAuthorization() {
        PublicShareSettingsRequest request = new PublicShareSettingsRequest();
        request.setDownloadsEnabled(true);
        request.setContactEnabled(false);
        when(cvRepository.findByIdAndUserId(12L, 4L))
                .thenReturn(Optional.of(cv));
        when(cvRepository.save(any(Cv.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(CvResponse.builder().build());

        service.updateShareSettings(12L, request, 4L);

        assertThat(cv.isPublicContactEnabled()).isFalse();
        assertThat(cv.isPublicDownloadsEnabled()).isFalse();
    }

    @Test
    void tracksPublicSharesAndDownloads() {
        cv.setPublicContactEnabled(true);
        cv.setPublicDownloadsEnabled(true);
        when(cvRepository.findByPublicToken("public-token"))
                .thenReturn(Optional.of(cv));
        service.trackPublicShare("public-token");
        service.trackPublicDownload("public-token");

        verify(cvRepository).incrementShareCount(cv.getId());
        verify(cvRepository).incrementDownloadCount(cv.getId());
    }
}
