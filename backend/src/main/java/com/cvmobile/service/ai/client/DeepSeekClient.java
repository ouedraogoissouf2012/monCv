package com.cvmobile.service.ai.client;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import com.cvmobile.exception.ai.AiTimeoutException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageConversionException;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.net.SocketTimeoutException;
import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Client DeepSeek (API compatible OpenAI).
 *
 * Traduit les erreurs HTTP brutes de RestTemplate en AiServiceException typees
 * pour que la chaine de resilience (retry/circuit breaker) et le GlobalExceptionHandler
 * puissent reagir de maniere appropriee a chaque type d'echec.
 *
 * Timeouts explicites (connect 3s, read 9s) en dessous du TimeLimiter (10s)
 * pour que les timeouts soient signales par ResourceAccessException, pas par le thread pool.
 */
@Slf4j
@Component
public class DeepSeekClient implements IAiClient {

    public static final String PROVIDER_NAME = "deepseek";

    @Value("${ai.deepseek.api-key:}")
    private String apiKey;

    @Value("${ai.deepseek.model:deepseek-chat}")
    private String model;

    @Value("${ai.deepseek.base-url:https://api.deepseek.com/v1}")
    private String baseUrl;

    private final RestTemplate restTemplate;

    public DeepSeekClient(RestTemplateBuilder builder) {
        this.restTemplate = builder
                .setConnectTimeout(Duration.ofSeconds(3))
                .setReadTimeout(Duration.ofSeconds(9))
                .build();
    }

    @Override
    public boolean isAvailable() {
        return apiKey != null && !apiKey.isBlank();
    }

    @Override
    public String complete(String prompt, int maxTokens) {
        if (!isAvailable()) {
            throw new AiKeyInvalidException(PROVIDER_NAME,
                    new IllegalStateException("DeepSeek API key not configured"));
        }

        Map<String, Object> requestBody = Map.of(
                "model", model,
                "messages", List.of(Map.of("role", "user", "content", prompt)),
                "max_tokens", maxTokens,
                "temperature", 0.7
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        long startedAt = System.nanoTime();
        try {
            @SuppressWarnings("unchecked")
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                    baseUrl + "/chat/completions",
                    HttpMethod.POST,
                    entity,
                    (Class<Map<String, Object>>) (Class<?>) Map.class);

            String content = extractContent(response.getBody());
            log.debug("AI request succeeded provider={} httpStatus={} latencyMs={}",
                    PROVIDER_NAME, response.getStatusCode().value(), elapsedMillis(startedAt));
            return content;

        } catch (HttpClientErrorException.Unauthorized e) {
            logFailure(e.getStatusCode().value(), startedAt, e);
            throw new AiKeyInvalidException(PROVIDER_NAME, e);
        } catch (HttpClientErrorException.TooManyRequests e) {
            logFailure(e.getStatusCode().value(), startedAt, e);
            Integer retryAfter = parseRetryAfter(e.getResponseHeaders());
            throw new AiQuotaExceededException(PROVIDER_NAME, retryAfter, e);
        } catch (HttpClientErrorException e) {
            logFailure(e.getStatusCode().value(), startedAt, e);
            if (e.getStatusCode() == HttpStatus.PAYMENT_REQUIRED) {
                throw new AiQuotaExceededException(PROVIDER_NAME,
                        parseRetryAfter(e.getResponseHeaders()), e);
            }
            if (e.getStatusCode() == HttpStatus.REQUEST_TIMEOUT) {
                throw new AiTimeoutException(PROVIDER_NAME, e);
            }
            throw new AiProviderDownException(PROVIDER_NAME,
                    "HTTP " + e.getStatusCode().value(), e);
        } catch (HttpServerErrorException e) {
            logFailure(e.getStatusCode().value(), startedAt, e);
            if (e.getStatusCode() == HttpStatus.GATEWAY_TIMEOUT) {
                throw new AiTimeoutException(PROVIDER_NAME, e);
            }
            throw new AiProviderDownException(PROVIDER_NAME,
                    "HTTP " + e.getStatusCode().value(), e);
        } catch (AiParseException e) {
            logFailure(HttpStatus.OK.value(), startedAt, e);
            throw e;
        } catch (ResourceAccessException e) {
            logFailure(null, startedAt, e);
            if (hasCause(e, SocketTimeoutException.class)) {
                throw new AiTimeoutException(PROVIDER_NAME, e);
            }
            throw new AiProviderDownException(PROVIDER_NAME,
                    "Network error: " + e.getMessage(), e);
        } catch (RestClientException e) {
            logFailure(null, startedAt, e);
            if (hasCause(e, HttpMessageConversionException.class)) {
                throw new AiParseException(PROVIDER_NAME,
                        "malformed response body", e);
            }
            throw new AiProviderDownException(PROVIDER_NAME,
                    "Client error: " + e.getMessage(), e);
        }
    }

    /**
     * Extrait le content du premier choice de la reponse OpenAI-like.
     * Lance AiParseException si la structure ne correspond pas.
     */
    private String extractContent(Map<String, Object> body) {
        if (body == null) {
            throw new AiParseException(PROVIDER_NAME, "empty response body", null);
        }
        try {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> choices = (List<Map<String, Object>>) body.get("choices");
            if (choices == null || choices.isEmpty()) {
                throw new AiParseException(PROVIDER_NAME, "missing or empty 'choices'", null);
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
            if (message == null) {
                throw new AiParseException(PROVIDER_NAME, "missing 'message' in first choice", null);
            }
            String content = (String) message.get("content");
            if (content == null) {
                throw new AiParseException(PROVIDER_NAME, "missing 'content' in message", null);
            }
            // Nettoyer les ```json ``` si present
            content = content.replaceAll("^```json\\s*", "").replaceAll("```\\s*$", "").trim();
            log.debug("DeepSeek response ({} chars)", content.length());
            return content;
        } catch (ClassCastException e) {
            throw new AiParseException(PROVIDER_NAME,
                    "unexpected response structure: " + e.getMessage(), e);
        }
    }

    private Integer parseRetryAfter(HttpHeaders headers) {
        if (headers == null) return null;
        String value = headers.getFirst(HttpHeaders.RETRY_AFTER);
        if (value == null || value.isBlank()) return null;
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private boolean hasCause(Throwable throwable, Class<? extends Throwable> causeType) {
        Throwable current = throwable;
        while (current != null) {
            if (causeType.isInstance(current)) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }

    private void logFailure(Integer httpStatus, long startedAt, Exception exception) {
        log.warn("AI request failed provider={} httpStatus={} latencyMs={} errorType={}",
                PROVIDER_NAME,
                httpStatus != null ? httpStatus : "network",
                elapsedMillis(startedAt),
                exception.getClass().getSimpleName());
    }

    private long elapsedMillis(long startedAt) {
        return Duration.ofNanos(System.nanoTime() - startedAt).toMillis();
    }
}
