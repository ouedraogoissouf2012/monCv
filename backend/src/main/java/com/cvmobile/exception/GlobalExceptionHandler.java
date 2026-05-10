package com.cvmobile.exception;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import com.cvmobile.exception.ai.AiTimeoutException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
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

    @ExceptionHandler(FileStorageException.class)
    public ResponseEntity<Map<String, Object>> handleFileStorage(FileStorageException ex) {
        log.error("Erreur stockage fichier: {}", ex.getMessage(), ex);
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "FILE_STORAGE_ERROR",
                "Erreur lors du traitement du fichier", null);
    }

    @ExceptionHandler(PdfGenerationException.class)
    public ResponseEntity<Map<String, Object>> handlePdfGeneration(PdfGenerationException ex) {
        log.error("Erreur generation PDF: {}", ex.getMessage(), ex);
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

    // ── Upload ───────────────────────────────────────────────────
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, Object>> handleMaxUpload(MaxUploadSizeExceededException ex) {
        return buildResponse(HttpStatus.PAYLOAD_TOO_LARGE, "FILE_TOO_LARGE",
                "Le fichier depasse la taille maximale autorisee (5 MB)", null);
    }

    // ── IA (specifiques, doivent precedder le catch RuntimeException) ─────
    @ExceptionHandler(AiKeyInvalidException.class)
    public ResponseEntity<Map<String, Object>> handleAiKeyInvalid(AiKeyInvalidException ex) {
        log.error("AI key invalid for provider {}: {}", ex.getProviderName(), ex.getMessage());
        return buildResponse(HttpStatus.SERVICE_UNAVAILABLE, ex.getErrorCode(),
                "Le service IA est mal configure. Contactez l'administrateur.",
                Map.of("provider", ex.getProviderName()));
    }

    @ExceptionHandler(AiQuotaExceededException.class)
    public ResponseEntity<Map<String, Object>> handleAiQuota(AiQuotaExceededException ex) {
        int retry = ex.getRetryAfterSeconds() != null ? ex.getRetryAfterSeconds() : 60;
        log.warn("AI quota exceeded for provider {}: retry in {}s", ex.getProviderName(), retry);
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .header("Retry-After", String.valueOf(retry))
                .body(buildBody(HttpStatus.SERVICE_UNAVAILABLE, ex.getErrorCode(),
                        "Limite d'usage IA atteinte. Reessayez plus tard.",
                        Map.of("provider", ex.getProviderName(), "retryAfter", retry)));
    }

    @ExceptionHandler(AiTimeoutException.class)
    public ResponseEntity<Map<String, Object>> handleAiTimeout(AiTimeoutException ex) {
        log.warn("AI timeout for provider {}", ex.getProviderName());
        return buildResponse(HttpStatus.GATEWAY_TIMEOUT, ex.getErrorCode(),
                "Le service IA met trop de temps a repondre. Reessayez.",
                Map.of("provider", ex.getProviderName()));
    }

    @ExceptionHandler(AiProviderDownException.class)
    public ResponseEntity<Map<String, Object>> handleAiDown(AiProviderDownException ex) {
        log.warn("AI provider {} down: {}", ex.getProviderName(), ex.getMessage());
        return buildResponse(HttpStatus.SERVICE_UNAVAILABLE, ex.getErrorCode(),
                "Le service IA est temporairement indisponible. Reessayez.",
                Map.of("provider", ex.getProviderName()));
    }

    @ExceptionHandler(AiParseException.class)
    public ResponseEntity<Map<String, Object>> handleAiParse(AiParseException ex) {
        log.error("AI parse error for provider {}: {}", ex.getProviderName(), ex.getMessage());
        return buildResponse(HttpStatus.BAD_GATEWAY, ex.getErrorCode(),
                "Reponse IA invalide. Reessayez.",
                Map.of("provider", ex.getProviderName()));
    }

    // ── Fallback ─────────────────────────────────────────────────
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntime(RuntimeException ex) {
        log.warn("RuntimeException non geree: {}", ex.getMessage(), ex);
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                ex.getMessage(), null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex) {
        log.error("Erreur interne non geree", ex);
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Une erreur inattendue s'est produite", null);
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
        if (details != null) body.put("details", details);
        return body;
    }
}
