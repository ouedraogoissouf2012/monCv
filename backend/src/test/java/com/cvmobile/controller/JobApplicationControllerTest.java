package com.cvmobile.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.cvmobile.dto.JobApplicationRequest;
import com.cvmobile.dto.JobApplicationResponse;
import com.cvmobile.model.JobApplicationStatus;
import com.cvmobile.model.User;
import com.cvmobile.service.JobApplicationService;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

@ExtendWith(MockitoExtension.class)
class JobApplicationControllerTest {

    @Mock private JobApplicationService service;
    private JobApplicationController controller;
    private final User user = User.builder().id(9L).build();

    @BeforeEach
    void setUp() {
        controller = new JobApplicationController(service);
    }

    @Test
    void list_passeLIdUtilisateurEtLesFiltres() {
        LocalDate from = LocalDate.of(2026, 1, 1);
        LocalDate to = LocalDate.of(2026, 6, 1);
        List<JobApplicationResponse> expected =
                List.of(JobApplicationResponse.builder().id(1L).build());
        when(service.list(eq(9L), eq(JobApplicationStatus.SENT), eq(from), eq(to), any()))
                .thenReturn(expected);

        List<JobApplicationResponse> result = controller.list(
                user, JobApplicationStatus.SENT, from, to, PageRequest.of(0, 50));

        assertThat(result).isSameAs(expected);
        verify(service).list(eq(9L), eq(JobApplicationStatus.SENT), eq(from), eq(to), any());
    }

    @Test
    void create_retourne201EtDelegueAvecLUtilisateur() {
        JobApplicationRequest request = org.mockito.Mockito.mock(JobApplicationRequest.class);
        JobApplicationResponse expected = JobApplicationResponse.builder().id(2L).build();
        when(service.create(request, user)).thenReturn(expected);

        ResponseEntity<JobApplicationResponse> response = controller.create(user, request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isSameAs(expected);
    }

    @Test
    void update_passeLIdRessourceEtLIdUtilisateur() {
        JobApplicationRequest request = org.mockito.Mockito.mock(JobApplicationRequest.class);
        JobApplicationResponse expected = JobApplicationResponse.builder().id(3L).build();
        when(service.update(5L, request, 9L)).thenReturn(expected);

        assertThat(controller.update(5L, user, request)).isSameAs(expected);
        verify(service).update(5L, request, 9L);
    }

    @Test
    void delete_delegueAvecLIdUtilisateur() {
        controller.delete(5L, user);
        verify(service).delete(5L, 9L);
    }
}
