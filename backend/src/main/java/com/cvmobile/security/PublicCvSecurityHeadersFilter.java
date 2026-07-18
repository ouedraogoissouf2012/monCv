package com.cvmobile.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public final class PublicCvSecurityHeadersFilter extends OncePerRequestFilter {
    private static final String PUBLIC_PATH = "/api/cvs/public/";

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        return !request.getRequestURI().startsWith(PUBLIC_PATH);
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store, max-age=0");
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Expires", "0");
        response.setHeader("Referrer-Policy", "no-referrer");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("X-Frame-Options", "DENY");
        response.setHeader("X-Robots-Tag", "noindex, nofollow, noarchive");
        response.setHeader("Content-Security-Policy",
                "default-src 'none'; frame-ancestors 'none'; object-src 'none'");
        filterChain.doFilter(request, response);
    }
}
