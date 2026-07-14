package com.cvmobile.service.notification;

import com.cvmobile.dto.NotificationDtos;
import com.cvmobile.model.*;
import com.cvmobile.repository.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import java.time.LocalDateTime;
import java.util.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {
    @Mock DeviceTokenRepository tokens;
    @Mock NotificationPreferenceRepository preferences;
    @Mock NotificationDeliveryRepository deliveries;
    @Mock CvRepository cvs;
    @Mock JobApplicationRepository applications;
    @Mock PushGateway gateway;
    @InjectMocks NotificationService service;

    User user;
    Cv cv;

    @BeforeEach void setUp() {
        user = User.builder().id(1L).email("test@example.com").build();
        cv = Cv.builder().id(8L).titre("CV pro").user(user).viewCount(10)
            .updatedAt(LocalDateTime.now().minusDays(31)).build();
        ReflectionTestUtils.setField(service, "staleCvDays", 30);
    }

    @Test void notifieAuDixiemeAffichageUneSeuleFois() {
        when(preferences.findById(1L)).thenReturn(Optional.empty());
        when(deliveries.existsByDeduplicationKey("views:8:10")).thenReturn(false);
        when(tokens.findByUserId(1L)).thenReturn(List.of(DeviceToken.builder().token("token").user(user).build()));
        when(gateway.send(eq("token"), anyString(), anyString(), anyMap())).thenReturn(true);

        service.notifyViewMilestone(cv);

        verify(gateway).send(eq("token"), anyString(), contains("10"), argThat(data -> data.get("route").equals("/cvs/8")));
        verify(deliveries).save(argThat(d -> d.getDeduplicationKey().equals("views:8:10")));
    }

    @Test void neNotifiePasAvantLeSeuil() {
        cv.setViewCount(9);
        service.notifyViewMilestone(cv);
        verifyNoInteractions(gateway, deliveries);
    }

    @Test void respecteLaPreferenceDesactivee() {
        when(preferences.findById(1L)).thenReturn(Optional.of(NotificationPreference.builder()
            .user(user).cvViewsEnabled(false).build()));
        service.notifyViewMilestone(cv);
        verifyNoInteractions(gateway, deliveries);
    }

    @Test void rappelleUnCvInactifDepuisTrenteJours() {
        when(cvs.findByUpdatedAtBefore(any())).thenReturn(List.of(cv));
        when(preferences.findById(1L)).thenReturn(Optional.empty());
        when(tokens.findByUserId(1L)).thenReturn(List.of(DeviceToken.builder().token("token").user(user).build()));
        when(gateway.send(anyString(), anyString(), anyString(), anyMap())).thenReturn(true);

        service.sendStaleCvReminders();

        verify(gateway).send(eq("token"), anyString(), contains("experiences"), anyMap());
        verify(deliveries).save(argThat(d -> d.getNotificationType().equals("STALE_CV")));
    }

    @Test void sauvegardeLesPreferences() {
        when(preferences.findById(1L)).thenReturn(Optional.empty());
        when(preferences.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        var result = service.updatePreferences(user, new NotificationDtos.Preferences(false, true, false));
        Assertions.assertFalse(result.staleCvEnabled());
        Assertions.assertTrue(result.cvViewsEnabled());
        Assertions.assertFalse(result.aiTipsEnabled());
    }

    @Test void rappelleUneCandidatureArriveeAEcheance() {
        JobApplication application = JobApplication.builder()
            .id(12L).user(user).cv(cv).company("Acme").position("Product Manager")
            .status(JobApplicationStatus.SENT).nextFollowUp(java.time.LocalDate.now()).build();
        when(applications.findByNextFollowUpLessThanEqualAndStatusNotIn(any(), anyList()))
            .thenReturn(List.of(application));
        when(tokens.findByUserId(1L)).thenReturn(List.of(DeviceToken.builder().token("token").user(user).build()));
        when(gateway.send(anyString(), anyString(), anyString(), anyMap())).thenReturn(true);

        service.sendApplicationFollowUpReminders();

        verify(gateway).send(eq("token"), contains("Relance"), contains("Acme"),
            argThat(data -> data.get("route").equals("/applications")));
        verify(deliveries).save(argThat(d -> d.getNotificationType().equals("APPLICATION_FOLLOW_UP")));
    }
}
