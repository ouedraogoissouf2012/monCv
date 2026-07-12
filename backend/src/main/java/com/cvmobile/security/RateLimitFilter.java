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
 * Rate limiter simple sur les endpoints exposes aux abus publics ou IA.
 * Les compteurs sont en memoire: suffisant pour une premiere protection PWA,
 * a remplacer par Redis/Bucket4j en environnement multi-instance.
 */
@Slf4j
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final int AUTH_MAX_REQUESTS_PER_MINUTE = 10;
    private static final int AI_MAX_REQUESTS_PER_MINUTE = 20;
    private static final int PUBLIC_MAX_REQUESTS_PER_MINUTE = 60;
    private static final long WINDOW_MS = 60_000;

    private final Map<String, RateWindow> ipWindows = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                     @NonNull HttpServletResponse response,
                                     @NonNull FilterChain filterChain) throws ServletException, IOException {

        String path = request.getRequestURI();
        int limit = limitForPath(path);
        if (limit <= 0) {
            filterChain.doFilter(request, response);
            return;
        }

        String ip = getClientIp(request);
        String key = ip + ":" + bucketForPath(path);
        RateWindow window = ipWindows.compute(key, (k, v) -> {
            long now = System.currentTimeMillis();
            if (v == null || now - v.startTime > WINDOW_MS) {
                return new RateWindow(now);
            }
            return v;
        });

        int count = window.counter.incrementAndGet();
        if (count > limit) {
            log.warn("Rate limit depasse pour IP: {} sur endpoint {}", ip, bucketForPath(path));
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

    private int limitForPath(String path) {
        if (path.startsWith("/api/auth/")) return AUTH_MAX_REQUESTS_PER_MINUTE;
        if (path.startsWith("/api/ai/")) return AI_MAX_REQUESTS_PER_MINUTE;
        if (path.startsWith("/api/cvs/public/")) return PUBLIC_MAX_REQUESTS_PER_MINUTE;
        return 0;
    }

    private String bucketForPath(String path) {
        if (path.startsWith("/api/auth/")) return "auth";
        if (path.startsWith("/api/ai/")) return "ai";
        if (path.startsWith("/api/cvs/public/")) return "public-cv";
        return "other";
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
