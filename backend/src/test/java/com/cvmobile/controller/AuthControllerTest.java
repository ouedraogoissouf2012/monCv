package com.cvmobile.controller;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.ForgotPasswordRequest;
import com.cvmobile.dto.GoogleAuthRequest;
import com.cvmobile.dto.LoginRequest;
import com.cvmobile.dto.RegisterRequest;
import com.cvmobile.dto.ResetPasswordRequest;
import com.cvmobile.exception.DuplicateEmailException;
import com.cvmobile.model.User;
import com.cvmobile.service.AuthService;
import com.cvmobile.service.auth.PasswordResetService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock private AuthService authService;
    @Mock private PasswordResetService passwordResetService;

    @InjectMocks private AuthController authController;

    private AuthResponse buildAuthResponse() {
        return AuthResponse.builder()
                .accessToken("access-token").refreshToken("refresh-token")
                .tokenType("Bearer").expiresIn(3600L)
                .user(AuthResponse.UserDto.builder()
                        .id(1L).email("user@example.com")
                        .nom("Traore").prenom("Alex").role("USER").build())
                .build();
    }

    @Test
    void register_avecDonneesValides_devraitRetourner201() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("user@example.com");
        request.setPassword("password123");
        request.setNom("Traore");
        request.setPrenom("Alex");

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

        when(authService.register(any())).thenThrow(new DuplicateEmailException("existant@example.com"));

        assertThatThrownBy(() -> authController.register(request))
                .isInstanceOf(DuplicateEmailException.class)
                .hasMessageContaining("deja utilise");
    }

    // ── Endpoints supplementaires couverts pour retirer l'exclusion jacoco (#258) ──

    @Test
    void google_delegueLeCredential() {
        when(authService.loginWithGoogle("cred-token")).thenReturn(buildAuthResponse());

        ResponseEntity<AuthResponse> response =
                authController.google(new GoogleAuthRequest("cred-token"));

        assertThat(response.getBody().getAccessToken()).isEqualTo("access-token");
        verify(authService).loginWithGoogle("cred-token");
    }

    @Test
    void linkGoogle_associeAuCompteAuthentifie() {
        User user = User.builder().id(1L).build();
        when(authService.linkGoogle(user, "cred-token")).thenReturn(buildAuthResponse());

        ResponseEntity<AuthResponse> response =
                authController.linkGoogle(new GoogleAuthRequest("cred-token"), user);

        assertThat(response.getBody().getTokenType()).isEqualTo("Bearer");
        verify(authService).linkGoogle(user, "cred-token");
    }

    @Test
    void refreshToken_valide_retourne200() {
        when(authService.refreshToken("rt")).thenReturn(buildAuthResponse());

        ResponseEntity<AuthResponse> response =
                authController.refreshToken(Map.of("refreshToken", "rt"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getAccessToken()).isEqualTo("access-token");
    }

    @Test
    void refreshToken_absent_retourne400SansAppelerLeService() {
        ResponseEntity<AuthResponse> response = authController.refreshToken(Map.of());

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verify(authService, never()).refreshToken(anyString());
    }

    @Test
    void forgotPassword_delegueEtRetourne200() {
        ResponseEntity<Void> response =
                authController.forgotPassword(new ForgotPasswordRequest("a@b.c"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(passwordResetService).requestReset("a@b.c");
    }

    @Test
    void resetPassword_delegueTokenEtNouveauMotDePasse() {
        ResponseEntity<Void> response = authController.resetPassword(
                new ResetPasswordRequest("tok", "NouveauMotDePasse1"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(passwordResetService).resetPassword("tok", "NouveauMotDePasse1");
    }
}
