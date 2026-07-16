package com.cvmobile.security;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
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
        User user = new User(
                "owner@example.test",
                "password",
                List.of(new SimpleGrantedAuthority("ROLE_USER")));
        when(tokenProvider.validateAccessToken("valid-token")).thenReturn(true);
        when(tokenProvider.getEmailFromToken("valid-token")).thenReturn(user.getUsername());
        when(userDetailsService.loadUserByUsername(user.getUsername())).thenReturn(user);

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication())
                .isNotNull()
                .extracting(authentication -> authentication.getName())
                .isEqualTo(user.getUsername());
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

    private MockHttpServletRequest bearerRequest(String token) {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer " + token);
        return request;
    }
}
