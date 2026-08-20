package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.Cv;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.service.CvQualityService;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.cv.CvOwnershipService;
import com.cvmobile.service.quality.CvTextCleaner;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JobMatchQualityCleanTest {

    @Mock IAiClient aiClient;
    @Mock CvOwnershipService cvOwnershipService;
    @Mock CvQualityService cvQualityService;

    @Test
    void suggestionsEtResumeOptimisePassentParClean() {
        CvTextCleaner cleaner = new CvTextCleaner();
        when(cvQualityService.clean(org.mockito.ArgumentMatchers.anyString()))
                .thenAnswer(invocation -> cleaner.clean(invocation.getArgument(0)));
        when(cvQualityService.findReviewWarnings(org.mockito.ArgumentMatchers.any()))
                .thenReturn(java.util.List.of());
        Cv cv = Cv.builder().id(22L).titre("CV")
                .personalInfo(PersonalInfo.builder().titrePoste("Dev").build())
                .build();
        when(cvOwnershipService.requireOwnedCv(22L, 7L)).thenReturn(cv);
        JobMatchTextAnalyzer text = new JobMatchTextAnalyzer();
        JobMatchProperties properties = new JobMatchProperties(50, 14, 6, 5, 5, 100, 1800);
        JobMatchServiceImpl service = new JobMatchServiceImpl(
                aiClient, cvOwnershipService, cvQualityService, properties, text,
                new JobMatchScorer(text, properties),
                new JobMatchFormatChecker(text, properties),
                new JobMatchRecommender(text, properties),
                new JobMatchPromptBuilder(text));
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("""
                        SCORE: 60
                        MOTS_CLES_PRESENTS:
                        - java
                        SUGGESTIONS:
                        - Livrés **cinq** modules
                        RESUME_OPTIMISE:
                        Analyses les besoins **ATS**.
                        """);

        JobMatchResponse response = service.matchJob(22L, 7L, "Offre Java");

        assertThat(response.getSuggestions()).anyMatch(s -> s.contains("Livré cinq modules"));
        assertThat(response.getOptimizedResume()).isEqualTo("Analyse les besoins ATS.");
    }
}
