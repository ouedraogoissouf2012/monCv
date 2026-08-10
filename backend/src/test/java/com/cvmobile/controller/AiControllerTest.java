package com.cvmobile.controller;

import com.cvmobile.dto.AiStatusResponse;
import com.cvmobile.dto.ApplicationMessagesRequest;
import com.cvmobile.dto.ApplicationMessagesResponse;
import com.cvmobile.dto.EnhanceCvRequest;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.dto.GenerateResumeRequest;
import com.cvmobile.dto.JobMatchRequest;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.dto.SuggestRequest;
import com.cvmobile.dto.SuggestResponse;
import com.cvmobile.model.User;
import com.cvmobile.service.ai.AiStatusService;
import com.cvmobile.service.ai.IApplicationMessageService;
import com.cvmobile.service.ai.IEnhancementService;
import com.cvmobile.service.ai.IJobMatchService;
import com.cvmobile.service.ai.IResumeGeneratorService;
import com.cvmobile.service.ai.ISuggestionService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/// Tests unitaires d'AiController (issue #258) : chaque endpoint delegue au bon
/// service (avec l'id de l'utilisateur authentifie pour les endpoints proteges)
/// et retourne 200 avec la reponse du service.
class AiControllerTest {

    private final ISuggestionService suggestionService = mock(ISuggestionService.class);
    private final IResumeGeneratorService resumeGeneratorService = mock(IResumeGeneratorService.class);
    private final IEnhancementService enhancementService = mock(IEnhancementService.class);
    private final IJobMatchService jobMatchService = mock(IJobMatchService.class);
    private final IApplicationMessageService applicationMessageService = mock(IApplicationMessageService.class);
    private final AiStatusService aiStatusService = mock(AiStatusService.class);

    private final AiController controller = new AiController(
            suggestionService, resumeGeneratorService, enhancementService,
            jobMatchService, applicationMessageService, aiStatusService);

    private final User user = User.builder().id(42L).build();

    @Test
    void status_retourneLEtatDuSousSystemeIa() {
        AiStatusResponse status = mock(AiStatusResponse.class);
        when(aiStatusService.currentStatus()).thenReturn(status);

        ResponseEntity<AiStatusResponse> response = controller.status();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(status);
    }

    @Test
    void suggest_delegueLesChampsDeLaRequete() {
        SuggestRequest request = SuggestRequest.builder()
                .poste("Dev").entreprise("Acme").description("Missions").build();
        SuggestResponse expected = mock(SuggestResponse.class);
        when(suggestionService.generateSuggestions("Dev", "Acme", "Missions"))
                .thenReturn(expected);

        ResponseEntity<SuggestResponse> response = controller.suggest(request);

        assertThat(response.getBody()).isSameAs(expected);
        verify(suggestionService).generateSuggestions("Dev", "Acme", "Missions");
    }

    @Test
    void generateResume_delegueEtRetourneLaCarte() {
        GenerateResumeRequest request = new GenerateResumeRequest();
        request.setTitrePoste("Titre");
        request.setCompetences("Comp");
        request.setExperience("Exp");
        Map<String, Object> expected = Map.of("resume", "genere");
        when(resumeGeneratorService.generateResume("Titre", "Comp", "Exp"))
                .thenReturn(expected);

        ResponseEntity<Map<String, Object>> response =
                controller.generateResume(request);

        assertThat(response.getBody()).isEqualTo(expected);
    }

    @Test
    void enhanceCv_passeLIdDeLUtilisateurAuthentifie() {
        EnhanceCvRequest request = new EnhanceCvRequest();
        request.setCvId(7L);
        request.setLevel("MAX");
        EnhanceCvResponse expected = mock(EnhanceCvResponse.class);
        when(enhancementService.enhanceCv(7L, 42L, "MAX")).thenReturn(expected);

        ResponseEntity<EnhanceCvResponse> response =
                controller.enhanceCv(request, user);

        assertThat(response.getBody()).isSameAs(expected);
        verify(enhancementService).enhanceCv(7L, 42L, "MAX");
    }

    @Test
    void matchJob_passeLIdDeLUtilisateurAuthentifie() {
        JobMatchRequest request = new JobMatchRequest();
        request.setCvId(7L);
        request.setJobDescription("Offre");
        JobMatchResponse expected = mock(JobMatchResponse.class);
        when(jobMatchService.matchJob(7L, 42L, "Offre")).thenReturn(expected);

        ResponseEntity<JobMatchResponse> response =
                controller.matchJob(request, user);

        assertThat(response.getBody()).isSameAs(expected);
        verify(jobMatchService).matchJob(7L, 42L, "Offre");
    }

    @Test
    void generateApplicationMessages_passeIdUtilisateurJobDescriptionEtTon() {
        ApplicationMessagesRequest request = new ApplicationMessagesRequest();
        request.setCvId(7L);
        request.setJobDescription("Offre");
        request.setTone("FRIENDLY");
        ApplicationMessagesResponse expected = mock(ApplicationMessagesResponse.class);
        when(applicationMessageService.generate(7L, 42L, "Offre", "FRIENDLY"))
                .thenReturn(expected);

        ResponseEntity<ApplicationMessagesResponse> response =
                controller.generateApplicationMessages(request, user);

        assertThat(response.getBody()).isSameAs(expected);
        verify(applicationMessageService).generate(7L, 42L, "Offre", "FRIENDLY");
    }
}
