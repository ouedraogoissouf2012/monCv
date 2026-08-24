package com.cvmobile.service;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.exception.InvalidTokenException;
import com.cvmobile.mapper.UserMapper;
import com.cvmobile.model.User;
import com.cvmobile.security.JwtTokenProvider;
import com.cvmobile.service.auth.GoogleIdentityVerifier;
import com.cvmobile.service.user.IUserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Revocation de session cote service (issue #505) : deconnexion, et rejet des
 * refresh tokens d'une generation revoquee — le point que {@code /api/auth/refresh}
 * ne peut pas deleguer au filtre puisqu'il est permitAll.
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceSessionRevocationTest {

    private static final String EMAIL = "user@example.com";

    @Mock private IUserService userService;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtTokenProvider jwtTokenProvider;
    @Mock private AuthenticationManager authenticationManager;
    @Mock private UserMapper userMapper;
    @Mock private GoogleIdentityVerifier googleIdentityVerifier;

    @InjectMocks private AuthService authService;

    @Test
    void refreshToken_dUneGenerationRevoquee_devraitEtreRejete() {
        // Le refresh est syntaxiquement valide et le compte existe toujours : seule
        // la generation a change (deconnexion ou reinitialisation de mot de passe).
        // C'est exactement le jeton « vole » du scenario de l'issue.
        stubRefresh("refresh-perime", account(1));
        when(jwtTokenProvider.matchesTokenVersion("refresh-perime", 1)).thenReturn(false);

        assertThatThrownBy(() -> authService.refreshToken("refresh-perime"))
                .isInstanceOf(InvalidTokenException.class)
                // Message identique au refresh invalide : aucun oracle sur la cause du rejet.
                .hasMessage("Token de rafraichissement invalide");

        verify(jwtTokenProvider, never()).generateToken(anyString(), anyInt());
        verify(jwtTokenProvider, never()).generateRefreshToken(anyString(), anyInt());
    }

    @Test
    void refreshToken_dansLaGenerationCourante_devraitReemettreDesJetons() {
        ReflectionTestUtils.setField(authService, "jwtExpiration", 3600000L);
        User user = account(3);
        stubRefresh("refresh-valide", user);
        when(jwtTokenProvider.matchesTokenVersion("refresh-valide", 3)).thenReturn(true);
        when(jwtTokenProvider.generateToken(EMAIL, 3)).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken(EMAIL, 3)).thenReturn("refresh-token");
        when(userMapper.toUserDto(user)).thenReturn(AuthResponse.UserDto.builder()
                .id(1L).email(EMAIL).role("USER").build());

        AuthResponse response = authService.refreshToken("refresh-valide");

        // Les jetons re-emis portent la generation courante, pas la generation 0.
        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getRefreshToken()).isEqualTo("refresh-token");
    }

    @Test
    void logout_devraitIncrementerLaGenerationPersisteeDuCompte() {
        // Le principal de la requete peut porter une generation perimee : c'est la
        // valeur reellement persistee qui est incrementee, pas celle du jeton.
        User principalPerime = account(0);
        User persiste = account(4);
        when(userService.findByEmail(EMAIL)).thenReturn(persiste);

        authService.logout(principalPerime);

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(userService).save(saved.capture());
        assertThat(saved.getValue().getTokenVersion()).isEqualTo(5);
    }

    private User account(int tokenVersion) {
        return User.builder().id(1L).email(EMAIL).role(User.Role.USER)
                .tokenVersion(tokenVersion).build();
    }

    private void stubRefresh(String refreshToken, User user) {
        when(jwtTokenProvider.validateRefreshToken(refreshToken)).thenReturn(true);
        when(jwtTokenProvider.getEmailFromToken(refreshToken)).thenReturn(EMAIL);
        when(userService.findByEmail(EMAIL)).thenReturn(user);
    }
}
