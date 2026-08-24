package com.cvmobile.security;

import com.cvmobile.model.User;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class JwtAuthenticationFilterTest {

    private JwtTokenProvider tokenProvider;
    private UserDetailsService userDetailsService;
    private JwtAuthenticationFilter filter;
    private FilterChain filterChain;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
        tokenProvider = mock(JwtTokenProvider.class);
        userDetailsService = mock(UserDetailsService.class);
        filterChain = mock(FilterChain.class);
        filter = new JwtAuthenticationFilter(tokenProvider, userDetailsService);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void continuesAsAnonymousWhenJwtUserNoLongerExists() throws Exception {
        MockHttpServletRequest request = bearerRequest("orphan-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(tokenProvider.validateAccessToken("orphan-token")).thenReturn(true);
        when(tokenProvider.getEmailFromToken("orphan-token")).thenReturn("deleted@example.test");
        when(userDetailsService.loadUserByUsername("deleted@example.test"))
                .thenThrow(new UsernameNotFoundException("deleted"));

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void authenticatesWhenJwtUserExists() throws Exception {
        MockHttpServletRequest request = bearerRequest("valid-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        User user = account(3);
        stubAccessTokenFor(user, "valid-token");
        when(tokenProvider.matchesTokenVersion("valid-token", 3)).thenReturn(true);

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication())
                .isNotNull()
                .extracting(authentication -> authentication.getName())
                .isEqualTo(user.getUsername());
        assertThat(SecurityContextHolder.getContext().getAuthentication().getAuthorities())
                .extracting(GrantedAuthority::getAuthority)
                .containsExactly("ROLE_USER");
        verify(filterChain).doFilter(request, response);
    }

    // ── Revocation de session (#505) ────────────────────────────────

    @Test
    void refusesAccessTokenFromRevokedSessionGeneration() throws Exception {
        // Jeton signe, non expire, du bon type, dont le compte existe toujours :
        // seule la generation de sessions a change (deconnexion / reinitialisation).
        MockHttpServletRequest request = bearerRequest("revoked-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        User user = account(4);
        stubAccessTokenFor(user, "revoked-token");
        when(tokenProvider.matchesTokenVersion("revoked-token", 4)).thenReturn(false);

        filter.doFilterInternal(request, response, filterChain);

        // Anonyme : Spring Security repondra 401 sur toute route protegee.
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void refusesPrincipalWhoseSessionGenerationCannotBeChecked() throws Exception {
        // Fail-closed : un principal qui n'expose pas de generation ne peut pas etre
        // verifie, il ne doit donc pas etre authentifie sans controle de revocation.
        MockHttpServletRequest request = bearerRequest("foreign-principal");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(tokenProvider.validateAccessToken("foreign-principal")).thenReturn(true);
        when(tokenProvider.getEmailFromToken("foreign-principal")).thenReturn("owner@example.test");
        when(userDetailsService.loadUserByUsername("owner@example.test")).thenReturn(
                new org.springframework.security.core.userdetails.User(
                        "owner@example.test", "password",
                        List.of(new SimpleGrantedAuthority("ROLE_USER"))));

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(tokenProvider, never()).matchesTokenVersion(anyString(), anyInt());
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void ignoresInvalidJwtWithoutLoadingUser() throws Exception {
        MockHttpServletRequest request = bearerRequest("invalid-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(tokenProvider.validateAccessToken("invalid-token")).thenReturn(false);

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verifyNoInteractions(userDetailsService);
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void ignoresRefreshTokenOnProtectedEndpoint() throws Exception {
        MockHttpServletRequest request = bearerRequest("refresh-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(tokenProvider.validateAccessToken("refresh-token")).thenReturn(false);

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verifyNoInteractions(userDetailsService);
        verify(filterChain).doFilter(request, response);
    }

    private User account(int tokenVersion) {
        return User.builder()
                .id(1L)
                .email("owner@example.test")
                .role(User.Role.USER)
                .tokenVersion(tokenVersion)
                .build();
    }

    private void stubAccessTokenFor(User user, String token) {
        when(tokenProvider.validateAccessToken(token)).thenReturn(true);
        when(tokenProvider.getEmailFromToken(token)).thenReturn(user.getUsername());
        when(userDetailsService.loadUserByUsername(user.getUsername())).thenReturn(user);
    }

    private MockHttpServletRequest bearerRequest(String token) {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer " + token);
        return request;
    }
}
