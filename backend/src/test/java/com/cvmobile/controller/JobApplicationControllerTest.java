package com.cvmobile.controller;

import com.cvmobile.dto.JobApplicationRequest;
import com.cvmobile.dto.JobApplicationResponse;
import com.cvmobile.model.JobApplicationStatus;
import com.cvmobile.model.User;
import com.cvmobile.service.JobApplicationService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/// Tests unitaires de JobApplicationController (issue #258) : delegation au
/// service avec, systematiquement, l'id de l'utilisateur AUTHENTIFIE (jamais un
/// id issu de la requete) et le bon code HTTP.
class JobApplicationControllerTest {

    private final JobApplicationService service = mock(JobApplicationService.class);
    private final JobApplicationController controller =
            new JobApplicationController(service);
    private final User user = User.builder().id(9L).build();

    @Test
    void list_passeLIdUtilisateurEtLesFiltres() {
        LocalDate from = LocalDate.of(2026, 1, 1);
        LocalDate to = LocalDate.of(2026, 6, 1);
        List<JobApplicationResponse> expected =
                List.of(JobApplicationResponse.builder().id(1L).build());
        when(service.list(9L, JobApplicationStatus.SENT, from, to)).thenReturn(expected);

        List<JobApplicationResponse> result =
                controller.list(user, JobApplicationStatus.SENT, from, to);

        assertThat(result).isSameAs(expected);
        verify(service).list(9L, JobApplicationStatus.SENT, from, to);
    }

    @Test
    void create_retourne201EtDelegueAvecLUtilisateur() {
        JobApplicationRequest request = mock(JobApplicationRequest.class);
        JobApplicationResponse expected = JobApplicationResponse.builder().id(2L).build();
        when(service.create(request, user)).thenReturn(expected);

        ResponseEntity<JobApplicationResponse> response =
                controller.create(user, request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isSameAs(expected);
    }

    @Test
    void update_passeLIdRessourceEtLIdUtilisateur() {
        JobApplicationRequest request = mock(JobApplicationRequest.class);
        JobApplicationResponse expected = JobApplicationResponse.builder().id(3L).build();
        when(service.update(5L, request, 9L)).thenReturn(expected);

        JobApplicationResponse result = controller.update(5L, user, request);

        assertThat(result).isSameAs(expected);
        verify(service).update(5L, request, 9L);
    }

    @Test
    void delete_delegueAvecLIdUtilisateur() {
        controller.delete(5L, user);

        verify(service).delete(5L, 9L);
    }
}
