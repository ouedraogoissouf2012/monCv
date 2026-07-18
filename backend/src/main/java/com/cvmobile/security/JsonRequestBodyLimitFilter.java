package com.cvmobile.security;

import com.cvmobile.config.RequestBodyLimitProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Set;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public final class JsonRequestBodyLimitFilter extends OncePerRequestFilter {
    private static final Set<String> BODY_METHODS = Set.of("POST", "PUT", "PATCH");
    private final RequestBodyLimitProperties properties;

    public JsonRequestBodyLimitFilter(RequestBodyLimitProperties properties) {
        this.properties = properties;
    }

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        return !BODY_METHODS.contains(request.getMethod()) || !isJson(request.getContentType());
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        int limit = request.getRequestURI().startsWith("/api/cvs")
                ? properties.maxCvJsonBytes() : properties.maxJsonBytes();
        if (request.getContentLengthLong() > limit) {
            writeTooLarge(response);
            return;
        }

        byte[] body = request.getInputStream().readNBytes(limit + 1);
        if (body.length > limit) {
            writeTooLarge(response);
            return;
        }
        filterChain.doFilter(new CachedBodyRequest(request, body), response);
    }

    private boolean isJson(String contentType) {
        if (contentType == null) return false;
        try {
            MediaType mediaType = MediaType.parseMediaType(contentType);
            return MediaType.APPLICATION_JSON.includes(mediaType)
                    || mediaType.getSubtype().toLowerCase(java.util.Locale.ROOT).endsWith("+json");
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }

    private void writeTooLarge(HttpServletResponse response) throws IOException {
        response.setStatus(HttpStatus.PAYLOAD_TOO_LARGE.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setHeader("Cache-Control", "no-store");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.getWriter().write(
                "{\"status\":413,\"code\":\"REQUEST_TOO_LARGE\","
                        + "\"message\":\"Le corps de la requete est trop volumineux.\"}");
    }

    private static final class CachedBodyRequest extends HttpServletRequestWrapper {
        private final byte[] body;

        private CachedBodyRequest(HttpServletRequest request, byte[] body) {
            super(request);
            this.body = body;
        }

        @Override
        public ServletInputStream getInputStream() {
            return new CachedServletInputStream(body);
        }

        @Override
        public BufferedReader getReader() {
            return new BufferedReader(new InputStreamReader(
                    getInputStream(), StandardCharsets.UTF_8));
        }

        @Override
        public int getContentLength() {
            return body.length;
        }

        @Override
        public long getContentLengthLong() {
            return body.length;
        }
    }

    private static final class CachedServletInputStream extends ServletInputStream {
        private final ByteArrayInputStream input;

        private CachedServletInputStream(byte[] body) {
            input = new ByteArrayInputStream(body);
        }

        @Override
        public int read() {
            return input.read();
        }

        @Override
        public int read(byte[] bytes, int offset, int length) {
            return input.read(bytes, offset, length);
        }

        @Override
        public boolean isFinished() {
            return input.available() == 0;
        }

        @Override
        public boolean isReady() {
            return true;
        }

        @Override
        public void setReadListener(ReadListener readListener) {
            throw new UnsupportedOperationException("Lecture asynchrone non prise en charge");
        }
    }
}
