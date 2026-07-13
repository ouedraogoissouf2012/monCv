package com.cvmobile.exception;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import com.cvmobile.exception.ai.AiTimeoutException;
import com.cvmobile.observability.CorrelationIdFilter;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GlobalExceptionHandlerAiTest {

    private final MockMvc mvc = MockMvcBuilders
            .standaloneSetup(new FailingAiController())
            .setControllerAdvice(new GlobalExceptionHandler())
            .addFilters(new CorrelationIdFilter())
            .build();

    @Test
    void keyInvalidReturnsServiceUnavailable() throws Exception {
        assertAiError("/test/ai/key-invalid", 503, "AI_KEY_INVALID",
                "Le service IA est mal configure. Contactez l'administrateur.");
    }

    @Test
    void quotaExceededReturnsServiceUnavailableWithNumericRetryAfter() throws Exception {
        mvc.perform(get("/test/ai/quota"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(header().string("Retry-After", matchesPattern("\\d+")))
                .andExpect(header().string("Retry-After", "75"))
                .andExpect(header().exists(CorrelationIdFilter.HEADER_NAME))
                .andExpect(jsonPath("$.status").value(503))
                .andExpect(jsonPath("$.code").value("AI_QUOTA_EXCEEDED"))
                .andExpect(jsonPath("$.correlationId").isString())
                .andExpect(jsonPath("$.message")
                        .value("Limite d'usage IA atteinte. Reessayez plus tard."))
                .andExpect(jsonPath("$.details.provider").value("deepseek"))
                .andExpect(jsonPath("$.details.retryAfter").value(75));
    }

    @Test
    void providerDownReturnsServiceUnavailable() throws Exception {
        assertAiError("/test/ai/provider-down", 503, "AI_PROVIDER_DOWN",
                "Le service IA est temporairement indisponible. Reessayez.");
    }

    @Test
    void timeoutReturnsGatewayTimeout() throws Exception {
        assertAiError("/test/ai/timeout", 504, "AI_TIMEOUT",
                "Le service IA met trop de temps a repondre. Reessayez.");
    }

    @Test
    void parseErrorReturnsBadGateway() throws Exception {
        assertAiError("/test/ai/parse", 502, "AI_PARSE_ERROR",
                "Reponse IA invalide. Reessayez.");
    }

    private void assertAiError(String path, int httpStatus, String code, String message)
            throws Exception {
        mvc.perform(get(path))
                .andExpect(status().is(httpStatus))
                .andExpect(header().exists(CorrelationIdFilter.HEADER_NAME))
                .andExpect(jsonPath("$.status").value(httpStatus))
                .andExpect(jsonPath("$.code").value(code))
                .andExpect(jsonPath("$.correlationId").isString())
                .andExpect(jsonPath("$.message").value(message))
                .andExpect(jsonPath("$.details.provider").value("deepseek"));
    }

    @RestController
    private static class FailingAiController {

        @GetMapping("/test/ai/key-invalid")
        void keyInvalid() {
            throw new AiKeyInvalidException("deepseek", null);
        }

        @GetMapping("/test/ai/quota")
        void quota() {
            throw new AiQuotaExceededException("deepseek", 75, null);
        }

        @GetMapping("/test/ai/provider-down")
        void providerDown() {
            throw new AiProviderDownException("deepseek", "HTTP 503", null);
        }

        @GetMapping("/test/ai/timeout")
        void timeout() {
            throw new AiTimeoutException("deepseek", null);
        }

        @GetMapping("/test/ai/parse")
        void parse() {
            throw new AiParseException("deepseek", "missing choices", null);
        }
    }
}
