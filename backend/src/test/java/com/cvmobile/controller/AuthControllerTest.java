package com.cvmobile.controller;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.LoginRequest;
import com.cvmobile.dto.RegisterRequest;
import com.cvmobile.service.AuthService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock private AuthService authService;

    @InjectMocks private AuthController authController;

    private AuthResponse buildAuthResponse() {
        return AuthResponse.builder()
                .accessToken("access-token").refreshToken("refresh-token")
                .tokenType("Bearer").expiresIn(3600L)
                .user(AuthResponse.UserDto.builder()
                        .id(1L).email("user@example.com")
                        .nom("Ouedraogo").prenom("Issouf").role("USER").build())
                .build();
    }

    @Test
    void register_avecDonneesValides_devraitRetourner201() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("user@example.com");
        request.setPassword("password123");
        request.setNom("Ouedraogo");
        request.setPrenom("Issouf");

        when(authService.register(any(RegisterRequest.class))).thenReturn(buildAuthResponse());

        ResponseEntity<AuthResponse> response = authController.register(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getAccessToken()).isEqualTo("access-token");
        assertThat(response.getBody().getUser().getEmail()).isEqualTo("user@example.com");
    }

    @Test
    void login_avecCredentielsValides_devraitRetourner200() {
        LoginRequest request = new LoginRequest();
        request.setEmail("user@example.com");
        request.setPassword("password123");

        when(authService.login(any(LoginRequest.class))).thenReturn(buildAuthResponse());

        ResponseEntity<AuthResponse> response = authController.login(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getTokenType()).isEqualTo("Bearer");
    }

    @Test
    void register_quandServiceLeveeException_devraitPropager() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("existant@example.com");
        request.setPassword("password123");

        when(authService.register(any())).thenThrow(new RuntimeException("Email deja utilise"));

        assertThatThrownBy(() -> authController.register(request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("deja utilise");
    }
}
