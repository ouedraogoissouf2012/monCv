package com.cvmobile.exception.ai;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AiServiceExceptionTest {

    private static final String PROVIDER = "deepseek";
    private static final RuntimeException CAUSE = new RuntimeException("provider failure");

    @Test
    void keyInvalidCarriesStableMetadata() {
        AiKeyInvalidException exception = new AiKeyInvalidException(PROVIDER, CAUSE);

        assertMetadata(exception, "AI_KEY_INVALID", null);
    }

    @Test
    void quotaExceededCarriesRetryDelay() {
        AiQuotaExceededException exception = new AiQuotaExceededException(PROVIDER, 60, CAUSE);

        assertMetadata(exception, "AI_QUOTA_EXCEEDED", 60);
    }

    @Test
    void providerDownCarriesStableMetadata() {
        AiProviderDownException exception =
                new AiProviderDownException(PROVIDER, "HTTP 503", CAUSE);

        assertMetadata(exception, "AI_PROVIDER_DOWN", null);
    }

    @Test
    void timeoutCarriesStableMetadata() {
        AiTimeoutException exception = new AiTimeoutException(PROVIDER, CAUSE);

        assertMetadata(exception, "AI_TIMEOUT", null);
    }

    @Test
    void parseErrorCarriesStableMetadata() {
        AiParseException exception =
                new AiParseException(PROVIDER, "missing choices", CAUSE);

        assertMetadata(exception, "AI_PARSE_ERROR", null);
    }

    private static void assertMetadata(AiServiceException exception, String errorCode,
                                       Integer retryAfterSeconds) {
        assertThat(exception.getProviderName()).isEqualTo(PROVIDER);
        assertThat(exception.getErrorCode()).isEqualTo(errorCode);
        assertThat(exception.getRetryAfterSeconds()).isEqualTo(retryAfterSeconds);
        assertThat(exception.getCause()).isSameAs(CAUSE);
        assertThat(exception.getMessage()).isNotBlank();
    }
}
