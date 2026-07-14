package com.cvmobile.service;

import com.cvmobile.dto.JobApplicationRequest;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.*;
import com.cvmobile.repository.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.*;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JobApplicationServiceTest {
    @Mock JobApplicationRepository applications;
    @Mock CvRepository cvs;
    @InjectMocks JobApplicationService service;

    private User user;
    private Cv cv;

    @BeforeEach
    void setUp() {
        user = User.builder().id(7L).email("user@example.com").build();
        cv = Cv.builder().id(11L).titre("CV Produit").user(user).varianteLabel("Product Manager").build();
    }

    @Test
    void createsApplicationLinkedToOwnedCv() {
        JobApplicationRequest request = request();
        when(cvs.findByIdAndUserId(11L, 7L)).thenReturn(Optional.of(cv));
        when(applications.save(any())).thenAnswer(invocation -> {
            JobApplication value = invocation.getArgument(0);
            value.setId(3L);
            return value;
        });

        var result = service.create(request, user);

        Assertions.assertEquals(3L, result.id());
        Assertions.assertEquals(11L, result.cvId());
        Assertions.assertTrue(result.cvVariant());
        Assertions.assertEquals("Acme", result.company());
    }

    @Test
    void rejectsCvOwnedByAnotherUser() {
        JobApplicationRequest request = request();
        when(cvs.findByIdAndUserId(11L, 7L)).thenReturn(Optional.empty());

        Assertions.assertThrows(ResourceNotFoundException.class, () -> service.create(request, user));
        verify(applications, never()).save(any());
    }

    @Test
    void filtersApplicationsForCurrentUser() {
        when(applications.findForUser(7L, JobApplicationStatus.INTERVIEW,
                LocalDate.of(2026, 1, 1), LocalDate.of(2026, 12, 31)))
                .thenReturn(List.of(JobApplication.builder()
                        .id(1L).user(user).company("Acme").position("PM")
                        .status(JobApplicationStatus.INTERVIEW).build()));

        var result = service.list(7L, JobApplicationStatus.INTERVIEW,
                LocalDate.of(2026, 1, 1), LocalDate.of(2026, 12, 31));

        Assertions.assertEquals(1, result.size());
        Assertions.assertEquals(JobApplicationStatus.INTERVIEW, result.get(0).status());
    }

    @Test
    void cannotUpdateAnotherUsersApplication() {
        when(applications.findOwnedById(99L, 7L)).thenReturn(Optional.empty());
        Assertions.assertThrows(ResourceNotFoundException.class,
                () -> service.update(99L, request(), 7L));
    }

    private JobApplicationRequest request() {
        JobApplicationRequest request = new JobApplicationRequest();
        request.setCvId(11L);
        request.setCompany(" Acme ");
        request.setPosition(" Product Manager ");
        request.setStatus(JobApplicationStatus.SENT);
        request.setSentDate(LocalDate.of(2026, 7, 14));
        request.setNextFollowUp(LocalDate.of(2026, 7, 21));
        return request;
    }
}
