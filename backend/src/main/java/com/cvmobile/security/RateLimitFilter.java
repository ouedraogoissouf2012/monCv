package com.cvmobile.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Rate limiter simple sur les endpoints /api/auth/*.
 * Max 10 requetes par minute par IP.
 */
@Slf4j
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final int MAX_REQUESTS_PER_MINUTE = 10;
    private static final long WINDOW_MS = 60_000;

    private final Map<String, RateWindow> ipWindows = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                     @NonNull HttpServletResponse response,
                                     @NonNull FilterChain filterChain) throws ServletException, IOException {

        String path = request.getRequestURI();
        if (!path.startsWith("/api/auth/")) {
            filterChain.doFilter(request, response);
            return;
        }

        String ip = getClientIp(request);
        RateWindow window = ipWindows.compute(ip, (k, v) -> {
            long now = System.currentTimeMillis();
            if (v == null || now - v.startTime > WINDOW_MS) {
                return new RateWindow(now);
            }
            return v;
        });

        int count = window.counter.incrementAndGet();
        if (count > MAX_REQUESTS_PER_MINUTE) {
            log.warn("Rate limit depasse pour IP: {} sur {}", ip, path);
            response.setStatus(429);
            response.setContentType("application/json");
            response.setHeader("Retry-After", "60");
            response.getWriter().write(
                    "{\"status\":429,\"code\":\"RATE_LIMIT_EXCEEDED\"," +
                    "\"message\":\"Trop de tentatives. Reessayez dans 1 minute.\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isEmpty()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private static class RateWindow {
        final long startTime;
        final AtomicInteger counter;

        RateWindow(long startTime) {
            this.startTime = startTime;
            this.counter = new AtomicInteger(0);
        }
    }
}
