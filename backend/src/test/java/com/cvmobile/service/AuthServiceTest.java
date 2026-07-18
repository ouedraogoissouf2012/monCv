package com.cvmobile.service;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.LoginRequest;
import com.cvmobile.dto.RegisterRequest;
import com.cvmobile.exception.DuplicateEmailException;
import com.cvmobile.exception.InvalidTokenException;
import com.cvmobile.mapper.UserMapper;
import com.cvmobile.model.User;
import com.cvmobile.security.JwtTokenProvider;
import com.cvmobile.service.user.IUserService;
import com.cvmobile.service.auth.GoogleIdentityVerifier;
import com.cvmobile.service.auth.GoogleIdentity;
import com.cvmobile.exception.GoogleAuthException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.dao.DataIntegrityViolationException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private IUserService userService;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtTokenProvider jwtTokenProvider;
    @Mock private AuthenticationManager authenticationManager;
    @Mock private UserMapper userMapper;
    @Mock private GoogleIdentityVerifier googleIdentityVerifier;

    @InjectMocks
    private AuthService authService;

    private AuthResponse.UserDto buildUserDto() {
        return AuthResponse.UserDto.builder()
                .id(1L).email("nouveau@example.com")
                .nom("Ouedraogo").prenom("Issouf").role("USER")
                .build();
    }

    @Test
    void register_avecNouvelEmail_devraitCreerLUtilisateur() {
        ReflectionTestUtils.setField(authService, "jwtExpiration", 3600000L);

        RegisterRequest request = new RegisterRequest();
        request.setEmail("nouveau@example.com");
        request.setPassword("password123");
        request.setNom("Ouedraogo");
        request.setPrenom("Issouf");

        User mappedUser = User.builder()
                .email(request.getEmail())
                .nom(request.getNom()).prenom(request.getPrenom())
                .role(User.Role.USER).build();

        User savedUser = User.builder()
                .id(1L).email(request.getEmail())
                .nom(request.getNom()).prenom(request.getPrenom())
                .role(User.Role.USER).build();

        when(userService.existsByEmail(anyString())).thenReturn(false);
        when(userMapper.toUser(request)).thenReturn(mappedUser);
        when(passwordEncoder.encode(anyString())).thenReturn("encoded");
        when(userService.save(any(User.class))).thenReturn(savedUser);
        when(jwtTokenProvider.generateToken(anyString())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(anyString())).thenReturn("refresh-token");
        when(userMapper.toUserDto(savedUser)).thenReturn(buildUserDto());

        var response = authService.register(request);

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getUser().getEmail()).isEqualTo("nouveau@example.com");
        verify(userService).save(any(User.class));
    }

    @Test
    void register_avecEmailExistant_devraitLeverException() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("existant@example.com");
        request.setPassword("password123");

        when(userService.existsByEmail("existant@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(DuplicateEmailException.class)
                .hasMessageContaining("deja utilise");

        verify(userService, never()).save(any());
    }

    @Test
    void register_concurrentAvecLeMemeEmail_devraitRetournerUnConflit() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("course@example.com");
        request.setPassword("password123");
        User mappedUser = User.builder().email(request.getEmail()).build();

        when(userService.existsByEmail(request.getEmail())).thenReturn(false);
        when(userMapper.toUser(request)).thenReturn(mappedUser);
        when(passwordEncoder.encode(request.getPassword())).thenReturn("encoded");
        when(userService.save(mappedUser)).thenThrow(new DataIntegrityViolationException("unique email"));

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(DuplicateEmailException.class);

        verify(jwtTokenProvider, never()).generateToken(anyString());
    }

    @Test
    void login_avecCredentielsValides_devraitRetournerTokens() {
        ReflectionTestUtils.setField(authService, "jwtExpiration", 3600000L);

        LoginRequest request = new LoginRequest();
        request.setEmail("user@example.com");
        request.setPassword("password123");

        User user = User.builder()
                .id(1L).email("user@example.com")
                .nom("Ouedraogo").prenom("Issouf")
                .role(User.Role.USER).build();

        Authentication auth = new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
        when(authenticationManager.authenticate(any())).thenReturn(auth);
        when(jwtTokenProvider.generateToken(any(Authentication.class))).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(anyString())).thenReturn("refresh-token");
        when(userMapper.toUserDto(user)).thenReturn(buildUserDto());

        var response = authService.login(request);

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getTokenType()).isEqualTo("Bearer");
    }

    @Test
    void refreshToken_avecTokenInvalide_devraitLeverException() {
        when(jwtTokenProvider.validateRefreshToken("bad-token")).thenReturn(false);

        assertThatThrownBy(() -> authService.refreshToken("bad-token"))
                .isInstanceOf(InvalidTokenException.class)
                .hasMessageContaining("invalide");
    }

    @Test
    void refreshToken_avecAccessToken_devraitLeverException() {
        when(jwtTokenProvider.validateRefreshToken("access-token")).thenReturn(false);

        assertThatThrownBy(() -> authService.refreshToken("access-token"))
                .isInstanceOf(InvalidTokenException.class);

        verify(userService, never()).findByEmail(anyString());
        verify(jwtTokenProvider, never()).generateToken(anyString());
    }

    @Test
    void googleLogin_nouveauCompteCreeUnUtilisateurSansMotDePasse() {
        ReflectionTestUtils.setField(authService, "jwtExpiration", 3600000L);
        GoogleIdentity identity = new GoogleIdentity(
                "google-123", "user@gmail.com", true, "Ada", "Lovelace", "https://photo");
        when(googleIdentityVerifier.verify("credential")).thenReturn(identity);
        when(userService.findByGoogleSubject("google-123")).thenReturn(java.util.Optional.empty());
        when(userService.findOptionalByEmail("user@gmail.com")).thenReturn(java.util.Optional.empty());
        when(userService.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0); user.setId(9L); return user;
        });
        when(jwtTokenProvider.generateToken("user@gmail.com")).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken("user@gmail.com")).thenReturn("refresh-token");
        when(userMapper.toUserDto(any(User.class))).thenReturn(buildUserDto());

        AuthResponse response = authService.loginWithGoogle("credential");

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        verify(userService).save(argThat(user -> user.getPassword() == null
                && user.getAuthProvider() == User.AuthProvider.GOOGLE
                && "google-123".equals(user.getGoogleSubject())));
    }

    @Test
    void googleLogin_emailLocalExistantExigeUneLiaisonExplicite() {
        GoogleIdentity identity = new GoogleIdentity(
                "google-123", "user@example.com", true, null, null, null);
        when(googleIdentityVerifier.verify("credential")).thenReturn(identity);
        when(userService.findByGoogleSubject("google-123")).thenReturn(java.util.Optional.empty());
        when(userService.findOptionalByEmail("user@example.com"))
                .thenReturn(java.util.Optional.of(User.builder().id(1L).email("user@example.com").build()));

        assertThatThrownBy(() -> authService.loginWithGoogle("credential"))
                .isInstanceOf(GoogleAuthException.class)
                .hasMessageContaining("associez Google");
        verify(userService, never()).save(any());
    }

    @Test
    void linkGoogle_refuseUneAdresseDifferente() {
        User current = User.builder().id(1L).email("owner@example.com").build();
        when(googleIdentityVerifier.verify("credential")).thenReturn(new GoogleIdentity(
                "google-123", "attacker@example.com", true, null, null, null));

        assertThatThrownBy(() -> authService.linkGoogle(current, "credential"))
                .isInstanceOf(GoogleAuthException.class)
                .hasMessageContaining("meme adresse email");
        verify(userService, never()).save(any());
    }
}
