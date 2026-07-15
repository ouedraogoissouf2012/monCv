package com.cvmobile.security;

import com.cvmobile.config.RateLimitProperties;
import com.cvmobile.model.User;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RateLimitFilterTest {

    private final RateLimitService rateLimitService = mock(RateLimitService.class);
    private final SimpleMeterRegistry meterRegistry = new SimpleMeterRegistry();
    private final RateLimitFilter filter = new RateLimitFilter(
            defaultProperties(),
            rateLimitService,
            meterRegistry
    );

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void limiteIaParIdentifiantUtilisateurEtExposeRetryAfter() throws Exception {
        authenticate(User.Role.USER, 42L);
        when(rateLimitService.consume("ai:user:42", 20, Duration.ofHours(1)))
                .thenReturn(RateLimitResult.rejected(Duration.ofSeconds(37)));
        MockHttpServletResponse response = execute("POST", "/api/ai/enhance-cv", "203.0.113.10");

        assertThat(response.getStatus()).isEqualTo(429);
        assertThat(response.getHeader("Retry-After")).isEqualTo("37");
        assertThat(meterRegistry.get("rate_limit_hits")
                .tags("endpoint", "ai", "user_tier", "user")
                .counter().count()).isEqualTo(1);
    }

    @Test
    void limiteAuthentificationParAdresseDistanteSansFaireConfianceAXForwardedFor() throws Exception {
        when(rateLimitService.consume("auth:ip:198.51.100.7", 10, Duration.ofMinutes(1)))
                .thenReturn(RateLimitResult.allowed(9));
        MockHttpServletRequest request = request("POST", "/api/auth/login", "198.51.100.7");
        request.addHeader("X-Forwarded-For", "192.0.2.99");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        verify(rateLimitService).consume("auth:ip:198.51.100.7", 10, Duration.ofMinutes(1));
        assertThat(response.getStatus()).isEqualTo(200);
        assertThat(response.getHeader("X-RateLimit-Remaining")).isEqualTo("9");
    }

    @Test
    void appliqueLeQuotaImportParUtilisateur() throws Exception {
        authenticate(User.Role.PREMIUM, 7L);
        when(rateLimitService.consume("cv-import:user:7", 5, Duration.ofHours(1)))
                .thenReturn(RateLimitResult.allowed(4));

        MockHttpServletResponse response = execute("POST", "/api/cvs/import", "203.0.113.10");

        assertThat(response.getStatus()).isEqualTo(200);
        verify(rateLimitService).consume("cv-import:user:7", 5, Duration.ofHours(1));
    }

    @Test
    void bypassAdminConfigurable() throws Exception {
        authenticate(User.Role.ADMIN, 1L);

        MockHttpServletResponse response = execute("POST", "/api/ai/job-match", "203.0.113.10");

        assertThat(response.getStatus()).isEqualTo(200);
        verify(rateLimitService, never()).consume(any(), anyLong(), any());
    }

    @Test
    void ignoreLesEndpointsNonSensibles() throws Exception {
        MockHttpServletResponse response = execute("GET", "/api/health/local", "203.0.113.10");

        assertThat(response.getStatus()).isEqualTo(200);
        verify(rateLimitService, never()).consume(any(), anyLong(), any());
    }

    private MockHttpServletResponse execute(String method, String path, String ip) throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request(method, path, ip), response, new MockFilterChain());
        return response;
    }

    private MockHttpServletRequest request(String method, String path, String ip) {
        MockHttpServletRequest request = new MockHttpServletRequest(method, path);
        request.setRemoteAddr(ip);
        return request;
    }

    private void authenticate(User.Role role, Long userId) {
        User user = User.builder()
                .id(userId)
                .email(role.name().toLowerCase() + "@example.com")
                .password("unused")
                .role(role)
                .build();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities())
        );
    }

    private static RateLimitProperties defaultProperties() {
        return new RateLimitProperties(
                true,
                true,
                10,
                Duration.ofMinutes(1),
                20,
                Duration.ofHours(1),
                5,
                Duration.ofHours(1),
                60,
                Duration.ofMinutes(1),
                "redis://localhost:6379",
                "test:rate-limit:"
        );
    }
}
