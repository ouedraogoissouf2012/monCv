package com.cvmobile.security;

import com.cvmobile.config.RateLimitProperties;
import com.cvmobile.model.User;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;

@Slf4j
@Component
@RequiredArgsConstructor
public class RateLimitFilter extends OncePerRequestFilter {

    private final RateLimitProperties properties;
    private final RateLimitService rateLimitService;
    private final MeterRegistry meterRegistry;
    private final SecurityIdentifierHasher identifierHasher;

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        return !properties.enabled() || ruleForRequest(request) == null;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        RateLimitRule rule = ruleForRequest(request);
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String userTier = userTier(authentication);

        if (properties.adminBypass() && "admin".equals(userTier)) {
            filterChain.doFilter(request, response);
            return;
        }

        String identity = rule.perUser()
                ? authenticatedUserKey(authentication, request)
                : ipKey(request);
        RateLimitResult result;
        try {
            result = rateLimitService.consume(
                    rule.endpoint() + ":" + identity,
                    rule.capacity(),
                    rule.window()
            );
        } catch (RuntimeException exception) {
            log.error("Stockage Redis du rate limiting indisponible", exception);
            writeUnavailable(response);
            return;
        }

        response.setHeader("X-RateLimit-Remaining", Long.toString(result.remainingTokens()));
        if (result.allowed()) {
            filterChain.doFilter(request, response);
            return;
        }

        long retryAfterSeconds = retryAfterSeconds(result.retryAfter());
        incrementRejectedMetric(rule.endpoint(), userTier);
        log.warn("Rate limit depasse sur endpoint {} pour tier {}", rule.endpoint(), userTier);
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setContentType("application/json");
        response.setHeader("Retry-After", Long.toString(retryAfterSeconds));
        response.getWriter().write(
                "{\"status\":" + HttpStatus.TOO_MANY_REQUESTS.value()
                        + ",\"code\":\"RATE_LIMIT_EXCEEDED\","
                        + "\"message\":\"Trop de tentatives. Reessayez dans "
                        + retryAfterSeconds + " seconde(s).\"}"
        );
    }

    private RateLimitRule ruleForRequest(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (path.startsWith("/api/auth/")) {
            return new RateLimitRule("auth", properties.authRequests(), properties.authWindow(), false);
        }
        if (path.startsWith("/api/ai/")) {
            return new RateLimitRule("ai", properties.aiRequests(), properties.aiWindow(), true);
        }
        if (path.startsWith("/api/cvs/import")) {
            return new RateLimitRule("cv-import", properties.importRequests(), properties.importWindow(), true);
        }
        if (path.startsWith("/api/cvs/public/")) {
            if ("GET".equals(request.getMethod())
                    && (path.endsWith("/pdf") || path.endsWith("/docx"))) {
                return new RateLimitRule(
                        "public-document",
                        properties.publicDownloadRequests(),
                        properties.publicDownloadWindow(),
                        false
                );
            }
            if ("POST".equals(request.getMethod()) && path.endsWith("/share")) {
                return new RateLimitRule(
                        "public-share",
                        properties.publicShareRequests(),
                        properties.publicShareWindow(),
                        false
                );
            }
            return new RateLimitRule(
                    "public-cv",
                    properties.publicRequests(),
                    properties.publicWindow(),
                    false
            );
        }
        return null;
    }

    private String authenticatedUserKey(Authentication authentication, HttpServletRequest request) {
        if (authentication != null
                && authentication.isAuthenticated()
                && authentication.getPrincipal() instanceof User user
                && user.getId() != null) {
            return "user:" + user.getId();
        }
        return ipKey(request);
    }

    private String ipKey(HttpServletRequest request) {
        return "ip:" + identifierHasher.hash("rate-limit", request.getRemoteAddr());
    }

    private String userTier(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return "anonymous";
        }
        if (hasRole(authentication, "ROLE_ADMIN")) {
            return "admin";
        }
        if (hasRole(authentication, "ROLE_PREMIUM")) {
            return "premium";
        }
        return "user";
    }

    private boolean hasRole(Authentication authentication, String role) {
        return authentication.getAuthorities().stream()
                .anyMatch(authority -> role.equals(authority.getAuthority()));
    }

    private long retryAfterSeconds(Duration retryAfter) {
        long millis = Math.max(1, retryAfter.toMillis());
        return Math.max(1, (millis + 999) / 1000);
    }

    private void incrementRejectedMetric(String endpoint, String userTier) {
        Counter.builder("rate_limit_hits")
                .description("Nombre de requetes refusees par le rate limiter")
                .tag("endpoint", endpoint)
                .tag("user_tier", userTier)
                .register(meterRegistry)
                .increment();
    }

    private void writeUnavailable(HttpServletResponse response) throws IOException {
        response.setStatus(HttpStatus.SERVICE_UNAVAILABLE.value());
        response.setContentType("application/json");
        response.getWriter().write(
                "{\"status\":" + HttpStatus.SERVICE_UNAVAILABLE.value()
                        + ",\"code\":\"RATE_LIMIT_UNAVAILABLE\","
                        + "\"message\":\"Protection anti-abus temporairement indisponible.\"}"
        );
    }

    private record RateLimitRule(
            String endpoint,
            long capacity,
            Duration window,
            boolean perUser
    ) {
    }
}
