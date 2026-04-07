package com.cvmobile.service.ai.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

/**
 * Implementation DeepSeek de IAiClient.
 * Utilise l'API compatible OpenAI de DeepSeek.
 * Peut etre remplace par ClaudeClient, GptClient, etc.
 */
@Slf4j
@Component
public class DeepSeekClient implements IAiClient {

    @Value("${ai.deepseek.api-key:}")
    private String apiKey;

    @Value("${ai.deepseek.model:deepseek-chat}")
    private String model;

    @Value("${ai.deepseek.base-url:https://api.deepseek.com/v1}")
    private String baseUrl;

    private final RestTemplate restTemplate;

    public DeepSeekClient(RestTemplateBuilder builder) {
        this.restTemplate = builder.build();
    }

    @Override
    public boolean isAvailable() {
        return apiKey != null && !apiKey.isBlank();
    }

    @Override
    public String complete(String prompt, int maxTokens) {
        if (!isAvailable()) {
            throw new IllegalStateException("DeepSeek API key not configured");
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

        @SuppressWarnings("unchecked")
        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                baseUrl + "/chat/completions",
                HttpMethod.POST,
                entity,
                (Class<Map<String, Object>>) (Class<?>) Map.class);

        Map<String, Object> body = response.getBody();
        if (body == null) throw new IllegalStateException("Empty response from DeepSeek");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> choices = (List<Map<String, Object>>) body.get("choices");
        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");

        String content = (String) message.get("content");
        // Nettoyer les ```json ``` si present
        content = content.replaceAll("^```json\\s*", "").replaceAll("```\\s*$", "").trim();

        log.debug("DeepSeek response ({} chars)", content.length());
        return content;
    }
}
