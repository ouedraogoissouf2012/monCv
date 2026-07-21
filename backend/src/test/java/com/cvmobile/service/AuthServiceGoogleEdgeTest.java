package com.cvmobile.service;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.exception.GoogleAuthException;
import com.cvmobile.mapper.UserMapper;
import com.cvmobile.model.User;
import com.cvmobile.security.JwtTokenProvider;
import com.cvmobile.service.auth.GoogleIdentity;
import com.cvmobile.service.auth.GoogleIdentityVerifier;
import com.cvmobile.service.user.IUserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceGoogleEdgeTest {
    @Mock IUserService userService;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtTokenProvider jwtTokenProvider;
    @Mock AuthenticationManager authenticationManager;
    @Mock UserMapper userMapper;
    @Mock GoogleIdentityVerifier googleIdentityVerifier;

    @InjectMocks AuthService authService;

    @BeforeEach
    void configureTokenLifetime() {
        ReflectionTestUtils.setField(authService, "jwtExpiration", 3_600_000L);
    }

    @Test
    void googleLoginReusesTheSubjectOwnerWithoutCreatingAnAccount() {
        User existing = user(9L, "user@example.com");
        when(googleIdentityVerifier.verify("credential")).thenReturn(identity());
        when(userService.findByGoogleSubject("google-123"))
                .thenReturn(Optional.of(existing));
        stubTokens(existing);

        AuthResponse response = authService.loginWithGoogle("credential");

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getExpiresIn()).isEqualTo(3600L);
        verify(userService, never()).save(any());
    }

    @Test
    void googleLoginRecoversTheWinnerOfAConcurrentRegistration() {
        User winner = user(10L, "user@example.com");
        when(googleIdentityVerifier.verify("credential")).thenReturn(identity());
        when(userService.findByGoogleSubject("google-123"))
                .thenReturn(Optional.empty(), Optional.of(winner));
        when(userService.findOptionalByEmail("user@example.com"))
                .thenReturn(Optional.empty());
        when(userService.save(any(User.class)))
                .thenThrow(new DataIntegrityViolationException("unique google subject"));
        stubTokens(winner);

        AuthResponse response = authService.loginWithGoogle("credential");

        assertThat(response.getRefreshToken()).isEqualTo("refresh-token");
    }

    @Test
    void googleLoginReportsAnOpaqueConflictWhenTheRaceWinnerCannotBeRead() {
        when(googleIdentityVerifier.verify("credential")).thenReturn(identity());
        when(userService.findByGoogleSubject("google-123"))
                .thenReturn(Optional.empty());
        when(userService.findOptionalByEmail("user@example.com"))
                .thenReturn(Optional.empty());
        when(userService.save(any(User.class)))
                .thenThrow(new DataIntegrityViolationException("unique google subject"));

        assertThatThrownBy(() -> authService.loginWithGoogle("credential"))
                .isInstanceOf(GoogleAuthException.class)
                .extracting(error -> ((GoogleAuthException) error).getCode())
                .isEqualTo("GOOGLE_ACCOUNT_CONFLICT");
    }

    @Test
    void linkGooglePersistsTheVerifiedSubjectAndIssuesTokens() {
        User current = user(7L, "Owner@Example.com");
        GoogleIdentity identity = new GoogleIdentity(
                "google-123", "owner@example.com", true,
                "Ada", "Lovelace", "https://images.example.test/ada.png");
        when(googleIdentityVerifier.verify("credential")).thenReturn(identity);
        when(userService.findByGoogleSubject("google-123")).thenReturn(Optional.empty());
        when(userService.save(current)).thenReturn(current);
        stubTokens(current);

        authService.linkGoogle(current, "credential");

        assertThat(current.getGoogleSubject()).isEqualTo("google-123");
        assertThat(current.getPictureUrl()).endsWith("ada.png");
        assertThat(current.getAuthProvider()).isEqualTo(User.AuthProvider.BOTH);
        verify(userService).save(current);
    }

    @Test
    void linkGoogleRejectsASubjectOwnedByAnotherUser() {
        User current = user(7L, "user@example.com");
        User other = user(8L, "other@example.com");
        when(googleIdentityVerifier.verify("credential")).thenReturn(identity());
        when(userService.findByGoogleSubject("google-123"))
                .thenReturn(Optional.of(other));

        assertThatThrownBy(() -> authService.linkGoogle(current, "credential"))
                .isInstanceOf(GoogleAuthException.class)
                .extracting(error -> ((GoogleAuthException) error).getCode())
                .isEqualTo("GOOGLE_ACCOUNT_ALREADY_LINKED");
        verify(userService, never()).save(any());
    }

    @Test
    void refreshesAValidRefreshTokenAndRotatesBothTokens() {
        User user = user(5L, "user@example.com");
        when(jwtTokenProvider.validateRefreshToken("refresh-old")).thenReturn(true);
        when(jwtTokenProvider.getEmailFromToken("refresh-old"))
                .thenReturn("user@example.com");
        when(userService.findByEmail("user@example.com")).thenReturn(user);
        stubTokens(user);

        AuthResponse response = authService.refreshToken("refresh-old");

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getRefreshToken()).isEqualTo("refresh-token");
    }

    private GoogleIdentity identity() {
        return new GoogleIdentity(
                "google-123", "user@example.com", true,
                "Ada", "Lovelace", null);
    }

    private User user(Long id, String email) {
        return User.builder().id(id).email(email).role(User.Role.USER).build();
    }

    private void stubTokens(User user) {
        when(jwtTokenProvider.generateToken(user.getEmail())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(user.getEmail()))
                .thenReturn("refresh-token");
    }
}
