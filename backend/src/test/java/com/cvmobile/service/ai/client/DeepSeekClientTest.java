package com.cvmobile.service.ai.client;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withUnauthorizedRequest;

/**
 * Tests de la traduction HTTP brut -> exceptions typees par DeepSeekClient.
 * Utilise MockRestServiceServer pour simuler toutes les reponses possibles de l'API.
 */
class DeepSeekClientTest {

    private DeepSeekClient client;
    private MockRestServiceServer server;

    @BeforeEach
    void setUp() {
        client = new DeepSeekClient(new RestTemplateBuilder());
        ReflectionTestUtils.setField(client, "apiKey", "sk-test-valid-key");
        ReflectionTestUtils.setField(client, "model", "deepseek-chat");
        ReflectionTestUtils.setField(client, "baseUrl", "http://deepseek.test/v1");
        // Recuperer le RestTemplate interne pour mocker
        RestTemplate rt = (RestTemplate) ReflectionTestUtils.getField(client, "restTemplate");
        server = MockRestServiceServer.bindTo(rt).build();
    }

    @Test
    void complete_happyPath_devraitRetournerContent() {
        server.expect(requestTo("http://deepseek.test/v1/chat/completions"))
                .andExpect(method(POST))
                .andRespond(withSuccess(
                        """
                        {"choices":[{"message":{"content":"Resume ameliore"}}]}
                        """,
                        MediaType.APPLICATION_JSON));

        String result = client.complete("prompt", 100);

        assertThat(result).isEqualTo("Resume ameliore");
        server.verify();
    }

    @Test
    void complete_401_devraitLeverAiKeyInvalidException() {
        server.expect(requestTo("http://deepseek.test/v1/chat/completions"))
                .andRespond(withUnauthorizedRequest().body("{\"error\":\"Invalid API key\"}")
                        .contentType(MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiKeyInvalidException.class)
                .hasMessageContaining("deepseek")
                .extracting(e -> ((AiKeyInvalidException) e).getErrorCode())
                .isEqualTo("AI_KEY_INVALID");
    }

    @Test
    void complete_429_devraitLeverAiQuotaExceededExceptionAvecRetryAfter() {
        HttpHeaders respHeaders = new HttpHeaders();
        respHeaders.add(HttpHeaders.RETRY_AFTER, "45");
        server.expect(requestTo("http://deepseek.test/v1/chat/completions"))
                .andRespond(withStatus(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS)
                        .headers(respHeaders)
                        .body("{\"error\":\"rate limit\"}")
                        .contentType(MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiQuotaExceededException.class)
                .satisfies(t -> {
                    AiQuotaExceededException ex = (AiQuotaExceededException) t;
                    assertThat(ex.getRetryAfterSeconds()).isEqualTo(45);
                    assertThat(ex.getErrorCode()).isEqualTo("AI_QUOTA_EXCEEDED");
                });
    }

    @Test
    void complete_500_devraitLeverAiProviderDownException() {
        server.expect(requestTo("http://deepseek.test/v1/chat/completions"))
                .andRespond(withServerError().body("{\"error\":\"internal\"}")
                        .contentType(MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class)
                .extracting(e -> ((AiProviderDownException) e).getErrorCode())
                .isEqualTo("AI_PROVIDER_DOWN");
    }

    @Test
    void complete_responseWithoutChoices_devraitLeverAiParseException() {
        server.expect(requestTo("http://deepseek.test/v1/chat/completions"))
                .andRespond(withSuccess("{\"other\":\"field\"}", MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiParseException.class)
                .hasMessageContaining("choices");
    }

    @Test
    void complete_responseWithEmptyChoices_devraitLeverAiParseException() {
        server.expect(requestTo("http://deepseek.test/v1/chat/completions"))
                .andRespond(withSuccess("{\"choices\":[]}", MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiParseException.class);
    }

    @Test
    void complete_cleMissing_devraitLeverAiKeyInvalidException() {
        ReflectionTestUtils.setField(client, "apiKey", "");

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiKeyInvalidException.class)
                .hasMessageContaining("deepseek");
    }
}
