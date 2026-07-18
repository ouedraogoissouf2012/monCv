package com.cvmobile.exception;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import com.cvmobile.exception.ai.AiTimeoutException;
import com.cvmobile.observability.CorrelationIdSupport;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // ── Validation ───────────────────────────────────────────────
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = ex.getBindingResult().getAllErrors().stream()
                .filter(e -> e instanceof FieldError)
                .map(e -> (FieldError) e)
                .collect(Collectors.toMap(
                        FieldError::getField,
                        e -> e.getDefaultMessage() != null ? e.getDefaultMessage() : "Invalide",
                        (a, b) -> a
                ));

        return buildResponse(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR",
                "Erreur de validation", fieldErrors);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleUnreadableJson(
            HttpMessageNotReadableException ex) {
        return buildResponse(HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST",
                "Le corps de la requete est invalide", null);
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<Map<String, Object>> handleUnsupportedMediaType(
            HttpMediaTypeNotSupportedException ex) {
        return buildResponse(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "UNSUPPORTED_MEDIA_TYPE",
                "Le type de contenu de la requete n'est pas accepte", null);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, Object>> handleUnsupportedMethod(
            HttpRequestMethodNotSupportedException ex) {
        return buildResponse(HttpStatus.METHOD_NOT_ALLOWED, "METHOD_NOT_ALLOWED",
                "La methode HTTP n'est pas acceptee", null);
    }

    // ── Auth ─────────────────────────────────────────────────────
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, Object>> handleBadCredentials(BadCredentialsException ex) {
        return buildResponse(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS",
                "Email ou mot de passe incorrect", null);
    }

    @ExceptionHandler(UsernameNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleUserNotFound(UsernameNotFoundException ex) {
        return buildResponse(HttpStatus.NOT_FOUND, "USER_NOT_FOUND",
                ex.getMessage(), null);
    }

    // ── Custom exceptions ────────────────────────────────────────
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(ResourceNotFoundException ex) {
        return buildResponse(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND",
                ex.getMessage(), null);
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, Object>> handleUnauthorized(UnauthorizedException ex) {
        return buildResponse(HttpStatus.FORBIDDEN, "FORBIDDEN",
                ex.getMessage(), null);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, Object>> handleBusiness(BusinessException ex) {
        return buildResponse(HttpStatus.BAD_REQUEST, ex.getCode(),
                ex.getMessage(), null);
    }

    @ExceptionHandler(DuplicateEmailException.class)
    public ResponseEntity<Map<String, Object>> handleDuplicateEmail(DuplicateEmailException ex) {
        return buildResponse(HttpStatus.CONFLICT, "DUPLICATE_EMAIL",
                ex.getMessage(), null);
    }

    @ExceptionHandler(InvalidTokenException.class)
    public ResponseEntity<Map<String, Object>> handleInvalidToken(InvalidTokenException ex) {
        return buildResponse(HttpStatus.UNAUTHORIZED, "INVALID_TOKEN",
                ex.getMessage(), null);
    }

    @ExceptionHandler(GoogleAuthException.class)
    public ResponseEntity<Map<String, Object>> handleGoogleAuth(GoogleAuthException ex) {
        HttpStatus status = switch (ex.getCode()) {
            case "GOOGLE_AUTH_UNAVAILABLE" -> HttpStatus.SERVICE_UNAVAILABLE;
            case "GOOGLE_LINK_REQUIRED", "GOOGLE_ACCOUNT_ALREADY_LINKED", "GOOGLE_ACCOUNT_CONFLICT" -> HttpStatus.CONFLICT;
            case "GOOGLE_EMAIL_MISMATCH" -> HttpStatus.FORBIDDEN;
            default -> HttpStatus.UNAUTHORIZED;
        };
        return buildResponse(status, ex.getCode(), ex.getMessage(), null);
    }

    @ExceptionHandler(FileStorageException.class)
    public ResponseEntity<Map<String, Object>> handleFileStorage(FileStorageException ex) {
        log.error("Erreur stockage fichier [correlationId={}]: {}",
                CorrelationIdSupport.current(), ex.getMessage(), ex);
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "FILE_STORAGE_ERROR",
                "Erreur lors du traitement du fichier", null);
    }

    @ExceptionHandler(PdfGenerationException.class)
    public ResponseEntity<Map<String, Object>> handlePdfGeneration(PdfGenerationException ex) {
        log.error("Erreur generation PDF [correlationId={}]: {}",
                CorrelationIdSupport.current(), ex.getMessage(), ex);
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "PDF_GENERATION_ERROR",
                "Erreur lors de la generation du document", null);
    }

    @ExceptionHandler(RateLimitException.class)
    public ResponseEntity<Map<String, Object>> handleRateLimit(RateLimitException ex) {
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .header("Retry-After", "60")
                .body(buildBody(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMIT_EXCEEDED",
                        ex.getMessage(), null));
    }

    @ExceptionHandler(PublicDocumentUnavailableException.class)
    public ResponseEntity<Map<String, Object>> handlePublicDocumentUnavailable(
            PublicDocumentUnavailableException ex) {
        log.warn("Generation de document public refusee [correlationId={}]",
                CorrelationIdSupport.current());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .header("Retry-After", "1")
                .body(buildBody(HttpStatus.SERVICE_UNAVAILABLE,
                        "PUBLIC_DOCUMENT_UNAVAILABLE",
                        "Le document est temporairement indisponible. Reessayez.", null));
    }

    // ── Upload ───────────────────────────────────────────────────
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, Object>> handleMaxUpload(MaxUploadSizeExceededException ex) {
        return buildResponse(HttpStatus.PAYLOAD_TOO_LARGE, "FILE_TOO_LARGE",
                "Le fichier depasse la taille maximale autorisee (5 MB)", null);
    }

    // ── IA (specifiques, doivent precedder le catch RuntimeException) ─────
    @ExceptionHandler(AiKeyInvalidException.class)
    public ResponseEntity<Map<String, Object>> handleAiKeyInvalid(AiKeyInvalidException ex) {
        log.error("AI key invalid [correlationId={}] provider={}: {}",
                CorrelationIdSupport.current(), ex.getProviderName(), ex.getMessage());
        return buildResponse(HttpStatus.SERVICE_UNAVAILABLE, ex.getErrorCode(),
                "Le service IA est mal configure. Contactez l'administrateur.",
                Map.of("provider", ex.getProviderName()));
    }

    @ExceptionHandler(AiQuotaExceededException.class)
    public ResponseEntity<Map<String, Object>> handleAiQuota(AiQuotaExceededException ex) {
        int retry = ex.getRetryAfterSeconds() != null ? ex.getRetryAfterSeconds() : 60;
        log.warn("AI quota exceeded [correlationId={}] provider={}: retry in {}s",
                CorrelationIdSupport.current(), ex.getProviderName(), retry);
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .header("Retry-After", String.valueOf(retry))
                .body(buildBody(HttpStatus.SERVICE_UNAVAILABLE, ex.getErrorCode(),
                        "Limite d'usage IA atteinte. Reessayez plus tard.",
                        Map.of("provider", ex.getProviderName(), "retryAfter", retry)));
    }

    @ExceptionHandler(AiTimeoutException.class)
    public ResponseEntity<Map<String, Object>> handleAiTimeout(AiTimeoutException ex) {
        log.warn("AI timeout [correlationId={}] provider={}",
                CorrelationIdSupport.current(), ex.getProviderName());
        return buildResponse(HttpStatus.GATEWAY_TIMEOUT, ex.getErrorCode(),
                "Le service IA met trop de temps a repondre. Reessayez.",
                Map.of("provider", ex.getProviderName()));
    }

    @ExceptionHandler(AiProviderDownException.class)
    public ResponseEntity<Map<String, Object>> handleAiDown(AiProviderDownException ex) {
        log.warn("AI provider down [correlationId={}] provider={}: {}",
                CorrelationIdSupport.current(), ex.getProviderName(), ex.getMessage());
        return buildResponse(HttpStatus.SERVICE_UNAVAILABLE, ex.getErrorCode(),
                "Le service IA est temporairement indisponible. Reessayez.",
                Map.of("provider", ex.getProviderName()));
    }

    @ExceptionHandler(AiParseException.class)
    public ResponseEntity<Map<String, Object>> handleAiParse(AiParseException ex) {
        log.error("AI parse error [correlationId={}] provider={}: {}",
                CorrelationIdSupport.current(), ex.getProviderName(), ex.getMessage());
        return buildResponse(HttpStatus.BAD_GATEWAY, ex.getErrorCode(),
                "Reponse IA invalide. Reessayez.",
                Map.of("provider", ex.getProviderName()));
    }

    // ── Fallback ─────────────────────────────────────────────────
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex) {
        log.error("Erreur interne non geree [correlationId={}]",
                CorrelationIdSupport.current(), ex);
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Une erreur s'est produite. Si le problème persiste, contactez le support.", null);
    }

    // ── Helper ───────────────────────────────────────────────────
    private ResponseEntity<Map<String, Object>> buildResponse(
            HttpStatus status, String code, String message, Object details) {
        return ResponseEntity.status(status).body(buildBody(status, code, message, details));
    }

    private Map<String, Object> buildBody(
            HttpStatus status, String code, String message, Object details) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", LocalDateTime.now().toString());
        body.put("status", status.value());
        body.put("code", code);
        body.put("message", message);
        if (CorrelationIdSupport.current() != null) body.put("correlationId", CorrelationIdSupport.current());
        if (details != null) body.put("details", details);
        return body;
    }
}
