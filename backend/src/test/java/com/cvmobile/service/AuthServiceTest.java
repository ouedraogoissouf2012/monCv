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
        when(jwtTokenProvider.validateToken("bad-token")).thenReturn(false);

        assertThatThrownBy(() -> authService.refreshToken("bad-token"))
                .isInstanceOf(InvalidTokenException.class)
                .hasMessageContaining("invalide");
    }
}
