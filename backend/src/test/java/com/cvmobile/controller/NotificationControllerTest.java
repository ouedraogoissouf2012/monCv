package com.cvmobile.controller;

import com.cvmobile.dto.NotificationDtos;
import com.cvmobile.model.User;
import com.cvmobile.service.notification.NotificationService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/// Tests unitaires de NotificationController (issue #258) : delegation au service
/// pour l'utilisateur authentifie, extraction du token et codes HTTP (204).
class NotificationControllerTest {

    private final NotificationService service = mock(NotificationService.class);
    private final NotificationController controller =
            new NotificationController(service);
    private final User user = User.builder().id(3L).build();

    @Test
    void register_delegueLaRequeteEtRetourne204() {
        NotificationDtos.DeviceTokenRequest request =
                new NotificationDtos.DeviceTokenRequest("token-abc", "android");

        ResponseEntity<Void> response = controller.register(user, request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(service).registerDevice(user, request);
    }

    @Test
    void unregister_extraitLeTokenEtRetourne204() {
        NotificationDtos.TokenDeleteRequest request =
                new NotificationDtos.TokenDeleteRequest("token-xyz");

        ResponseEntity<Void> response = controller.unregister(user, request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(service).unregisterDevice(user, "token-xyz");
    }

    @Test
    void preferences_delegueLaLecture() {
        NotificationDtos.Preferences prefs =
                new NotificationDtos.Preferences(true, false, true);
        when(service.getPreferences(user)).thenReturn(prefs);

        assertThat(controller.preferences(user)).isSameAs(prefs);
    }

    @Test
    void update_delegueLaMiseAJour() {
        NotificationDtos.Preferences request =
                new NotificationDtos.Preferences(false, true, false);
        NotificationDtos.Preferences updated =
                new NotificationDtos.Preferences(true, true, true);
        when(service.updatePreferences(user, request)).thenReturn(updated);

        assertThat(controller.update(user, request)).isSameAs(updated);
    }
}
