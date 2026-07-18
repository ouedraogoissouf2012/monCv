package com.cvmobile.security;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
public final class PublicUrlPolicy {
    private static final int MAX_URL_LENGTH = 500;
    private static final Pattern PHOTO_PATH = Pattern.compile(
            "/api/uploads/photos/[0-9a-fA-F-]{36}\\.(?:jpe?g|png|webp)",
            Pattern.CASE_INSENSITIVE);

    private final Set<String> allowedMediaOrigins;

    public PublicUrlPolicy(PublicPortfolioSecurityProperties properties) {
        allowedMediaOrigins = properties.allowedMediaOrigins().stream()
                .map(this::parseOrigin)
                .flatMap(Optional::stream)
                .collect(Collectors.toUnmodifiableSet());
    }

    public String sanitizeMediaUrl(String value) {
        Optional<URI> candidate = parse(value);
        if (candidate.isEmpty()) return null;
        URI uri = candidate.get();
        if (uri.getRawQuery() != null || uri.getRawFragment() != null
                || uri.getUserInfo() != null
                || !PHOTO_PATH.matcher(uri.getPath()).matches()) {
            return null;
        }
        if (!uri.isAbsolute()) return uri.toASCIIString();
        return parseOrigin(uri).filter(allowedMediaOrigins::contains)
                .map(ignored -> uri.toASCIIString())
                .orElse(null);
    }

    public Optional<String> extractPhotoFilename(String value) {
        String sanitized = sanitizeMediaUrl(value);
        if (sanitized == null) return Optional.empty();
        String path = URI.create(sanitized).getPath();
        return Optional.of(path.substring(path.lastIndexOf('/') + 1));
    }

    public String sanitizeExternalUrl(String value) {
        Optional<URI> candidate = parse(value);
        if (candidate.isEmpty()) return null;
        URI uri = candidate.get();
        if (!uri.isAbsolute() || uri.getHost() == null || uri.getUserInfo() != null
                || !"https".equalsIgnoreCase(uri.getScheme())) {
            return null;
        }
        return uri.normalize().toASCIIString();
    }

    private Optional<URI> parse(String value) {
        if (value == null || value.isBlank() || value.length() > MAX_URL_LENGTH) {
            return Optional.empty();
        }
        try {
            URI uri = URI.create(value);
            return uri.getPath() == null ? Optional.empty() : Optional.of(uri);
        } catch (IllegalArgumentException exception) {
            return Optional.empty();
        }
    }

    private Optional<String> parseOrigin(String value) {
        return parse(value).flatMap(this::parseOrigin);
    }

    private Optional<String> parseOrigin(URI uri) {
        String scheme = uri.getScheme();
        String host = uri.getHost();
        if (scheme == null || host == null
                || !(scheme.equalsIgnoreCase("https") || scheme.equalsIgnoreCase("http"))) {
            return Optional.empty();
        }
        int port = uri.getPort();
        String origin = scheme.toLowerCase(Locale.ROOT) + "://"
                + host.toLowerCase(Locale.ROOT) + (port < 0 ? "" : ":" + port);
        return Optional.of(origin);
    }
}
